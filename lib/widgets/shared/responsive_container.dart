// responsive_container.dart - versión corregida
import 'package:flutter/material.dart';
import '../../utils/responsive_utils.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final bool enableScrolling;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.enableScrolling = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
      child: child,
    );

    return enableScrolling ? SingleChildScrollView(child: content) : content;
  }
}
