import 'package:flutter/services.dart';

extension BigIntX on BigInt {
  double toRealDouble(int decimals) {
    return this / BigInt.from(10).pow(decimals);
  }

  double parseGwei() {
    return this / BigInt.from(10).pow(9);
  }

  double parseEther() {
    return this / BigInt.from(10).pow(18);
  }
}

extension BigIntExtension on BigInt {
  Uint8List toBytes() {
    if (this == BigInt.zero) return Uint8List.fromList([0]);

    var hex = toRadixString(16);
    if (hex.length % 2 != 0) hex = '0' + hex;

    var bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }
}
