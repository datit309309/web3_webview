// lib/ethereum/ethereum_provider.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

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

  Future<void> initialize({
    required NetworkConfig defaultNetwork,
    required String privateKey,
    required EIP6963ProviderInfo providerInfo,
    List<NetworkConfig> additionalNetworks = const [],
    String? initialAddress,
    WalletDialogTheme? theme,
  }) async {
    // Configure dialog service theme
    _dialogService.configureTheme(theme ?? WalletDialogTheme());

    // Configure provider info
    _eip6963ProviderInfo = providerInfo;

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
      address: initialAddress,
      isConnected: initialAddress != null,
    );

    // Add networks
    _addNetwork(defaultNetwork);
    for (var network in additionalNetworks) {
      _addNetwork(network);
    }
  }

  void setWebViewController(InAppWebViewController controller) {
    _webViewController = controller;
  }

  void _addNetwork(NetworkConfig network) {
    _networks[network.chainId] = network;
  }

  Future<dynamic> handleRequest(String method, List<dynamic>? params) async {
    if (_context == null) {
      throw WalletException('Provider context not set');
    }

    try {
      switch (method) {
        case 'eth_requestAccounts':
          return await _handleConnect();
        case 'eth_accounts':
          return _getConnectedAccounts();
        case 'eth_blockNumber':
          return await _handleBlockNumber();
        case 'eth_chainId':
          return _state.chainId;
        case 'net_version':
          return _state.chainId;
        case 'eth_sendTransaction':
          return await _txHandler.handleTransaction(params?.first);
        case 'eth_getBalance':
          final address = params?.first;
          final balance = await _web3client.getBalance(
            EthereumAddress.fromHex(address),
          );
          return balance.getInEther.toString();
        case 'eth_estimateGas':
          if (params == null || params.isEmpty) {
            throw WalletException('Missing transaction parameters');
          }
          return await _txHandler.estimateGas(params[0]);
        case 'personal_sign':
        case 'eth_sign':
        case 'eth_signTypedData_v4':
          return await _signingHandler.signMessage({
            'type': method,
            'from': params?[0],
            'message': params?[1],
          });
        case 'wallet_switchEthereumChain':
          if (params?.isNotEmpty == true) {
            final newChainId = params?.first['chainId'];
            return await switchNetwork(newChainId);
          }
          throw WalletException('Invalid chain ID');
        case 'wallet_addEthereumChain':
          if (params?.isNotEmpty == true) {
            return await _addEthereumChain(params?.first);
          }
          throw WalletException('Invalid network config');
        default:
          debugPrint('Method $method not supported');
        // throw WalletException('Method $method not supported');
      }
    } catch (e) {
      throw WalletException(e.toString());
    }
  }

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

  Future<bool> switchNetwork(String newChainId) async {
    if (!_networks.containsKey(newChainId)) {
      throw WalletException('Network not configured');
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
      await _updateNetwork(network);
      await _emitToWebView('chainChanged', newChainId);

      return true;
    } catch (e) {
      throw WalletException('Network switch failed: $e');
    }
  }

  Future<bool> _addEthereumChain(Map<String, dynamic> networkParams) async {
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
}
