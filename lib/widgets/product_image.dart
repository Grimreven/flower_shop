import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class ProductImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
  });

  bool get _isNetworkImage {
    final String value = imageUrl.trim().toLowerCase();
    return value.startsWith('http://') || value.startsWith('https://');
  }

  bool get _isAssetImage {
    final String value = imageUrl.trim().toLowerCase();
    return value.startsWith('assets/');
  }

  Widget _fallback(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      color: backgroundColor ??
          (isDark ? AppColors.darkSurfaceElevated : AppColors.primaryLight),
      child: Icon(
        Icons.local_florist_rounded,
        size: 52,
        color: isDark ? AppColors.purpleLight : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String path = imageUrl.trim();

    Widget child;

    if (path.isEmpty) {
      child = _fallback(context);
    } else if (_isAssetImage) {
      child = Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    } else if (_isNetworkImage) {
      child = Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    } else {
      child = Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }

    if (borderRadius == null) {
      return child;
    }

    return ClipRRect(
      borderRadius: borderRadius!,
      child: child,
    );
  }
}