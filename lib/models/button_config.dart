import 'package:flutter/material.dart';

class ButtonConfig {
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? borderWidth;
  final Color? borderColor;

  const ButtonConfig({
    this.backgroundColor,
    this.textColor,
    this.fontSize = 16,
    this.borderRadius = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.borderWidth,
    this.borderColor,
  });

  ButtonConfig copyWith({
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,
    bool? enableGradient,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
    Widget? icon,
    Widget? suffixIcon,
    double? borderWidth,
    Color? borderColor,
    List<Color>? gradientColors,
    Gradient? customGradient,
  }) {
    return ButtonConfig(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      fontSize: fontSize ?? this.fontSize,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
    );
  }
}
