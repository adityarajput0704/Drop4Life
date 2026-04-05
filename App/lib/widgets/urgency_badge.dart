import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class UrgencyBadge extends StatelessWidget {
  final String urgency;

  const UrgencyBadge({super.key, required this.urgency});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textCol;

    switch (urgency.toUpperCase()) {
      case 'CRITICAL':
        bg = AppTheme.criticalBg;
        textCol = AppTheme.criticalText;
        break;
      case 'HIGH':
        bg = AppTheme.highBg;
        textCol = AppTheme.highText;
        break;
      case 'MEDIUM':
        bg = AppTheme.mediumBg;
        textCol = AppTheme.mediumText;
        break;
      case 'LOW':
      default:
        bg = AppTheme.lowBg;
        textCol = AppTheme.lowText;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        urgency.toUpperCase(),
        style: TextStyle(
          color: textCol,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
