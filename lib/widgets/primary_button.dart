import 'package:flutter/material.dart';

import '../models/button_config.dart';

enum ButtonMode {
  confirm,
  reject,
}

class PrimaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final ButtonMode mode;
  final double? width;
  final double height;
  final ButtonConfig? style;

  // Màu mặc định
  static const defaultConfirmColor = Color(0xFF4CAF50); // Xanh lá
  static const defaultRejectColor = Color(0xFFf44336); // Đỏ
  static const defaultTextColor = Colors.white;
  static const defaultBorderColor = Colors.transparent;
  static const defaultBorderWidth = 0.0;
  static const defaultBorderRadius = 10.0;
  static const defaultPadding = EdgeInsets.all(10);

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.mode = ButtonMode.confirm,
    this.width,
    this.height = 45,
    this.style,
  });

  ButtonConfig _getConfigForMode(ButtonMode mode) {
    switch (mode) {
      case ButtonMode.confirm:
        return ButtonConfig(
          backgroundColor: style?.backgroundColor ?? defaultConfirmColor,
          textColor: style?.textColor ?? defaultTextColor,
          borderRadius: style?.borderRadius ?? 10.0,
          padding: style?.padding ?? const EdgeInsets.all(10),
          fontSize: style?.fontSize ?? 16.0,
          borderColor: style?.borderColor,
          borderWidth: style?.borderWidth,
        );

      case ButtonMode.reject:
        return ButtonConfig(
          backgroundColor: style?.backgroundColor ?? defaultRejectColor,
          textColor: style?.textColor ?? defaultTextColor,
          borderRadius: style?.borderRadius ?? 10.0,
          padding: style?.padding ?? const EdgeInsets.all(10),
          fontSize: style?.fontSize ?? 16.0,
          borderColor: style?.borderColor,
          borderWidth: style?.borderWidth,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _getConfigForMode(mode);

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius:
              BorderRadius.circular(config.borderRadius ?? defaultBorderRadius),
          child: Ink(
            decoration: BoxDecoration(
              color: config.backgroundColor,
              borderRadius: BorderRadius.circular(
                  config.borderRadius ?? defaultBorderRadius),
            ),
            child: Padding(
              padding: config.padding ?? defaultPadding,
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    color: config.textColor,
                    fontSize: config.fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
