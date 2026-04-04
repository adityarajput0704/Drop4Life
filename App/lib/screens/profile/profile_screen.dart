import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/donor_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/blood_badge.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/bottom_nav.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DonorProvider>().fetchDonorProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DonorProvider>();
    final donor = provider.donor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const [
          Icon(Icons.notifications_none),
          SizedBox(width: 16),
        ],
        automaticallyImplyLeading: false,
      ),
      body: provider.isLoading && donor == null
          ? const LoadingSpinner(text: 'Loading profile...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Avatar row
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primaryRed,
                          child: Text(
                            donor?.name.substring(0, 2).toUpperCase() ?? 'NA',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: BloodBadge(bloodGroup: donor?.bloodGroup ?? 'O+', size: 32, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(donor?.name ?? 'Unknown', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(donor?.email ?? '---', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 32),

                  // Donation Status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: const Border(left: BorderSide(color: AppColors.statusFulfilledText, width: 4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.statusFulfilledText),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Donation Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                const Text('You are available to donate', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.statusFulfilledBg, borderRadius: BorderRadius.circular(12)),
                          child: const Text('ACTIVE', style: TextStyle(color: AppColors.statusFulfilledText, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Edit Profile
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const Icon(Icons.edit, size: 20, color: AppColors.primaryRed),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildReadonlyField('FULL NAME', donor?.name ?? ''),
                        Row(
                          children: [
                            Expanded(child: _buildReadonlyField('CITY', donor?.city ?? '')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildReadonlyField('AGE', donor?.age.toString() ?? '')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Emergency Availability', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                SizedBox(height: 4),
                                Text('Allow urgent blood requests', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                            Switch(
                              value: donor?.availability ?? false,
                              onChanged: (val) {},
                              activeThumbColor: AppColors.primaryRed,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                      icon: const Icon(Icons.logout, color: AppColors.primaryRed),
                      label: const Text('Logout', style: TextStyle(color: AppColors.primaryRed, fontSize: 16, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryRed),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: const BottomNav(currentIndex: 3),
    );
  }

  Widget _buildReadonlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: value,
            readOnly: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
