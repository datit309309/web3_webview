// lib/ethereum/models/eip6963_provider_info.dart
class EIP6963ProviderInfo {
  final String uuid;
  final String name;
  final String icon;
  final String rdns;

  EIP6963ProviderInfo({
    required this.uuid,
    required this.name,
    required this.icon,
    required this.rdns,
  });

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'name': name,
        'icon': icon,
        'rdns': rdns,
      };

  factory EIP6963ProviderInfo.fromJson(Map<String, dynamic> json) {
    return EIP6963ProviderInfo(
      uuid: json['uuid'],
      name: json['name'],
      icon: json['icon'],
      rdns: json['rdns'],
    );
  }
}
