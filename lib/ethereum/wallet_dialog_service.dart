import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../utils/app_utils.dart';
import '../widgets/bottom_sheet_dialog.dart';
import '../models/button_config.dart';
import '../models/models.dart';
import '../widgets/primary_button.dart';

class WalletDialogTheme {
  final Color textColor;
  final Color borderColor;
  final Color backgroundColor;
  final Color gradientColor;
  final Color primaryColor;
  final TextStyle headerStyle;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final ButtonConfig buttonConfirmStyle;
  final ButtonConfig buttonRejectStyle;
  final EdgeInsets dialogPadding;
  final EdgeInsets contentPadding;
  final double itemSpacing;

  WalletDialogTheme({
    this.textColor = const Color(0xFF1F2937),
    this.borderColor = const Color(0xFFE5E7EB),
    this.backgroundColor = Colors.white,
    this.gradientColor = const Color(0xFFE0E0E0),
    this.primaryColor = const Color(0xFF2196F3),
    this.headerStyle = const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1F2937),
    ),
    this.labelStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      color: Color(0xFF1F2937),
    ),
    this.valueStyle = const TextStyle(
      color: Color(0xFF1F2937),
    ),
    ButtonConfig? buttonConfirmStyle,
    ButtonConfig? buttonRejectStyle,
    this.dialogPadding = const EdgeInsets.all(20.0),
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 20.0),
    this.itemSpacing = 10.0,
  })  : buttonConfirmStyle = buttonConfirmStyle ?? const ButtonConfig(),
        buttonRejectStyle = buttonRejectStyle ?? const ButtonConfig();

  WalletDialogTheme copyWith({
    Color? textColor,
    Color? borderColor,
    Color? backgroundColor,
    Color? gradientColor,
    Color? primaryColor,
    TextStyle? headerStyle,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
    ButtonConfig? buttonConfirmStyle,
    ButtonConfig? buttonRejectStyle,
    EdgeInsets? dialogPadding,
    EdgeInsets? contentPadding,
    double? itemSpacing,
  }) {
    return WalletDialogTheme(
      textColor: textColor ?? this.textColor,
      borderColor: borderColor ?? this.borderColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gradientColor: gradientColor ?? this.gradientColor,
      primaryColor: primaryColor ?? this.primaryColor,
      headerStyle: headerStyle ?? this.headerStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      valueStyle: valueStyle ?? this.valueStyle,
      buttonConfirmStyle: buttonConfirmStyle ?? this.buttonConfirmStyle,
      buttonRejectStyle: buttonRejectStyle ?? this.buttonRejectStyle,
      dialogPadding: dialogPadding ?? this.dialogPadding,
      contentPadding: contentPadding ?? this.contentPadding,
      itemSpacing: itemSpacing ?? this.itemSpacing,
    );
  }
}

class WalletDialogService {
  // Singleton pattern
  WalletDialogService._();
  static final WalletDialogService instance = WalletDialogService._();

  // Theme instance
  WalletDialogTheme _theme = WalletDialogTheme();

  // Getter for current theme
  WalletDialogTheme get theme => _theme;

  // Configure theme method
  void configureTheme(WalletDialogTheme theme) {
    _theme = theme;
  }

  Widget _buildDialogHeader(String title) {
    return Text(
      title,
      style: _theme.headerStyle,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text("$label: ", style: _theme.labelStyle),
        Text(value, style: _theme.valueStyle),
      ],
    );
  }

  Widget _buildActionButtons({
    required BuildContext context,
    required String cancelText,
    required String confirmText,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        PrimaryButton(
          onPressed: () async => Navigator.pop(context, false),
          text: cancelText,
          mode: ButtonMode.reject,
          style: _theme.buttonRejectStyle,
        ),
        PrimaryButton(
          onPressed: () async => Navigator.pop(context, true),
          text: confirmText,
          mode: ButtonMode.confirm,
          style: _theme.buttonConfirmStyle,
        ),
      ],
    );
  }

  Widget _buildContainer({
    required Widget child,
    Color? backgroundColor,
    EdgeInsets? padding,
  }) {
    return Container(
      padding: padding ?? _theme.dialogPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? _theme.gradientColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }

  Future<bool?> showConnectWallet(
    BuildContext context, {
    required String address,
    required InAppWebViewController ctrl,
    required String appName,
  }) async {
    final requestFrom = (await ctrl.getUrl())?.host ?? '';

    return await _showDialog(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: _theme.contentPadding,
        children: [
          _buildDialogHeader('$appName request to connect to your wallet?'),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Request from', requestFrom),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Address', address.ellipsisMidWalletAddress()),
          Divider(color: _theme.borderColor),
          _buildPermissionsSection(),
          SizedBox(height: _theme.itemSpacing * 2),
          _buildActionButtons(
            context: context,
            cancelText: 'Reject',
            confirmText: 'Connect',
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return Column(
      children: [
        Text('Permission', style: _theme.headerStyle.copyWith(fontSize: 16)),
        SizedBox(height: _theme.itemSpacing),
        Text(
          'Do you want this site to do the following?',
          style: _theme.valueStyle,
        ),
        SizedBox(height: _theme.itemSpacing),
        _buildContainer(
          child: Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                  'See address, account balance, activity and suggest transactions to approve',
                  style: _theme.valueStyle)
            ],
          ),
        ),
        SizedBox(height: _theme.itemSpacing),
        Text(
          'Only connect with sites you trust.',
          textAlign: TextAlign.center,
          style: _theme.valueStyle,
        ),
      ],
    );
  }

  Future _showDialog({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
  }) {
    return BottomSheetDialog.instance.showView(
      context: context,
      useRootNavigator: true,
      backgroundColor: _theme.backgroundColor,
      child: Container(
        padding: _theme.dialogPadding,
        child: builder(context),
      ),
    );
  }

  Future<bool?> showSignMessage(
    BuildContext context, {
    required String message,
    required String address,
    required InAppWebViewController ctrl,
  }) async {
    final requestFrom = (await ctrl.getUrl())?.host ?? '';

    return await _showDialog(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: _theme.contentPadding,
        children: [
          _buildDialogHeader('Sign Message'),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Request from', requestFrom),
          Divider(color: _theme.borderColor),
          Text('Message to sign:', style: _theme.valueStyle),
          SizedBox(height: _theme.itemSpacing),
          GestureDetector(
            onTap: () => AppUtils.copyToClipboard(message),
            child: _buildContainer(
              child: Text(message, style: _theme.valueStyle),
            ),
          ),
          SizedBox(height: _theme.itemSpacing * 2),
          _buildActionButtons(
            context: context,
            cancelText: 'Reject',
            confirmText: 'Sign',
          ),
        ],
      ),
    );
  }

  Future<bool?> showTransactionConfirm(
    BuildContext context, {
    required Map<String, dynamic> txParams,
    required InAppWebViewController ctrl,
  }) async {
    final requestFrom = (await ctrl.getUrl())?.host ?? '';
    final String from = txParams['from'] ?? '';
    final String to = txParams['to'] ?? '';
    final value = txParams['value'];
    final data = txParams['data'];
    final gas = txParams['gas'];

    return await _showDialog(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: _theme.contentPadding,
        children: [
          _buildDialogHeader('Transaction Request'),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Request from', requestFrom),
          Divider(color: _theme.borderColor),
          _buildInfoRow('From', from.ellipsisMidWalletAddress()),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('To', to.ellipsisMidWalletAddress()),
          SizedBox(height: _theme.itemSpacing),
          Text('Details', style: _theme.valueStyle),
          SizedBox(height: _theme.itemSpacing),
          if (gas != null)
            _buildContainer(
              child: _buildInfoRow(
                'Estimated Fee',
                AppUtils.formatCoin(
                  BigInt.parse(gas).parseGwei(),
                  symbol: "Gwei",
                  decimalDigits: 9,
                ),
              ),
            ),
          if (value != null) ...[
            SizedBox(height: _theme.itemSpacing),
            _buildContainer(
              child: _buildInfoRow(
                'Value',
                AppUtils.formatCoin(
                  BigInt.parse(value).parseGwei(),
                  symbol: "",
                  decimalDigits: 9,
                ),
              ),
            ),
          ],
          if (data != null) ...[
            SizedBox(height: _theme.itemSpacing),
            Text(
              'Hex Data',
              style: _theme.valueStyle,
            ),
            SizedBox(height: _theme.itemSpacing),
            _buildContainer(
              child: Text(data.toString(), style: _theme.valueStyle),
            ),
          ],
          SizedBox(height: _theme.itemSpacing * 2),
          _buildActionButtons(
            context: context,
            cancelText: 'Reject',
            confirmText: 'Confirm',
          ),
        ],
      ),
    );
  }

  Future<bool?> showSwitchNetwork(
    BuildContext context, {
    required NetworkConfig chain,
  }) async {
    return await _showDialog(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: _theme.contentPadding,
        children: [
          _buildDialogHeader('Switch Network?'),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Chain ID', chain.chainId.toString()),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Chain Name', chain.chainName),
          if (chain.nativeCurrency?.symbol != null) ...[
            SizedBox(height: _theme.itemSpacing),
            _buildInfoRow('Currency', chain.nativeCurrency!.symbol),
          ],
          if (chain.nativeCurrency?.decimals != null) ...[
            SizedBox(height: _theme.itemSpacing),
            _buildInfoRow(
                'Decimals', chain.nativeCurrency!.decimals.toString()),
          ],
          SizedBox(height: _theme.itemSpacing * 2),
          _buildActionButtons(
            context: context,
            cancelText: 'Cancel',
            confirmText: 'Confirm',
          ),
        ],
      ),
    );
  }

  Future<bool?> showAddNetwork(
    BuildContext context, {
    required NetworkConfig network,
  }) async {
    return await _showDialog(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: _theme.contentPadding,
        children: [
          _buildDialogHeader('Add Network?'),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Chain ID', network.chainId.toString()),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Chain Name', network.chainName),
          if (network.nativeCurrency?.symbol != null) ...[
            SizedBox(height: _theme.itemSpacing),
            _buildInfoRow('Currency', network.nativeCurrency!.symbol),
          ],
          if (network.nativeCurrency?.decimals != null) ...[
            SizedBox(height: _theme.itemSpacing),
            _buildInfoRow(
                'Decimals', network.nativeCurrency!.decimals.toString()),
          ],
          SizedBox(height: _theme.itemSpacing * 2),
          _buildActionButtons(
            context: context,
            cancelText: 'Cancel',
            confirmText: 'Confirm',
          ),
        ],
      ),
    );
  }
}
