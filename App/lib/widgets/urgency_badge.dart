import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class UrgencyBadge extends StatelessWidget {
  final String urgency;

  const UrgencyBadge({super.key, required this.urgency});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (urgency.toUpperCase()) {
      case 'CRITICAL':
        bgColor = AppColors.urgencyCriticalBg;
        textColor = AppColors.urgencyCriticalText;
        break;
      case 'HIGH':
        bgColor = AppColors.urgencyHighBg;
        textColor = AppColors.urgencyHighText;
        break;
      case 'MEDIUM':
        bgColor = AppColors.urgencyMediumBg;
        textColor = AppColors.urgencyMediumText;
        break;
      case 'LOW':
        bgColor = AppColors.urgencyLowBg;
        textColor = AppColors.urgencyLowText;
        break;
      default:
        bgColor = AppColors.border;
        textColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        urgency.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
