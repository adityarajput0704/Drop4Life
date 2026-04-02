import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/blood_request.dart';
import '../../providers/request_provider.dart';
import '../../widgets/blood_badge.dart';
import '../../widgets/urgency_badge.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/bottom_nav.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  BloodRequest? request;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final provider = context.read<RequestProvider>();
    if (provider.requests.isEmpty) {
      await provider.fetchBloodRequests();
    }
    setState(() {
      request = provider.requests.firstWhere((r) => r.id == widget.requestId, orElse: () => provider.requests.first);
      isLoading = false;
    });
  }

  void _accept() async {
    final success = await context.read<RequestProvider>().acceptRequest(widget.requestId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request Accepted!')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: LoadingSpinner(text: 'Loading details...'));
    if (request == null) return const Scaffold(body: Center(child: Text('Request not found')));

    final req = request!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Request Details'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: const [
          Icon(Icons.notifications_none),
          SizedBox(width: 16),
          CircleAvatar(backgroundColor: AppColors.border, radius: 16, child: Icon(Icons.person, size: 20, color: AppColors.textSecondary)),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BloodBadge(bloodGroup: req.bloodGroup, size: 80, fontSize: 32),
            const SizedBox(height: 16),
            UrgencyBadge(urgency: req.urgency),
            const SizedBox(height: 8),
            Text('REF: ${req.id.toUpperCase()}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Text('${req.units} Units Needed', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(req.hospitalName, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            const SizedBox(height: 32),

            // Patient Card
            _buildSectionCard(Icons.person, 'PATIENT', req.patientName, req.caseDescription),
            const SizedBox(height: 16),

            // Facility Card
            _buildSectionCard(Icons.local_hospital, 'FACILITY', req.hospitalName, req.address),
            const SizedBox(height: 24),

            // Map Placeholder
            Container(height: 150, width: double.infinity, decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16)), alignment: Alignment.center, child: const Icon(Icons.location_on, size: 48, color: AppColors.primaryRed)),
            const SizedBox(height: 16),

            // Phone Row
            Row(
              children: [
                Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: AppColors.surfaceCard, shape: BoxShape.circle), child: const Icon(Icons.phone, color: AppColors.textPrimary)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DIRECT LINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    Text(req.phone, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
                const Spacer(),
                ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppColors.textPrimary), child: const Text('Directions', style: TextStyle(color: Colors.white))),
              ],
            ),
            const SizedBox(height: 32),

            // Donor Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: AppColors.surfaceCard, border: Border(left: BorderSide(color: AppColors.primaryRed, width: 4))),
              child: const Text('Please arrive well hydrated and carry a valid ID. Fasting is not required.', style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 32),

            // Bottom Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _accept,
                icon: const Icon(Icons.favorite, color: Colors.white),
                label: const Text('Accept This Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ),
            const SizedBox(height: 16),
            const Text('By accepting, you commit to arriving within 2 hours.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
    );
  }

  Widget _buildSectionCard(IconData icon, String label, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: AppColors.primaryRed)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
