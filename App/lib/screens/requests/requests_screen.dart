import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../providers/request_provider.dart';
import '../../widgets/request_card.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/bottom_nav.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Critical', 'High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RequestProvider>().fetchBloodRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RequestProvider>();
    final requests = provider.requests.where((r) {
      if (_selectedFilter == 'All') return true;
      return r.urgency.toUpperCase() == _selectedFilter.toUpperCase();
    }).toList();

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
      body: RefreshIndicator(
        color: AppColors.primaryRed,
        onRefresh: () => provider.fetchBloodRequests(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search hospital or city...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: AppColors.surfaceCard,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _filters.map((filter) {
                  final isActive = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isActive,
                      onSelected: (val) => setState(() => _selectedFilter = filter),
                      selectedColor: AppColors.primaryRed,
                      backgroundColor: AppColors.surfaceCard,
                      labelStyle: TextStyle(color: isActive ? Colors.white : AppColors.textPrimary, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: provider.isLoadingRequests && provider.requests.isEmpty
                  ? const LoadingSpinner(text: 'LOADING MORE REQUESTS')
                  : requests.isEmpty
                      ? const Center(child: Text("No requests found."))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            final req = requests[index];
                            return RequestCard(
                              request: req,
                              onTap: () => context.go('/requests/${req.id}'),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
    );
  }
}
