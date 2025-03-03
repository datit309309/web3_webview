import '../json_rpc_method.dart';
import '../ethereum/wallet_dialog_service.dart';
import 'network_config.dart';

class Web3WalletConfig {
  final String? privateKey;
  final String? name;
  final String? icon;
  final String? id;
  final NetworkConfig? currentNetwork;
  final List<NetworkConfig>? supportNetworks;
  final bool? isDebug;
  final WalletDialogTheme? dialogTheme;
  final Function(JsonRpcMethod method, List<dynamic>? params, String message)?
      onError;

  Web3WalletConfig({
    this.privateKey,
    this.name,
    this.icon,
    this.id,
    this.currentNetwork,
    this.supportNetworks,
    this.isDebug,
    this.dialogTheme,
    this.onError,
  });
}
