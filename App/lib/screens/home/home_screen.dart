import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/donor_provider.dart';
import '../../providers/request_provider.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/request_card.dart';
import '../../widgets/loading_spinner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DonorProvider>().fetchMyProfile();
      context.read<RequestProvider>().fetchUrgentRequests();
      // Start WebSocket so new requests appear without manual refresh
      context.read<RequestProvider>().initWebSocket();
    });
  }

  @override
  Widget build(BuildContext context) {
    final donorProvider = context.watch<DonorProvider>();
    final requestProvider = context.watch<RequestProvider>();
    final donor = donorProvider.donor;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppTheme.primaryRed,
              radius: 16,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              donor != null
                  ? 'Hello, ${donor.fullName.split(' ').first} 🌟'
                  : 'Hello 🌟',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: donorProvider.isLoading && donor == null
          ? const LoadingSpinner()
          : RefreshIndicator(
              onRefresh: () async {
                await context.read<DonorProvider>().fetchMyProfile();
                await context.read<RequestProvider>().fetchUrgentRequests();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Blood Group Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Stack(
                        children: [
                          const Positioned(
                            right: -20,
                            top: -20,
                            child: Icon(Icons.water_drop,
                                size: 120, color: Colors.white10),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('YOUR BLOOD GROUP',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                              const SizedBox(height: 8),
                              Text(
                                donor?.bloodGroup ?? '--',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Status Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Status',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const Text('Ready to save a life today?',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                            const SizedBox(height: 8),
                            if (donor != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: donor.isAvailable
                                      ? AppTheme.availableBg
                                      : AppTheme.unavailableBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.circle,
                                        size: 8,
                                        color: donor.isAvailable
                                            ? AppTheme.availableText
                                            : AppTheme.unavailableText),
                                    const SizedBox(width: 6),
                                    Text(
                                      donor.isAvailable
                                          ? 'Available to Donate'
                                          : 'Unavailable',
                                      style: TextStyle(
                                        color: donor.isAvailable
                                            ? AppTheme.availableText
                                            : AppTheme.unavailableText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        Switch(
                          value: donor?.isAvailable ?? false,
                          activeThumbColor: AppTheme.primaryRed,
                          onChanged: (val) {
                            if (donor != null) {
                              context.read<DonorProvider>().updateProfile({
                                'availability': val
                                    ? 'available'
                                    : 'unavailable', // ← correct field
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Stats Row
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('TOTAL',
                              '${donor?.totalDonations ?? 0} Donations'),
                          _buildStatColumn('IMPACT',
                              '${donor?.livesSaved ?? 0} Lives Saved'),
                          _buildStatColumn(
                            'LAST',
                            donor?.lastDonation != null
                                ? '${_month(donor!.lastDonation!.month)} ${donor.lastDonation!.day} ${donor.lastDonation!.year}'
                                : 'Never',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Urgent Requests Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Urgent Requests',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Near ${donor?.city ?? "you"}',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.go('/requests'),
                          child: const Text('View All',
                              style: TextStyle(
                                  color: AppTheme.primaryRed,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Urgent Requests Horizontal List
                    if (requestProvider.urgentRequests.isEmpty)
                      const Center(
                          child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text(
                                  'No urgent requests near you right now.',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary))))
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 600;

                          if (isMobile) {
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: requestProvider.urgentRequests.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final req =
                                    requestProvider.urgentRequests[index];
                                return RequestCard(
                                  request: req,
                                  onTap: () => context
                                      .push('/request/${req.id}', extra: req),
                                  onAccept: () => context
                                      .push('/request/${req.id}', extra: req),
                                );
                              },
                            );
                          } else {
                            return SizedBox(
                              height: 190,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount:
                                    requestProvider.urgentRequests.length,
                                itemBuilder: (context, index) {
                                  final req =
                                      requestProvider.urgentRequests[index];
                                  return SizedBox(
                                    width: 320,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 16),
                                      child: RequestCard(
                                        request: req,
                                        onTap: () => context.push(
                                            '/request/${req.id}',
                                            extra: req),
                                        onAccept: () => context.push(
                                            '/request/${req.id}',
                                            extra: req),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  String _month(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[m - 1];
  }
}
