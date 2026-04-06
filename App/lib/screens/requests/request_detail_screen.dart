import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/blood_request.dart';
import '../../providers/request_provider.dart';
import '../../widgets/blood_badge.dart';
import '../../widgets/urgency_badge.dart';

class RequestDetailScreen extends StatelessWidget {
  final BloodRequest request;

  const RequestDetailScreen({super.key, required this.request});

  void _acceptRequest(BuildContext context) async {
    // Guard: don't allow accepting already-accepted or fulfilled requests
    final status = request.status.toUpperCase();
    if (status == 'ACCEPTED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This request has already been accepted.')),
      );
      return;
    }
    if (status == 'FULFILLED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This request has already been fulfilled.')),
      );
      return;
    }
    if (status == 'CANCELLED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This request has been cancelled.')),
      );
      return;
    }

    final success = await context.read<RequestProvider>().acceptRequest(request.id);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request Accepted! Please proceed to the hospital.')),
      );
      context.pop();
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to accept request. Please try again.')),
      );
    }
  }

  // Returns true if this request can still be accepted
  bool get _canAccept {
    final status = request.status.toUpperCase();
    return status == 'PENDING';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Request Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: AppTheme.primaryRed,
              radius: 14,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BloodBadge(bloodGroup: request.bloodGroup, size: 80, fontSize: 32),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                UrgencyBadge(urgency: request.urgency),
                const SizedBox(width: 8),
                // Fixed: id is now "3" not "req_abc" — just show as #3
                Text(
                  'Ref: #${request.id}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${request.unitsNeeded} Units Needed',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              request.hospitalName,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 32),

            _buildSectionCard(
              icon: Icons.person,
              label: 'PATIENT',
              title: request.patientName,
              subtitle: request.caseDescription.isNotEmpty
                  ? request.caseDescription
                  : 'No description provided.',
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              icon: Icons.local_hospital,
              label: 'FACILITY',
              title: request.hospitalName,
              subtitle: request.city,
            ),
            const SizedBox(height: 16),

            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: AppTheme.textSecondary),
                    SizedBox(height: 8),
                    Text(
                      'Map View Placeholder',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone, color: AppTheme.primaryRed),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      request.contactNumber.isNotEmpty
                          ? request.contactNumber
                          : 'Not provided',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: const Text('Directions'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceCard,
                border: Border(left: BorderSide(color: AppTheme.primaryRed, width: 4)),
              ),
              child: const Text(
                '"Please arrive at the emergency reception and mention the reference number. Ensure you have eaten and are well hydrated."',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Accept button — greyed out if request is not PENDING
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canAccept ? () => _acceptRequest(context) : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  // Visual indicator when disabled
                  disabledBackgroundColor: AppTheme.surfaceCard,
                ),
                child: Text(
                  _canAccept
                      ? '🤝 Accept This Request'
                      : '✅ ${request.status[0]}${request.status.substring(1).toLowerCase()}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _canAccept
                  ? 'By accepting, you commit to arriving within 4 hours.'
                  : 'This request is no longer available for acceptance.',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String label,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryRed, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}