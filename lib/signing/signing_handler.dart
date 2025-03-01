// lib/ethereum/signing/signing_handler.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:web3_webview/utils/bigint_utils.dart';
import 'package:web3dart/crypto.dart' as crypto;
import 'package:web3dart/web3dart.dart';
import '../utils/hex_utils.dart';
import '../exceptions.dart';

enum SigningType { PERSONAL_SIGN, TYPED_DATA_V4, ETH_SIGN }

class SigningHandler {
  final Credentials _credentials;

  SigningHandler(this._credentials);

  Future<String> signMessage(Map<String, dynamic> params) async {
    try {
      final type = _getSigningType(params['type']);
      final from = params['from'];
      final message = params['message'];

      // Validate signer
      await _validateSigner(from);

      switch (type) {
        case SigningType.PERSONAL_SIGN:
        case SigningType.ETH_SIGN:
          return await _personalSign(message);
        case SigningType.TYPED_DATA_V4:
          if (message is! Map<String, dynamic>) {
            throw WalletException('Invalid typed data format');
          }
          return await _signTypedDataV4(message);
      }
    } catch (e) {
      throw WalletException('Signing failed: $e');
    }
  }

  Future<void> _validateSigner(String address) async {
    final credentialsAddress = await _credentials.extractAddress();
    if (credentialsAddress.hex.toLowerCase() != address.toLowerCase()) {
      throw WalletException('Signer address does not match current account');
    }
  }

  Future<String> _personalSign(dynamic message) async {
    try {
      Uint8List messageBytes;
      if (message is String) {
        if (message.startsWith('0x')) {
          messageBytes = HexUtils.hexToBytes(message);
        } else {
          messageBytes = Uint8List.fromList(utf8.encode(message));
        }
      } else {
        throw WalletException('Invalid message format for personal_sign');
      }

      final signature =
          _credentials.signPersonalMessageToUint8List(messageBytes);
      return HexUtils.bytesToHex(signature, include0x: true);
    } catch (e) {
      throw WalletException('Personal sign failed: $e');
    }
  }

  Future<String> _signTypedDataV4(Map<String, dynamic> typedData) async {
    try {
      if (!_isValidTypedDataV4(typedData)) {
        throw WalletException('Invalid EIP-712 typed data structure');
      }

      // Create domain separator
      final domainSeparator = _hashStruct(
        typedData['domain'],
        typedData['types']['EIP712Domain'],
        typedData['types'],
      );

      // Hash message
      final messageHash = _hashStruct(
        typedData['message'],
        typedData['types'][typedData['primaryType']],
        typedData['types'],
      );

      // Combine hashes according to EIP-712
      final Uint8List encodedData = Uint8List.fromList([
        ...utf8.encode('\x19\x01'),
        ...domainSeparator,
        ...messageHash,
      ]);

      final Uint8List hash = crypto.keccak256(encodedData);
      final signature = await _credentials.signPersonalMessage(hash);

      return HexUtils.bytesToHex(signature, include0x: true);
    } catch (e) {
      throw WalletException('Sign typed data v4 failed: $e');
    }
  }

  Uint8List _hashStruct(
    Map<String, dynamic> data,
    List<Map<String, String>> types,
    Map<String, List<Map<String, String>>> allTypes,
  ) {
    // Encode type data
    final List<String> encodedTypes = types.map((field) {
      final String fieldType = field['type']!;
      if (_isElementaryType(fieldType)) {
        return '$fieldType ${field['name']}';
      } else {
        return '$fieldType ${field['name']}(${_encodeType(fieldType, allTypes)})';
      }
    }).toList();

    // Create type hash
    final String typeString = encodedTypes.join(',');
    final Uint8List typeHash = crypto.keccak256(utf8.encode(typeString));

    // Encode values
    final List<Uint8List> encodedValues = types.map((field) {
      final value = data[field['name']];
      return _encodeValue(value, field['type']!);
    }).toList();

    // Combine and hash
    return crypto.keccak256(Uint8List.fromList([
      ...typeHash,
      ...encodedValues.expand((x) => x),
    ]));
  }

  bool _isElementaryType(String type) {
    return [
      'address',
      'bool',
      'string',
      'bytes',
      ...List.generate(32, (i) => 'bytes${i + 1}'),
      ...List.generate(256, (i) => 'uint${i + 1}'),
      ...List.generate(256, (i) => 'int${i + 1}'),
    ].contains(type);
  }

  String _encodeType(
    String primaryType,
    Map<String, List<Map<String, String>>> types,
  ) {
    final List<Map<String, String>> fields = types[primaryType] ?? [];
    return fields.map((field) => '${field['type']} ${field['name']}').join(',');
  }

  Uint8List _encodeValue(dynamic value, String type) {
    if (type == 'string' || type == 'bytes') {
      return crypto.keccak256(utf8.encode(value.toString()));
    } else if (type == 'bool') {
      return Uint8List.fromList(value ? [1] : [0]);
    } else if (type.startsWith('uint') || type.startsWith('int')) {
      final bigInt = BigInt.parse(value.toString());
      return _padTo32(bigInt.toBytes());
    } else if (type == 'address') {
      return _padTo32(HexUtils.hexToBytes(value));
    } else {
      throw WalletException('Unsupported type: $type');
    }
  }

  Uint8List _padTo32(Uint8List input) {
    if (input.length > 32) {
      throw WalletException('Input too long');
    }
    final result = Uint8List(32);
    result.setAll(32 - input.length, input);
    return result;
  }

  bool _isValidTypedDataV4(Map<String, dynamic> typedData) {
    return typedData.containsKey('types') &&
        typedData.containsKey('primaryType') &&
        typedData.containsKey('domain') &&
        typedData.containsKey('message') &&
        typedData['types'].containsKey('EIP712Domain');
  }

  SigningType _getSigningType(String type) {
    switch (type.toLowerCase()) {
      case 'personal_sign':
        return SigningType.PERSONAL_SIGN;
      case 'eth_sign':
        return SigningType.ETH_SIGN;
      case 'eth_signtypeddata_v4':
        return SigningType.TYPED_DATA_V4;
      default:
        throw WalletException('Unsupported signing type: $type');
    }
  }
}
