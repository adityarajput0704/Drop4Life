import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/request_provider.dart';
import '../../providers/donor_provider.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/blood_badge.dart';
import '../../widgets/loading_spinner.dart';

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
    final requestProvider = context.watch<RequestProvider>();
    final donorProvider = context.watch<DonorProvider>();
    final donor = donorProvider.donor;

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.water_drop, color: AppTheme.primaryRed),
        title: const Text('Drop4life', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryRed)),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      body: requestProvider.isLoading
          ? const LoadingSpinner()
          : RefreshIndicator(
              onRefresh: () => context.read<RequestProvider>().fetchHistory(),
              color: AppTheme.primaryRed,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Impact Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Stack(
                        children: [
                          const Positioned(
                            right: -10,
                            top: -10,
                            child: Icon(Icons.favorite, size: 100, color: Color(0xFFFEE2E2)),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TOTAL IMPACT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                              const SizedBox(height: 8),
                              Text('${(donor?.livesSaved ?? 0) * 0.5} Liters', style: const TextStyle(color: AppTheme.primaryRed, fontSize: 36, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(
                                'You have saved approximately ${donor?.livesSaved ?? 0} lives through your donations.',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Achievement Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.star, color: Colors.white, size: 32),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Silver Donor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                              Text('3 MORE TO GOLD', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        FilterChip(
                          label: const Text('ALL TIME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          onSelected: (val) {},
                          backgroundColor: AppTheme.surfaceCard,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // List
                    if (requestProvider.history.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('No donation history found.', style: TextStyle(color: AppTheme.textSecondary))))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: requestProvider.history.length,
                        itemBuilder: (context, index) {
                          final h = requestProvider.history[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            StatusBadge(status: h.status),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(h.hospitalName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 12, color: AppTheme.textSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${_month(h.createdAt.month)} ${h.createdAt.day}, ${h.createdAt.year}',
                                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        if (h.status.toUpperCase() == 'CANCELLED' && h.cancellationReason != null) ...[
                                          const SizedBox(height: 8),
                                          Text(h.cancellationReason!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
                                        ],
                                        const SizedBox(height: 16),
                                        TextButton(
                                          onPressed: () {},
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(50, 20),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Text(
                                            h.status.toUpperCase() == 'FULFILLED' ? 'View Receipt ›' : 'View Details ›',
                                            style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  BloodBadge(bloodGroup: h.bloodGroup, size: 40, fontSize: 14),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }

  String _month(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }
}
