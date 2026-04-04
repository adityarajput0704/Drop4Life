import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../providers/request_provider.dart';
import '../../widgets/blood_badge.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/bottom_nav.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RequestProvider>().fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RequestProvider>();
    final history = provider.history;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: const [
          Icon(Icons.notifications_none),
          SizedBox(width: 16),
          CircleAvatar(backgroundColor: AppColors.border, radius: 16, child: Icon(Icons.person, size: 20, color: AppColors.textSecondary)),
          SizedBox(width: 16),
        ],
        automaticallyImplyLeading: false,
      ),
      body: provider.isLoadingHistory && history.isEmpty
          ? const LoadingSpinner(text: 'Loading history...')
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Impact Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Stack(
                            children: [
                              const Positioned(
                                right: -20,
                                bottom: -20,
                                child: Icon(Icons.favorite, color: Colors.black12, size: 100),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('TOTAL IMPACT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                  const SizedBox(height: 8),
                                  const Text('3.5 Liters', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primaryRed)),
                                  const SizedBox(height: 8),
                                  const Text('You have saved approximately 10 lives through your donations.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Achievement Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: const Color(0xFF8B0000), borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.star, color: Colors.yellow, size: 24)),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Silver Donor', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  const Text('2 MORE TO GOLD', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(12)),
                          child: const Text('ALL TIME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  ),
                ),

                // Updated history.isNotEmpty condition check
                history.isEmpty 
                  ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text("No history available"))))
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = history[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.hospitalName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(DateFormat('MMM dd yyyy').format(item.date), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                          const SizedBox(width: 16),
                                          StatusBadge(status: item.status),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      GestureDetector(
                                        onTap: () {},
                                        child: const Text('View Receipt ›', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: 12)),
                                      )
                                    ],
                                  ),
                                ),
                                BloodBadge(bloodGroup: item.bloodGroup, size: 48, fontSize: 16),
                              ],
                            ),
                          );
                        },
                        childCount: history.length,
                      ),
                    ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }
}
