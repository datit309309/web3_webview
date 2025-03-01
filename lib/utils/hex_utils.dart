// lib/ethereum/utils/hex_utils.dart
import 'package:flutter/services.dart';

import '../exceptions.dart';

class HexUtils {
  static String bytesToHex(List<int> bytes, {bool include0x = false}) {
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return include0x ? '0x$hex' : hex;
  }

  static Uint8List hexToBytes(String hexStr) {
    final hex = hexStr.startsWith('0x') ? hexStr.substring(2) : hexStr;
    if (hex.length % 2 != 0) {
      throw WalletException('Invalid hex string');
    }

    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      final byteHex = hex.substring(i * 2, (i * 2) + 2);
      bytes[i] = int.parse(byteHex, radix: 16);
    }
    return bytes;
  }

  static String numberToHex(dynamic number) {
    BigInt bigInt;

    if (number is BigInt) {
      bigInt = number;
    } else if (number is int) {
      bigInt = BigInt.from(number);
    } else if (number is String) {
      if (number.contains('.')) {
        throw WalletException('Decimal numbers not supported');
      }
      try {
        bigInt = BigInt.parse(number);
      } catch (e) {
        throw WalletException('Invalid number string: $number');
      }
    } else {
      throw WalletException('Unsupported number type: ${number.runtimeType}');
    }

    if (bigInt < BigInt.zero) {
      throw WalletException('Negative numbers not supported');
    }

    if (bigInt == BigInt.zero) {
      return '0x0';
    }

    String hex = bigInt.toRadixString(16);
    if (hex.length % 2 != 0) {
      hex = '0$hex';
    }

    return '0x$hex';
  }

  static BigInt hexToBigInt(String hex) {
    if (!hex.startsWith('0x')) {
      throw WalletException('Hex string must start with 0x');
    }
    return BigInt.parse(hex.substring(2), radix: 16);
  }
}
