// lib/ethereum/ethereum_provider.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart';
import 'package:web3_webview/utils/loading.dart';
import 'package:web3dart/web3dart.dart';

import '../json_rpc_method.dart';
import '../exceptions.dart';
import '../models/models.dart';
import '../provider/provider_script.dart';
import '../signing/signing_handler.dart';
import '../transaction/transaction_handler.dart';
import '../utils/hex_utils.dart';
import 'wallet_dialog_service.dart';

class EthereumProvider {
  // Singleton pattern
  static final EthereumProvider _instance = EthereumProvider._internal();
  factory EthereumProvider() => _instance;
  EthereumProvider._internal();

  // Context
  BuildContext? _context;

  // Dialog service
  final WalletDialogService _dialogService = WalletDialogService.instance;

  // Core components
  late Web3Client _web3client;
  late Credentials _credentials;
  late TransactionHandler _txHandler;
  late SigningHandler _signingHandler;

  // State
  late WalletState _state;
  final Map<String, NetworkConfig> _networks = {};
  InAppWebViewController? _webViewController;
  EIP6963ProviderInfo? _eip6963ProviderInfo;

  // Stream controllers
  final _stateController = StreamController<WalletState>.broadcast();
  Stream<WalletState> get stateStream => _stateController.stream;

  // Block number cache
  DateTime? _lastBlockFetch;
  String? _cachedBlockNumber;
  static const _blockNumberCacheDuration = Duration(seconds: 12);

  void setContext(BuildContext context) {
    _context = context;
  }

  void setWebViewController(InAppWebViewController controller) {
    _webViewController = controller;
  }

  Future<void> initialize({
    required NetworkConfig defaultNetwork,
    required String privateKey,
    required EIP6963ProviderInfo providerInfo,
    List<NetworkConfig> additionalNetworks = const [],
    WalletDialogTheme? theme,
  }) async {
    // Configure dialog service theme
    _dialogService.configureTheme(theme ?? WalletDialogTheme());

    // Configure provider info
    _eip6963ProviderInfo = providerInfo;

    _updateNetwork(defaultNetwork);

    // Initialize Web3 client
    _web3client = Web3Client(
      defaultNetwork.rpcUrls.first,
      Client(),
    );

    // Initialize credentials
    _credentials = EthPrivateKey.fromHex(privateKey);

    // Initialize handlers
    _txHandler = TransactionHandler(
      _web3client,
      _credentials,
      int.parse(defaultNetwork.chainId.substring(2), radix: 16),
    );
    _signingHandler = SigningHandler(_credentials);

    // Setup initial state
    _state = WalletState(
      chainId: defaultNetwork.chainId,
      address: getAddressFromPrivateKey(privateKey),
      isConnected: getAddressFromPrivateKey(privateKey) != null,
    );

    // Add networks
    _addNetwork(defaultNetwork);
    for (var network in additionalNetworks) {
      _addNetwork(network);
    }
  }

  getAddressFromPrivateKey(String privateKey) {
    final credentials = EthPrivateKey.fromHex(privateKey);
    final address = credentials.address;
    return address.hexEip55;
  }

  Future<dynamic> handleRequest(String method, List<dynamic>? params) async {
    if (_context == null) {
      throw WalletException('Provider context not set');
    }
    try {
      switch (JsonRpcMethod.fromString(method)) {
        case JsonRpcMethod.ETH_REQUEST_ACCOUNTS:
          return await _handleConnect();
        case JsonRpcMethod.ETH_ACCOUNTS:
          return _getConnectedAccounts();
        case JsonRpcMethod.ETH_BLOCK_NUMBER:
          return await _handleBlockNumber();
        case JsonRpcMethod.ETH_CHAIN_ID:
          return _state.chainId;
        case JsonRpcMethod.NET_VERSION:
          return _state.chainId;
        case JsonRpcMethod.ETH_CALL:
          return await _txHandler.handleTransaction(params?.first);
        case JsonRpcMethod.ETH_SEND_TRANSACTION:
          if (params == null || params.isEmpty) {
            throw WalletException('Missing call parameters');
          }
          return await _handleSignTransaction(params.first);
        case JsonRpcMethod.ETH_GET_BALANCE:
          final address = params?.first;
          final balance = await _web3client.getBalance(
            EthereumAddress.fromHex(address),
          );
          return balance.getInEther.toString();
        case JsonRpcMethod.ETH_GAS_PRICE:
          final gasPrice = await _web3client.getGasPrice();
          return gasPrice.getInWei.toString();
        case JsonRpcMethod.ETH_ESTIMATE_GAS:
          if (params == null || params.isEmpty) {
            throw WalletException('Missing transaction parameters');
          }
          return await _txHandler.estimateGas(params[0]);
        case JsonRpcMethod.PERSONAL_SIGN:
        case JsonRpcMethod.ETH_SIGN:
        case JsonRpcMethod.ETH_SIGN_TYPED_DATA:
        case JsonRpcMethod.ETH_SIGN_TYPED_DATA_V1:
        case JsonRpcMethod.ETH_SIGN_TYPED_DATA_V3:
        case JsonRpcMethod.ETH_SIGN_TYPED_DATA_V4:
          if (params == null || params.isEmpty) {
            throw WalletException('Missing sign parameters');
          }
          return await _handleSignMessage(method, params);
        case JsonRpcMethod.PERSONAL_EC_RECOVER:
          if (params == null || params.isEmpty) {
            throw WalletException('Missing sign parameters');
          }
          return _signingHandler.personalEcRecover(params[0], params[1]);
        case JsonRpcMethod.WALLET_SWITCH_ETHEREUM_CHAIN:
          if (params?.isNotEmpty == true) {
            final newChainId = params?.first['chainId'];
            return await _handleSwitchNetwork(newChainId);
          }
          throw WalletException('Invalid chain ID');
        case JsonRpcMethod.WALLET_ADD_ETHEREUM_CHAIN:
          if (params?.isNotEmpty == true) {
            return await _handleAddEthereumChain(params?.first);
          }
          throw WalletException('Invalid network parameters');
        case JsonRpcMethod.WALLET_GET_PERMISSIONS:
          return ['eth_accounts', 'eth_chainId', 'personal_sign'];
        case JsonRpcMethod.WALLET_REVOKE_PERMISSIONS:
          return true;
        default:
          print('=======================> Method $method not supported');
          return null;
        // throw WalletException('Method $method not supported');
      }
    } catch (e) {
      throw WalletException(e.toString());
    }
  }

  String getProviderScript() {
    return ProviderScriptGenerator.generate(
      chainId: _state.chainId,
      accounts: _getConnectedAccounts(),
      isConnected: _state.isConnected,
      providerInfo: _eip6963ProviderInfo!,
    );
  }

  void dispose() {
    _stateController.close();
    _web3client.dispose();
  }

  // Method handlers
  Future<List<String>> _handleConnect() async {
    try {
      final confirmed = await _dialogService.showConnectWallet(
        _context!,
        address: _state.address!,
        ctrl: _webViewController!,
        appName: _eip6963ProviderInfo!.name,
      );

      if (confirmed != true) {
        throw WalletException('User rejected connection');
      }

      _updateState(
        address: _state.address,
        isConnected: true,
      );

      return [_state.address!];
    } catch (e) {
      _updateState(
        address: null,
        isConnected: false,
      );
      rethrow;
    }
  }

  Future<String> _handleSignMessage(String method, List<dynamic> params) async {
    try {
      var message = params.first;
      String from = params[1];
      String password = params.length > 2 ? params[2] : '';
      if (JsonRpcMethod.ETH_SIGN == JsonRpcMethod.fromString(method) ||
          JsonRpcMethod.ETH_SIGN_TYPED_DATA_V3 ==
              JsonRpcMethod.fromString(method) ||
          JsonRpcMethod.ETH_SIGN_TYPED_DATA_V4 ==
              JsonRpcMethod.fromString(method)) {
        from = params.first;
        message = params[1];
      }
      final confirmed = await _dialogService.showSignMessage(
        _context!,
        message: message.toString(),
        address: _state.address!,
        ctrl: _webViewController!,
      );

      if (confirmed != true) {
        throw WalletException('User rejected signing message');
      }

      return await _signingHandler
          .signMessage(method, from, message, password)
          .withLoading(_context!, 'Waiting for signature');
    } catch (e) {
      throw WalletException('Failed to sign message: $e');
    }
  }

  Future _handleSignTransaction(Map<String, dynamic> params) async {
    try {
      final confirmed = await _dialogService.showTransactionConfirm(
        _context!,
        txParams: params,
        ctrl: _webViewController!,
      );

      if (confirmed != true) {
        throw WalletException('User rejected signing transaction');
      }

      return await _txHandler
          .handleTransaction(params)
          .withLoading(_context!, 'Waiting for transaction');
    } catch (e) {
      throw WalletException('Failed to sign transaction: $e');
    }
  }

  Future<bool> _handleSwitchNetwork(String newChainId) async {
    if (!_networks.containsKey(newChainId)) {
      throw WalletException('Network not supported: $newChainId');
    }
    try {
      final network = _networks[newChainId]!;

      final confirmed = await _dialogService.showSwitchNetwork(
        _context!,
        chain: network,
      );

      if (confirmed != true) {
        throw WalletException('User rejected network switch');
      }

      _updateState(chainId: newChainId);
      await _emitToWebView('chainChanged', newChainId);
      await _updateNetwork(network).withLoading(_context!, 'Switching network');
      return true;
    } catch (e) {
      throw WalletException('Network switch failed: $e');
    }
  }

  Future<bool> _handleAddEthereumChain(
      Map<String, dynamic> networkParams) async {
    try {
      final config = NetworkConfig(
        chainId: networkParams['chainId'],
        chainName: networkParams['chainName'],
        nativeCurrency: NativeCurrency(
          name: networkParams['nativeCurrency']['name'],
          symbol: networkParams['nativeCurrency']['symbol'],
          decimals: networkParams['nativeCurrency']['decimals'],
        ),
        rpcUrls: List<String>.from(networkParams['rpcUrls']),
        blockExplorerUrls: networkParams['blockExplorerUrls'] != null
            ? List<String>.from(networkParams['blockExplorerUrls'])
            : null,
      );
      // Show add network confirmation
      final confirmed = await _dialogService.showAddNetwork(
        _context!,
        network: config,
      );

      if (confirmed != true) {
        throw WalletException('User rejected adding network');
      }
      _addNetwork(config);
      return true;
    } catch (e) {
      throw WalletException('Failed to add network: ${e.toString()}');
    }
  }

  List<String> _getConnectedAccounts() {
    return _state.address != null ? [_state.address!] : [];
  }

  Future<String> _handleBlockNumber() async {
    try {
      if (_isBlockNumberCacheValid()) {
        return _cachedBlockNumber!;
      }

      final blockNumber = await _fetchBlockNumber();
      _updateBlockNumberCache(blockNumber);
      return blockNumber;
    } catch (e) {
      throw WalletException('Failed to get block number: $e');
    }
  }

  // Methods helpers
  void _addNetwork(NetworkConfig network) {
    _networks[network.chainId] = network;
  }

  bool _isBlockNumberCacheValid() {
    if (_lastBlockFetch == null || _cachedBlockNumber == null) {
      return false;
    }
    return DateTime.now().difference(_lastBlockFetch!) <
        _blockNumberCacheDuration;
  }

  void _updateBlockNumberCache(String blockNumber) {
    _cachedBlockNumber = blockNumber;
    _lastBlockFetch = DateTime.now();
  }

  Future<String> _fetchBlockNumber() async {
    try {
      final blockNumber = await _web3client.getBlockNumber();
      return HexUtils.numberToHex(blockNumber);
    } catch (e) {
      throw WalletException('Failed to fetch block number: $e');
    }
  }

  Future<void> _updateNetwork(NetworkConfig network) async {
    _web3client.dispose();
    _web3client = Web3Client(
      network.rpcUrls.first,
      Client(),
    );
    _txHandler = TransactionHandler(
      _web3client,
      _credentials,
      int.parse(network.chainId.substring(2), radix: 16),
    );
  }

  void _updateState({String? address, bool? isConnected, String? chainId}) {
    _state = _state.copyWith(
      address: address,
      isConnected: isConnected,
      chainId: chainId,
    );
    _stateController.add(_state);
  }

  Future<void> _emitToWebView(String eventName, dynamic data) async {
    if (_webViewController != null) {
      final js = """
        if (window.ethereum) {
          window.ethereum._emit('$eventName', ${jsonEncode(data)});
        }
      """;
      await _webViewController!.evaluateJavascript(source: js);
    }
  }
}
