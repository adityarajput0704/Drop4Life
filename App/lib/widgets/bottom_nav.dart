import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_colors.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;

  const BottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primaryRed,
      unselectedItemColor: AppColors.textSecondary,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      onTap: (i) {
        if (i == currentIndex) return;
        if (i == 0) context.go('/home');
        if (i == 1) context.go('/requests');
        if (i == 2) context.go('/history');
        if (i == 3) context.go('/profile');
      },
      items: [
        BottomNavigationBarItem(icon: _buildIcon(Icons.home, currentIndex == 0), label: 'Home'),
        BottomNavigationBarItem(icon: _buildIcon(Icons.list_alt, currentIndex == 1), label: 'Requests'),
        BottomNavigationBarItem(icon: _buildIcon(Icons.history, currentIndex == 2), label: 'History'),
        BottomNavigationBarItem(icon: _buildIcon(Icons.person, currentIndex == 3), label: 'Profile'),
      ],
    );
  }

  Widget _buildIcon(IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: isActive ? const BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle) : null,
      child: Icon(icon, color: isActive ? Colors.white : AppColors.textSecondary),
    );
  }
}
