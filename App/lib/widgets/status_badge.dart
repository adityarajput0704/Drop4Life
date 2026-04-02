import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status.toUpperCase()) {
      case 'FULFILLED':
        bgColor = AppColors.statusFulfilledBg;
        textColor = AppColors.statusFulfilledText;
        break;
      case 'ACCEPTED':
        bgColor = AppColors.statusAcceptedBg;
        textColor = AppColors.statusAcceptedText;
        break;
      case 'CANCELLED':
      default:
        bgColor = AppColors.statusCancelledBg;
        textColor = AppColors.statusCancelledText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
