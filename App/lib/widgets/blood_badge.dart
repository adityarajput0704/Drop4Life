import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class BloodBadge extends StatelessWidget {
  final String bloodGroup;
  final double size;
  final double fontSize;

  const BloodBadge({
    super.key,
    required this.bloodGroup,
    this.size = 48.0,
    this.fontSize = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(12),
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
