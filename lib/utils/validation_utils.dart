// lib/ethereum/utils/validation_utils.dart
import 'package:web3dart/credentials.dart';

import 'hex_utils.dart';

class ValidationUtils {
  static bool isValidAddress(String address) {
    if (!address.startsWith('0x')) return false;
    if (address.length != 42) return false;

    try {
      EthereumAddress.fromHex(address);
      return true;
    } catch (e) {
      return false;
    }
  }

  static bool isValidHexValue(String value) {
    if (!value.startsWith('0x')) return false;

    try {
      BigInt.parse(value.substring(2), radix: 16);
      return true;
    } catch (e) {
      return false;
    }
  }

  static bool isValidHexData(String data) {
    if (!data.startsWith('0x')) return false;
    if (data.length % 2 != 0) return false;

    try {
      HexUtils.hexToBytes(data);
      return true;
    } catch (e) {
      return false;
    }
  }
}
