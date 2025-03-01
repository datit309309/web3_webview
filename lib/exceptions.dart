// lib/ethereum/exceptions.dart
class WalletException implements Exception {
  final String message;

  WalletException(this.message);

  @override
  String toString() => message;
}
