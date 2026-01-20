import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import 'scale_tap.dart';

class CleanCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;

  const CleanCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: AppColors.surfaceDay,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: AppColors.borderDay,
        width: 1.5,
      ),
      // No shadow as per design principles
    );

    if (onTap != null) {
      return ScaleTap(
        onPressed: onTap,
        child: Container(
          decoration: decoration,
          padding: padding,
          child: child,
        ),
      );
    }

    return Container(
      decoration: decoration,
      padding: padding,
      child: child,
    );
  }
}
