import 'package:flutter/material.dart';

/// App Logo Widget - Tái sử dụng logo ứng dụng
class AppLogo extends StatelessWidget {
  final double size;
  final BoxFit fit;
  final Color? backgroundColor;
  final double? padding;
  final BorderRadius? borderRadius;

  const AppLogo({
    super.key,
    this.size = 80,
    this.fit = BoxFit.contain,
    this.backgroundColor,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget logo = Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: fit,
    );

    if (padding != null) {
      logo = Padding(padding: EdgeInsets.all(padding!), child: logo);
    }

    if (backgroundColor != null || borderRadius != null) {
      logo = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        ),
        child: logo,
      );
    }

    return logo;
  }
}
