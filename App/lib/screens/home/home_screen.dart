import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/donor_provider.dart';
import '../../providers/request_provider.dart';
import '../../widgets/blood_badge.dart';
import '../../widgets/request_card.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/bottom_nav.dart';

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
      context.read<DonorProvider>().fetchDonorProfile();
      context.read<RequestProvider>().fetchBloodRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final donorProvider = context.watch<DonorProvider>();
    final requestProvider = context.watch<RequestProvider>();
    final donor = donorProvider.donor;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: donorProvider.isLoading && donor == null
            ? const LoadingSpinner(text: 'Loading profile...')
            : CustomScrollView(
                slivers: [
                  // Top bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hello, ${donor?.name.split(' ').first ?? 'Donor'} 🌟',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Icon(Icons.notifications_none, size: 28),
                        ],
                      ),
                    ),
                  ),

                  // Large red card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Stack(
                          children: [
                            const Positioned(
                              right: -20,
                              bottom: -20,
                              child: Icon(Icons.water_drop, color: Colors.white24, size: 100),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('YOUR BLOOD GROUP', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(
                                  donor?.bloodGroup ?? 'N/A',
                                  style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Status row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  const Text('Ready to save a life today?', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                              Switch(
                                value: donor?.availability ?? false,
                                onChanged: (val) {},
                                activeColor: AppColors.primaryRed,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.statusFulfilledBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.centerLeft,
                            child: const Text('● Available to Donate', style: TextStyle(color: AppColors.statusFulfilledText, fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      ),
                    ),
                  ),

                  // Stats row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn('TOTAL', '12', 'Donations'),
                            _buildStatColumn('IMPACT', '36', 'Lives Saved'),
                            _buildStatColumn('LAST', 'Oct 12', '2023'),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Urgent Requests Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Urgent Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(height: 4),
                              Text('Near ${donor?.city ?? 'you'}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => context.go('/requests'),
                            child: const Text('View All', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: 14)),
                          )
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 180,
                      child: requestProvider.isLoadingRequests && requestProvider.requests.isEmpty
                          ? const LoadingSpinner()
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: requestProvider.requests.length,
                              itemBuilder: (context, index) {
                                final req = requestProvider.requests[index];
                                return Container(
                                  width: 300,
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  child: RequestCard(
                                    request: req,
                                    onTap: () => context.go('/requests/${req.id}'),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),

                  // Two info cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("SAFETY FIRST", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                                  SizedBox(height: 8),
                                  Text("Pre-donation checklist", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(16)),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("DIET TIPS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.pink)),
                                  SizedBox(height: 8),
                                  Text("Iron-rich foods guide", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }

  Widget _buildStatColumn(String label, String value, String sub) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}
