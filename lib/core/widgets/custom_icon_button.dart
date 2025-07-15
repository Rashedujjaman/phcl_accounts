import 'package:flutter/material.dart';

class CustomIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final double borderWidth;
  final double elevation;
  final EdgeInsetsGeometry padding;
  final double? iconSize;
  final double size;

  const CustomIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 8.0,
    this.borderWidth = 1.0,
    this.elevation = 0.0,
    this.padding = EdgeInsets.zero,
    this.iconSize,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(
            width: borderWidth,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        padding: padding,
        elevation: elevation,
        minimumSize: Size.square(size),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}