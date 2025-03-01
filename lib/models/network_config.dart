// lib/ethereum/models/network_config.dart
class NetworkConfig {
  final String chainId;
  final String chainName;
  final NativeCurrency? nativeCurrency;
  final List<String> rpcUrls;
  final List<String>? blockExplorerUrls;
  final List<String>? iconUrls;

  NetworkConfig({
    required this.chainId,
    required this.chainName,
    this.nativeCurrency,
    required this.rpcUrls,
    this.blockExplorerUrls,
    this.iconUrls,
  });

  Map<String, dynamic> toJson() => {
        'chainId': chainId,
        'chainName': chainName,
        'nativeCurrency': nativeCurrency?.toJson(),
        'rpcUrls': rpcUrls,
        'blockExplorerUrls': blockExplorerUrls,
        'iconUrls': iconUrls,
      };

  factory NetworkConfig.fromJson(Map<String, dynamic> json) {
    return NetworkConfig(
      chainId: json['chainId'],
      chainName: json['chainName'],
      nativeCurrency: json['nativeCurrency'] != null
          ? NativeCurrency.fromJson(json['nativeCurrency'])
          : null,
      rpcUrls: List<String>.from(json['rpcUrls']),
      blockExplorerUrls: json['blockExplorerUrls'] != null
          ? List<String>.from(json['blockExplorerUrls'])
          : null,
      iconUrls:
          json['iconUrls'] != null ? List<String>.from(json['iconUrls']) : null,
    );
  }
}

class NativeCurrency {
  final String name;
  final String symbol;
  final int decimals;

  NativeCurrency({
    required this.name,
    required this.symbol,
    required this.decimals,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'symbol': symbol,
        'decimals': decimals,
      };

  factory NativeCurrency.fromJson(Map<String, dynamic> json) {
    return NativeCurrency(
      name: json['name'],
      symbol: json['symbol'],
      decimals: json['decimals'],
    );
  }
}
