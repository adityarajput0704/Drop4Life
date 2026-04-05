import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class BloodBadge extends StatelessWidget {
  final String bloodGroup;
  final double size;
  final double fontSize;

  const BloodBadge({
    super.key,
    required this.bloodGroup,
    this.size = 40,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.primaryRed,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        bloodGroup,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
