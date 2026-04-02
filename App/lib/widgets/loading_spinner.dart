import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class LoadingSpinner extends StatelessWidget {
  final String? text;

  const LoadingSpinner({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
          ),
          if (text != null) ...[
            const SizedBox(height: 16),
            Text(
              text!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
