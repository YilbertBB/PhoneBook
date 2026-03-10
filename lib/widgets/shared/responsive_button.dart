import 'package:flutter/material.dart';

import '../../utils/responsive_utils.dart';
import 'responsive_text.dart';

class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const ResponsiveButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: 50,
      tablet: 55,
      desktop: 60,
    );

    final fontSize = ResponsiveUtils.getResponsiveTextSize(context, 16);

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: textColor),
                  SizedBox(width: 8),
                  ResponsiveText(
                    text: text,
                    size: fontSize,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              )
            : ResponsiveText(
                text: text,
                size: fontSize,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
      ),
    );
  }
}
