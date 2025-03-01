// lib/ethereum/transaction/transaction_handler.dart
import 'dart:typed_data';
import 'package:web3dart/web3dart.dart';
import '../utils/hex_utils.dart';
import '../exceptions.dart';
import '../utils/validation_utils.dart';

class TransactionHandler {
  final Web3Client _web3client;
  final Credentials _credentials;
  final int _chainId;

  Function(Map<String, dynamic> txParams) get estimateGas => _estimateGas;

  TransactionHandler(this._web3client, this._credentials, this._chainId);

  Future<String> handleTransaction(Map<String, dynamic> txParams) async {
    try {
      // Validate transaction
      _validateTransaction(txParams);

      // Prepare transaction
      final tx = await _prepareTransaction(txParams);

      // Sign transaction
      final signedTx = await _signTransaction(tx);

      // Send transaction
      final txHash = await _sendTransaction(signedTx);

      // Monitor transaction
      await _monitorTransaction(txHash);

      return txHash;
    } catch (e) {
      throw WalletException('Transaction failed: $e');
    }
  }

  void _validateTransaction(Map<String, dynamic> txParams) {
    if (!txParams.containsKey('to')) {
      throw WalletException("Missing 'to' address");
    }

    final to = txParams['to'] as String;
    if (!ValidationUtils.isValidAddress(to)) {
      throw WalletException("Invalid 'to' address format");
    }

    if (txParams.containsKey('value')) {
      final value = txParams['value'] as String;
      if (!ValidationUtils.isValidHexValue(value)) {
        throw WalletException("Invalid 'value' format");
      }
    }

    if (txParams.containsKey('data')) {
      final data = txParams['data'] as String;
      if (!ValidationUtils.isValidHexData(data)) {
        throw WalletException("Invalid 'data' format");
      }
    }
  }

  Future<Transaction> _prepareTransaction(Map<String, dynamic> params) async {
    final from = EthereumAddress.fromHex(params['from']);
    final to = EthereumAddress.fromHex(params['to']);

    // Parse value
    BigInt value = BigInt.zero;
    if (params['value'] != null) {
      value = HexUtils.hexToBigInt(params['value']);
    }

    // Get nonce
    final nonce = await _web3client.getTransactionCount(from);

    // Estimate gas
    final gasLimit = await _estimateGas(params);

    // Get gas price
    final gasPrice = await _getGasPrice(params);

    // Parse data
    Uint8List? data;
    if (params['data'] != null) {
      data = HexUtils.hexToBytes(params['data']);
    }

    return Transaction(
      from: from,
      to: to,
      value: EtherAmount.fromBigInt(EtherUnit.wei, value),
      gasPrice: EtherAmount.fromBigInt(EtherUnit.wei, gasPrice),
      maxGas: gasLimit.toInt(),
      nonce: nonce,
      data: data,
    );
  }

  Future<BigInt> _estimateGas(Map<String, dynamic> txParams) async {
    try {
      final estimation = await _web3client.estimateGas(
        sender: txParams['from'] != null
            ? EthereumAddress.fromHex(txParams['from'])
            : null,
        to: txParams['to'] != null
            ? EthereumAddress.fromHex(txParams['to'])
            : null,
        value: txParams['value'] != null
            ? EtherAmount.fromBigInt(
                EtherUnit.wei,
                HexUtils.hexToBigInt(txParams['value']),
              )
            : null,
        data: txParams['data'] != null
            ? HexUtils.hexToBytes(txParams['data'])
            : null,
      );

      // Add 20% buffer
      final estimationDouble = estimation.toDouble();
      final bufferedEstimation = (estimationDouble * 1.2).ceil();

      return BigInt.from(bufferedEstimation);
    } catch (e) {
      throw WalletException('Failed to estimate gas: $e');
    }
  }

  Future<BigInt> _getGasPrice(Map<String, dynamic> params) async {
    if (params['gasPrice'] != null) {
      return HexUtils.hexToBigInt(params['gasPrice']);
    }

    final currentGasPrice = await _web3client.getGasPrice();
    return currentGasPrice.getInWei;
  }

  Future<Uint8List> _signTransaction(Transaction tx) async {
    try {
      return await _web3client.signTransaction(
        _credentials,
        tx,
        chainId: _chainId,
      );
    } catch (e) {
      throw WalletException('Failed to sign transaction: $e');
    }
  }

  Future<String> _sendTransaction(Uint8List signedTx) async {
    try {
      return await _web3client.sendRawTransaction(signedTx);
    } catch (e) {
      throw WalletException('Failed to send transaction: $e');
    }
  }

  Future<void> _monitorTransaction(String txHash) async {
    bool confirmed = false;
    int retries = 0;
    const maxRetries = 30; // 5 minutes timeout

    while (!confirmed && retries < maxRetries) {
      try {
        final receipt = await _web3client.getTransactionReceipt(txHash);

        if (receipt != null) {
          confirmed = true;

          if (receipt.status != true) {
            throw WalletException('Transaction failed');
          }

          return;
        }

        await Future.delayed(Duration(seconds: 10));
        retries++;
      } catch (e) {
        await Future.delayed(Duration(seconds: 10));
        retries++;
      }
    }

    if (!confirmed) {
      throw WalletException('Transaction confirmation timeout');
    }
  }
}
