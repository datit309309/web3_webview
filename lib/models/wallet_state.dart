// lib/ethereum/models/wallet_state.dart
class WalletState {
  final String? address;
  final bool isConnected;
  final String chainId;

  WalletState({
    this.address,
    this.isConnected = false,
    required this.chainId,
  });

  WalletState copyWith({
    String? address,
    bool? isConnected,
    String? chainId,
  }) {
    return WalletState(
      address: address ?? this.address,
      isConnected: isConnected ?? this.isConnected,
      chainId: chainId ?? this.chainId,
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'isConnected': isConnected,
        'chainId': chainId,
      };

  factory WalletState.fromJson(Map<String, dynamic> json) {
    return WalletState(
      address: json['address'],
      isConnected: json['isConnected'],
      chainId: json['chainId'],
    );
  }
}
