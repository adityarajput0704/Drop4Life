import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/donor_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/blood_badge.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final donor = context.read<DonorProvider>().donor;
      if (donor != null) {
        _nameController.text = donor.fullName;
        _cityController.text = donor.city;
        _ageController.text = donor.age.toString();
      }
    });
  }

  void _saveChanges() async {
    final success = await context.read<DonorProvider>().updateProfile({
      'full_name': _nameController.text,
      'city': _cityController.text,
      'age': int.tryParse(_ageController.text) ?? 0,
    });
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile Updated Successfully!')),
      );
    }
  }

  void _logout() async {
    await context.read<AuthProvider>().logout();
    context.read<DonorProvider>().clearProfile();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final donorProvider = context.watch<DonorProvider>();
    final donor = donorProvider.donor;

    if (donorProvider.isLoading && donor == null) {
      return const Scaffold(
        body: LoadingSpinner(),
        bottomNavigationBar: BottomNav(currentIndex: 3),
      );
    }

    if (donor == null) {
      return const Scaffold(
        body: Center(child: Text("Couldn't load profile")),
        bottomNavigationBar: BottomNav(currentIndex: 3),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Top Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryRed,
                    child: Text(
                      donor.fullName.isNotEmpty ? donor.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: BloodBadge(bloodGroup: donor.bloodGroup, size: 30, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(donor.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(donor.email, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 32),

            // Donation Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: const Border(left: BorderSide(color: AppTheme.availableText, width: 4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.availableText),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Donation Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('You are available to donate', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.availableBg, borderRadius: BorderRadius.circular(12)),
                    child: const Text('ACTIVE', style: TextStyle(color: AppTheme.availableText, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Edit Profile Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Icon(Icons.edit, color: AppTheme.textSecondary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildLabel('FULL NAME'),
                  TextField(controller: _nameController, decoration: const InputDecoration(filled: true, fillColor: Colors.white)),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('CITY'),
                            TextField(controller: _cityController, decoration: const InputDecoration(filled: true, fillColor: Colors.white)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('AGE'),
                            TextField(controller: _ageController, keyboardType: TextInputType.number, decoration: const InputDecoration(filled: true, fillColor: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Emergency Availability', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Allow urgent blood requests', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                      Switch(
                        value: donor.isAvailable,
                        activeThumbColor: AppTheme.primaryRed,
                        onChanged: (val) {
                          context.read<DonorProvider>().updateProfile({'is_available': val});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: donorProvider.isLoading ? null : _saveChanges,
                      child: donorProvider.isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: AppTheme.primaryRed),
                label: const Text('Logout', style: TextStyle(color: AppTheme.primaryRed)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.primaryRed),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
    );
  }
}
