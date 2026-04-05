import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textCol;

    switch (status.toUpperCase()) {
      case 'FULFILLED':
        bg = AppTheme.fulfilledBg;
        textCol = AppTheme.fulfilledText;
        break;
      case 'ACCEPTED':
        bg = AppTheme.acceptedBg;
        textCol = AppTheme.acceptedText;
        break;
      case 'CANCELLED':
      default:
        bg = AppTheme.cancelledBg;
        textCol = AppTheme.cancelledText;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textCol,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
