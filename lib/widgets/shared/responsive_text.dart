// widgets/responsive_text.dart
import 'package:flutter/material.dart';

import '../../utils/responsive_utils.dart';

class ResponsiveText extends StatelessWidget {
  final String text;
  final double size;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;

  const ResponsiveText({
    super.key,
    required this.text,
    required this.size,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        fontSize: ResponsiveUtils.getResponsiveTextSize(context, size),
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}
