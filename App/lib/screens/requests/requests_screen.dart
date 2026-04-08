import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/request_provider.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/request_card.dart';
import '../../widgets/loading_spinner.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final List<String> _filters = ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RequestProvider>().fetchRequests(refresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<RequestProvider>().fetchRequests();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestProvider = context.watch<RequestProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.water_drop, color: AppTheme.primaryRed),
        title: const Text('Drop4life',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: AppTheme.primaryRed)),
        centerTitle: false,
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_none), onPressed: () {}),
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
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by city...',
                prefixIcon:
                    const Icon(Icons.search, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          context.read<RequestProvider>().fetchRequests(
                                refresh: true,
                                filter: context
                                    .read<RequestProvider>()
                                    .currentFilter,
                              );
                        },
                      )
                    : null,
              ),
              onSubmitted: (value) {
                context.read<RequestProvider>().fetchRequests(
                      refresh: true,
                      filter: context.read<RequestProvider>().currentFilter,
                      search: value.trim(),
                    );
              },
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = requestProvider.currentFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      _filters[index] == 'ALL'
                          ? 'All'
                          : _filters[index][0] +
                              _filters[index].substring(1).toLowerCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (val) {
                      context
                          .read<RequestProvider>()
                          .fetchRequests(refresh: true, filter: filter);
                    },
                    backgroundColor: AppTheme.surfaceCard,
                    selectedColor: AppTheme.primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<RequestProvider>().fetchRequests(
                  refresh: true, filter: requestProvider.currentFilter),
              color: AppTheme.primaryRed,
              child: requestProvider.isLoading
                  ? const LoadingSpinner()
                  : requestProvider.requests.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(
                                child: Text('No requests found.',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary))),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16.0),
                          itemCount: requestProvider.requests.length +
                              (requestProvider.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == requestProvider.requests.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation(
                                              AppTheme.primaryRed)),
                                      SizedBox(height: 8),
                                      Text('LOADING MORE REQUESTS',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.textSecondary,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              );
                            }
                            final req = requestProvider.requests[index];
                            return RequestCard(
                              request: req,
                              buttonText: 'Accept',
                              onTap: () => context.push('/request/${req.id}',
                                  extra: req),
                              onAccept: () => context.push('/request/${req.id}',
                                  extra: req),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
    );
  }
}
