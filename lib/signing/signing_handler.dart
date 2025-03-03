// lib/ethereum/signing/signing_handler.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:hex/hex.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import '../json_rpc_method.dart';
import '../utils/hex_utils.dart';
import '../exceptions.dart';

class SigningHandler {
  final Credentials _credentials;

  SigningHandler(this._credentials);

  Future<String> signMessage(
      String method, String from, dynamic message, String password) async {
    try {
      // Validate signer
      await _validateSigner(from);

      switch (JsonRpcMethod.fromString(method)) {
        case JsonRpcMethod.PERSONAL_SIGN:
        case JsonRpcMethod.ETH_SIGN:
          return await _personalSign(message);
        case JsonRpcMethod.ETH_SIGN_TYPED_DATA:
          return await _signTypedData(message[0]);
        case JsonRpcMethod.ETH_SIGN_TYPED_DATA_V1:
          return await _signTypedDataV1(message);
        case JsonRpcMethod.ETH_SIGN_TYPED_DATA_V3:
          return await _signTypedDataV3(jsonDecode(message));
        case JsonRpcMethod.ETH_SIGN_TYPED_DATA_V4:
          return await _signTypedDataV4(jsonDecode(message));
        default:
          throw WalletException('Unsupported signing method: $method');
      }
    } catch (e) {
      throw WalletException('Signing failed: $e');
    }
  }

  Future<void> _validateSigner(String address) async {
    final credentialsAddress = _credentials.address;
    if (credentialsAddress.hex.toLowerCase() != address.toLowerCase()) {
      throw WalletException('Signer address does not match current account');
    }
  }

  Future<String> _personalSign(dynamic message) async {
    try {
      Uint8List messageBytes;

      if (message is! String) {
        throw WalletException('Message must be a string');
      }

      if (message.startsWith('0x')) {
        // Nếu là hex string, decode trực tiếp thành bytes
        messageBytes = HexUtils.hexToBytes(message);
        // Thêm prefix sau khi decode hex
        // final prefix = '\x19Ethereum Signed Message:\n${messageBytes.length}';
        const prefix = ''; // Không cần prefix cho hex string
        messageBytes =
            Uint8List.fromList([...utf8.encode(prefix), ...messageBytes]);
      } else {
        // Nếu là plain text
        final utf8Bytes = utf8.encode(message);
        // final prefix = '\x19Ethereum Signed Message:\n${utf8Bytes.length}';
        const prefix = ''; // Không cần prefix cho plain text
        messageBytes =
            Uint8List.fromList([...utf8.encode(prefix), ...utf8Bytes]);
      }

      final signature =
          _credentials.signPersonalMessageToUint8List(messageBytes);
      return HexUtils.bytesToHex(signature, include0x: true);
    } catch (e) {
      throw WalletException('Personal sign failed: $e');
    }
  }

  Future<String> _signTypedData(dynamic message) async {
    try {
      if (message is! Map<String, dynamic>) {
        throw WalletException('Invalid typed data format');
      }

      // Legacy typed data signing (pre-EIP-712)
      final encodedData = TypedDataEncoder.encodeBasic(message);
      final signature = _credentials.signToUint8List(encodedData);
      return HexUtils.bytesToHex(signature, include0x: true);
    } catch (e) {
      throw WalletException('Typed data sign failed: $e');
    }
  }

  Future<String> _signTypedDataV1(dynamic message) async {
    try {
      if (message is! List) {
        throw WalletException('Invalid typed data v1 format - expected array');
      }

      // EIP-712 v1 signing
      final encodedData = TypedDataEncoder.encodeV1(message);
      final signature = _credentials.signToUint8List(encodedData);
      return HexUtils.bytesToHex(signature, include0x: true);
    } catch (e) {
      throw WalletException('Typed data v1 sign failed: $e');
    }
  }

  Future<String> _signTypedDataV3(dynamic message) async {
    try {
      if (message is! Map<String, dynamic>) {
        throw WalletException('Invalid typed data v3 format');
      }

      // Validate required fields for v3
      if (!message.containsKey('types') ||
          !message.containsKey('primaryType') ||
          !message.containsKey('domain') ||
          !message.containsKey('message')) {
        throw WalletException('Missing required fields for typed data v3');
      }

      // EIP-712 v3 signing
      final typedData = TypedData.fromJson(message);

      // Convert message to bytes following EIP-712
      final encodedData = _encodeTypedDataV3(typedData);
      final signature = _credentials.signToUint8List(encodedData);
      return HexUtils.bytesToHex(signature, include0x: true);
    } catch (e) {
      throw WalletException('Typed data v3 sign failed: $e');
    }
  }

  Future<String> _signTypedDataV4(dynamic message) async {
    try {
      if (message is! Map<String, dynamic>) {
        throw WalletException('Invalid typed data v4 format');
      }

      // Validate required fields for v4
      if (!message.containsKey('types') ||
          !message.containsKey('primaryType') ||
          !message.containsKey('domain') ||
          !message.containsKey('message')) {
        throw WalletException('Missing required fields for typed data v4');
      }

      // Additional v4 validations
      if (!message['types'].containsKey('EIP712Domain')) {
        throw WalletException('Missing EIP712Domain type definition');
      }

      // EIP-712 v4 signing
      final typedData = TypedData.fromJson(message);

      // Convert message to bytes following EIP-712
      final encodedData = _encodeTypedDataV4(typedData);
      final signature = _credentials.signToUint8List(encodedData);
      return HexUtils.bytesToHex(signature, include0x: true);
    } catch (e) {
      throw WalletException('Typed data v4 sign failed: $e');
    }
  }

  Uint8List _encodeTypedDataV3(TypedData typedData) {
    // Implement EIP-712 encoding for v3
    // This should encode domain separator and message following EIP-712 spec
    final domainSeparator =
        _hashStruct('EIP712Domain', typedData.domain, typedData.types);
    final messageHash =
        _hashStruct(typedData.primaryType, typedData.message, typedData.types);

    return keccak256(Uint8List.fromList([
      ...utf8.encode('\x19\x01'),
      ...domainSeparator,
      ...messageHash,
    ]));
  }

  Uint8List _encodeTypedDataV4(TypedData typedData) {
    // Validate domain fields according to EIP-712
    final validDomainFields = {
      'name': true,
      'version': true,
      'chainId': true,
      'verifyingContract': true,
      'salt': true
    };

    // Check domain fields
    for (final field in typedData.domain.keys) {
      if (!validDomainFields.containsKey(field)) {
        throw WalletException('Invalid domain field: $field');
      }
    }

    // Validate types
    _validateTypesV4(typedData.types);

    // Encode domain separator
    final domainSeparator =
        _hashStruct('EIP712Domain', typedData.domain, typedData.types);

    // Encode primary type
    final messageHash =
        _hashStruct(typedData.primaryType, typedData.message, typedData.types);

    // Concatenate according to EIP-712
    return keccak256(Uint8List.fromList([
      ...utf8.encode('\x19\x01'),
      ...domainSeparator,
      ...messageHash,
    ]));
  }

  /// Khôi phục địa chỉ Ethereum từ chữ ký được tạo bởi personal_sign
  String personalEcRecover(String message, String signature) {
    try {
      // Chuẩn bị message
      Uint8List messageBytes;
      if (message.startsWith('0x')) {
        messageBytes = hexToBytes(message.substring(2));
      } else {
        messageBytes = Uint8List.fromList(utf8.encode(message));
      }

      // Tạo prefix theo chuẩn Ethereum
      // final prefix = '\u0019Ethereum Signed Message:\n${messageBytes.length}';
      const prefix = '';
      final prefixBytes = Uint8List.fromList(utf8.encode(prefix));

      // Kết hợp prefix và message
      final prefixedMessage =
          Uint8List(prefixBytes.length + messageBytes.length);
      prefixedMessage.setAll(0, prefixBytes);
      prefixedMessage.setAll(prefixBytes.length, messageBytes);

      // Hash message đã được prefix
      final Uint8List hash = keccak256(prefixedMessage);

      // Xử lý signature
      String sigHex = signature;
      if (sigHex.startsWith('0x')) {
        sigHex = sigHex.substring(2);
      }

      // Đảm bảo signature có độ dài đúng
      if (sigHex.length != 130) {
        throw Exception(
            'Invalid signature length: ${sigHex.length} chars, expected 130');
      }

      // Tách r, s, v từ signature
      final r = BigInt.parse(sigHex.substring(0, 64), radix: 16);
      final s = BigInt.parse(sigHex.substring(64, 128), radix: 16);

      // Lấy v từ byte cuối cùng và điều chỉnh nếu cần
      int v = int.parse(sigHex.substring(128, 130), radix: 16);
      if (v < 27) {
        v += 27;
      }

      // Tạo MsgSignature
      final msgSignature = MsgSignature(r, s, v);

      // Khôi phục public key
      final Uint8List publicKey = ecRecover(hash, msgSignature);

      // Chuyển public key thành địa chỉ
      final EthereumAddress address = EthereumAddress.fromPublicKey(publicKey);
      return address.hexEip55;
    } catch (e) {
      throw Exception('Failed to recover address: $e');
    }
  }

  /// Lấy encryption public key từ private key sử dụng web3dart
  String getEncryptionPublicKey(String privateKeyHex) {
    try {
      // 1. Parse private key
      final privateKey = EthPrivateKey.fromHex(privateKeyHex.startsWith('0x')
          ? privateKeyHex.substring(2)
          : privateKeyHex);

      // 2. Lấy public key dạng compressed
      final publicKeyPoints = privateKey.encodedPublicKey;

      // 3. Convert sang compressed format (33 bytes)
      // Prefix (0x02 nếu y chẵn, 0x03 nếu y lẻ) + x coordinates
      final compressedPubKey = Uint8List(33);
      compressedPubKey[0] = publicKeyPoints[64] & 1 == 0 ? 0x02 : 0x03;
      compressedPubKey.setRange(1, 33, publicKeyPoints.sublist(1, 33));

      // 4. Convert sang hex và thêm prefix 0x
      return '0x${HEX.encode(compressedPubKey)}';
    } catch (e) {
      throw Exception('Failed to get encryption public key: $e');
    }
  }

  void _validateTypesV4(Map<String, dynamic> types) {
    // Ensure EIP712Domain type is present
    if (!types.containsKey('EIP712Domain')) {
      throw WalletException('Missing EIP712Domain type definition');
    }

    // Validate each type definition
    for (final type in types.entries) {
      final fields = type.value as List;
      final seenFields = <String>{};

      for (final field in fields) {
        if (field is! Map) {
          throw WalletException('Invalid type definition for ${type.key}');
        }

        // Check required field properties
        if (!field.containsKey('name') || !field.containsKey('type')) {
          throw WalletException('Missing name or type in field definition');
        }

        final fieldName = field['name'] as String;
        final fieldType = field['type'] as String;

        // Check for duplicate fields
        if (seenFields.contains(fieldName)) {
          throw WalletException(
              'Duplicate field name: $fieldName in type ${type.key}');
        }
        seenFields.add(fieldName);

        // Validate field type
        _validateFieldTypeV4(fieldType, types);
      }
    }
  }

  void _validateFieldTypeV4(String type, Map<String, dynamic> types) {
    // Check array types
    if (type.endsWith('[]')) {
      _validateFieldTypeV4(type.substring(0, type.length - 2), types);
      return;
    }

    // Check fixed-size array types
    final arrayMatch = RegExp(r'^(.+)\[(\d+)\]$').firstMatch(type);
    if (arrayMatch != null) {
      _validateFieldTypeV4(arrayMatch.group(1)!, types);
      return;
    }

    // Check atomic types
    final atomicTypes = {
      'bytes',
      'string',
      'bool',
      'address',
      ...List.generate(32, (i) => 'bytes${i + 1}'),
      ...List.generate(256, (i) => 'uint${i + 1}'),
      ...List.generate(256, (i) => 'int${i + 1}'),
    };

    if (!atomicTypes.contains(type) && !types.containsKey(type)) {
      throw WalletException('Unknown type: $type');
    }

    // Check for circular dependencies
    if (types.containsKey(type)) {
      _checkCircularDependencyV4(type, types, {});
    }
  }

  void _checkCircularDependencyV4(
      String type, Map<String, dynamic> types, Map<String, bool> seen) {
    if (seen.containsKey(type)) {
      if (seen[type]!) {
        throw WalletException('Circular dependency detected: $type');
      }
      return;
    }

    seen[type] = true;

    final fields = types[type] as List;
    for (final field in fields) {
      var fieldType = field['type'] as String;

      // Remove array suffix if present
      if (fieldType.endsWith('[]')) {
        fieldType = fieldType.substring(0, fieldType.length - 2);
      }

      final arrayMatch = RegExp(r'^(.+)\[(\d+)\]$').firstMatch(fieldType);
      if (arrayMatch != null) {
        fieldType = arrayMatch.group(1)!;
      }

      if (types.containsKey(fieldType)) {
        _checkCircularDependencyV4(fieldType, types, Map.from(seen));
      }
    }

    seen[type] = false;
  }

  Uint8List _hashStruct(String primaryType, Map<String, dynamic> data,
      Map<String, dynamic> types) {
    final encodedType = _encodeType(primaryType, types);
    final encodedData = _encodeData(primaryType, data, types);
    return keccak256(Uint8List.fromList([
      ...keccak256(encodedType),
      ...encodedData,
    ]));
  }

  Uint8List _encodeType(String primaryType, Map<String, dynamic> types) {
    // Implement type encoding according to EIP-712
    final buffer = StringBuffer();
    buffer.write(primaryType);
    buffer.write('(');

    final fields = types[primaryType] as List;
    for (var i = 0; i < fields.length; i++) {
      if (i > 0) buffer.write(',');
      buffer.write('${fields[i]['type']} ${fields[i]['name']}');
    }
    buffer.write(')');

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  Uint8List _encodeData(
      String type, dynamic value, Map<String, dynamic> types) {
    // Handle array types
    if (type.endsWith('[]')) {
      if (value is! List) {
        throw WalletException('Expected array value for type $type');
      }

      final baseType = type.substring(0, type.length - 2);
      final elements =
          value.map((item) => _encodeData(baseType, item, types)).toList();
      return keccak256(Buffer.concat(elements));
    }

    // Handle fixed-size array types
    final arrayMatch = RegExp(r'^(.+)\[(\d+)\]$').firstMatch(type);
    if (arrayMatch != null) {
      if (value is! List) {
        throw WalletException('Expected array value for type $type');
      }

      final baseType = arrayMatch.group(1)!;
      final size = int.parse(arrayMatch.group(2)!);

      if (value.length != size) {
        throw WalletException(
            'Array length mismatch. Expected: $size, got: ${value.length}');
      }

      final elements =
          value.map((item) => _encodeData(baseType, item, types)).toList();
      return keccak256(Buffer.concat(elements));
    }

    // Handle struct types
    if (types.containsKey(type)) {
      if (value is! Map<String, dynamic>) {
        throw WalletException('Expected object value for type $type');
      }
      return _encodeStruct(type, value, types);
    }

    // Handle atomic types
    if (type == 'string' || type == 'bytes') {
      return keccak256(Uint8List.fromList(utf8.encode(value.toString())));
    }

    if (type == 'bool') {
      return Uint8List.fromList([value ? 1 : 0]);
    }

    if (type.startsWith('uint') || type.startsWith('int')) {
      final bigInt = BigInt.parse(value.toString());
      return encodeBigInt(bigInt);
    }

    if (type == 'address') {
      // Remove '0x' prefix if present and ensure proper length
      String hexAddress = value.toString().toLowerCase();
      if (hexAddress.startsWith('0x')) {
        hexAddress = hexAddress.substring(2);
      }
      if (hexAddress.length != 40) {
        throw WalletException('Invalid address length');
      }
      return HexUtils.hexToBytes('0x$hexAddress');
    }

    if (type.startsWith('bytes')) {
      if (type == 'bytes') {
        // Dynamic bytes
        final bytes = HexUtils.hexToBytes(value.toString());
        return keccak256(bytes);
      } else {
        // Fixed bytes
        final size = int.parse(type.substring(5));
        final bytes = HexUtils.hexToBytes(value.toString());
        if (bytes.length != size) {
          throw WalletException('Invalid bytes length for $type');
        }
        return bytes;
      }
    }

    throw WalletException('Unsupported type: $type');
  }

  Uint8List _encodeStruct(
      String type, Map<String, dynamic> value, Map<String, dynamic> types) {
    final fields = types[type] as List;
    final List<Uint8List> encodedValues = [];

    for (final field in fields) {
      final name = field['name'] as String;
      final fieldType = field['type'] as String;
      encodedValues.add(_encodeData(fieldType, value[name], types));
    }

    return keccak256(Buffer.concat(encodedValues));
  }
}

// Helper class for encoding typed data
class TypedDataEncoder {
  static Uint8List encodeBasic(Map<String, dynamic> data) {
    // Basic implementation for legacy typed data
    final encoded = jsonEncode(data);
    return keccak256(Uint8List.fromList(utf8.encode(encoded)));
  }

  static Uint8List encodeV1(List data) {
    // Implementation for v1 encoding
    final encoded = jsonEncode(data);
    return keccak256(Uint8List.fromList(utf8.encode(encoded)));
  }
}

// TypedData class for handling EIP-712 structured data
class TypedData {
  final Map<String, dynamic> types;
  final String primaryType;
  final Map<String, dynamic> domain;
  final Map<String, dynamic> message;

  TypedData({
    required this.types,
    required this.primaryType,
    required this.domain,
    required this.message,
  });

  factory TypedData.fromJson(Map<String, dynamic> json) {
    return TypedData(
      types: json['types'] as Map<String, dynamic>,
      primaryType: json['primaryType'] as String,
      domain: json['domain'] as Map<String, dynamic>,
      message: json['message'] as Map<String, dynamic>,
    );
  }
}

class Buffer {
  static Uint8List concat(List<Uint8List> lists) {
    int length = 0;
    for (final list in lists) {
      length += list.length;
    }

    final result = Uint8List(length);
    int offset = 0;

    for (final list in lists) {
      result.setAll(offset, list);
      offset += list.length;
    }

    return result;
  }
}

Uint8List encodeBigInt(BigInt number) {
  if (number == BigInt.zero) {
    return Uint8List.fromList([0]);
  }

  // Convert to bytes removing leading zeros
  var result = number.toUint8List();

  // Ensure the size is 32 bytes for EIP-712
  if (result.length < 32) {
    var padded = Uint8List(32);
    padded.setAll(32 - result.length, result);
    result = padded;
  }

  return result;
}

// Extension method để convert BigInt sang Uint8List
extension BigIntExtension on BigInt {
  Uint8List toUint8List() {
    var hexString = toRadixString(16);
    if (hexString.length % 2 != 0) {
      hexString = '0$hexString';
    }

    var result = Uint8List(hexString.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      var hex = hexString.substring(i * 2, (i * 2) + 2);
      result[i] = int.parse(hex, radix: 16);
    }

    return result;
  }
}
