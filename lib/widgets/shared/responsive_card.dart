// widgets/responsive_card.dart
import 'package:flutter/material.dart';

import '../../utils/responsive_utils.dart';

class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? elevation;
  final Color? color;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.elevation,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cardPadding =
        padding ?? ResponsiveUtils.getResponsivePadding(context);

    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),

        onTap: onTap,
        child: Padding(padding: cardPadding, child: child),
      ),
    );
  }
}
