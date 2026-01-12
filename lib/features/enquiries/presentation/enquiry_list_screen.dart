import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/utils/helpers.dart';
import '../../auth/data/auth_provider.dart';
import '../data/enquiry_provider.dart';
import '../data/enquiry_model.dart';
import 'enquiry_detail_screen.dart';

class EnquiryListScreen extends StatefulWidget {
  const EnquiryListScreen({super.key});

  @override
  State<EnquiryListScreen> createState() => _EnquiryListScreenState();
}

class _EnquiryListScreenState extends State<EnquiryListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EnquiryProvider>().fetchEnquiries();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Enquiry> _filterEnquiries(List<Enquiry> enquiries, int tabIndex) {
    switch (tabIndex) {
      case 0:
        return enquiries; // All
      case 1:
        return enquiries.where((e) => e.status == 'pending').toList();
      case 2:
        return enquiries
            .where((e) => e.status == 'responded' || e.status == 'accepted')
            .toList();
      case 3:
        return enquiries
            .where((e) => e.status == 'completed' || e.status == 'rejected')
            .toList();
      default:
        return enquiries;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVendor = context.watch<AuthProvider>().isVendor;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<EnquiryProvider>(
        builder: (context, provider, _) {
          final allEnquiries = provider.enquiries;
          final pendingCount =
              allEnquiries.where((e) => e.status == 'pending').length;
          final activeCount = allEnquiries
              .where((e) => e.status == 'responded' || e.status == 'accepted')
              .length;
          final closedCount = allEnquiries
              .where((e) => e.status == 'completed' || e.status == 'rejected')
              .length;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(
                  isVendor, allEnquiries.length, pendingCount, provider),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  tabController: _tabController,
                  tabs: [
                    _TabItem(label: 'All', count: allEnquiries.length),
                    _TabItem(label: 'Pending', count: pendingCount),
                    _TabItem(label: 'Active', count: activeCount),
                    _TabItem(label: 'Closed', count: closedCount),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: List.generate(4, (index) {
                return _EnquiryTabContent(
                  enquiries: _filterEnquiries(allEnquiries, index),
                  isLoading: provider.isLoading && provider.enquiries.isEmpty,
                  isVendor: isVendor,
                  onRefresh: () => provider.fetchEnquiries(),
                  emptyMessage: _getEmptyMessage(index, isVendor),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  String _getEmptyMessage(int tabIndex, bool isVendor) {
    switch (tabIndex) {
      case 0:
        return isVendor
            ? 'No enquiries received yet'
            : 'You haven\'t sent any enquiries';
      case 1:
        return 'No pending enquiries';
      case 2:
        return 'No active enquiries';
      case 3:
        return 'No closed enquiries';
      default:
        return 'No enquiries';
    }
  }

  Widget _buildSliverAppBar(
      bool isVendor, int total, int pending, EnquiryProvider provider) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.mail_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isVendor ? 'Customer Enquiries' : 'My Enquiries',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isVendor
                                  ? 'Manage customer requests'
                                  : 'Track your requests',
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.inbox_rounded,
                        label: 'Total',
                        value: total.toString(),
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.pending_actions_rounded,
                        label: 'Pending',
                        value: pending.toString(),
                        highlight: pending > 0,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color:
            highlight ? Colors.white.withAlpha(50) : Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: highlight
            ? Border.all(color: Colors.white.withAlpha(100), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem {
  final String label;
  final int count;

  _TabItem({required this.label, required this.count});
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<_TabItem> tabs;

  _TabBarDelegate({required this.tabController, required this.tabs});

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: tabs.map((tab) {
          return Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tab.label),
                if (tab.count > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tab.count.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => true;
}

class _EnquiryTabContent extends StatelessWidget {
  final List<Enquiry> enquiries;
  final bool isLoading;
  final bool isVendor;
  final Future<void> Function() onRefresh;
  final String emptyMessage;

  const _EnquiryTabContent({
    required this.enquiries,
    required this.isLoading,
    required this.isVendor,
    required this.onRefresh,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LoadingWidget();
    }

    if (enquiries.isEmpty) {
      return _EmptyState(message: emptyMessage, isVendor: isVendor);
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: enquiries.length,
        itemBuilder: (context, index) {
          return _EnquiryCard(
            enquiry: enquiries[index],
            isVendor: isVendor,
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final bool isVendor;

  const _EmptyState({required this.message, required this.isVendor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVendor ? Icons.inbox_rounded : Icons.send_rounded,
                size: 48,
                color: AppColors.primary.withAlpha(150),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isVendor
                  ? 'Customer enquiries will appear here when they reach out'
                  : 'Browse products or services and send enquiries to vendors',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EnquiryCard extends StatelessWidget {
  final Enquiry enquiry;
  final bool isVendor;

  const _EnquiryCard({required this.enquiry, required this.isVendor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EnquiryDetailScreen(enquiryId: enquiry.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    _TypeBadge(type: enquiry.type),
                    const Spacer(),
                    _StatusBadge(status: enquiry.status),
                  ],
                ),
                const SizedBox(height: 14),

                // Item name
                Text(
                  enquiry.itemName ?? 'Unknown Item',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // User/Vendor info row
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isVendor ? Icons.person_rounded : Icons.store_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isVendor
                                ? enquiry.userName ?? 'Customer'
                                : enquiry.vendorName ?? 'Vendor',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (isVendor && enquiry.userPhone != null)
                            Text(
                              enquiry.userPhone!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Message preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        size: 16,
                        color: AppColors.textSecondary.withAlpha(150),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          enquiry.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Footer row
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: AppColors.textSecondary.withAlpha(150),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      Helpers.timeAgo(enquiry.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary.withAlpha(180),
                      ),
                    ),
                    if (enquiry.preferredDate != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: AppColors.textSecondary.withAlpha(150),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        enquiry.preferredDate!,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary.withAlpha(180),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.textSecondary.withAlpha(100),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isProduct = type == 'product';
    final color = isProduct ? const Color(0xFF3B82F6) : const Color(0xFF10B981);
    final icon =
        isProduct ? Icons.inventory_2_rounded : Icons.build_circle_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            type.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case 'pending':
        color = const Color(0xFFF59E0B);
        icon = Icons.schedule_rounded;
        label = 'Pending';
        break;
      case 'responded':
        color = const Color(0xFF3B82F6);
        icon = Icons.reply_rounded;
        label = 'Responded';
        break;
      case 'accepted':
        color = const Color(0xFF10B981);
        icon = Icons.check_circle_rounded;
        label = 'Accepted';
        break;
      case 'rejected':
        color = const Color(0xFFEF4444);
        icon = Icons.cancel_rounded;
        label = 'Rejected';
        break;
      case 'completed':
        color = const Color(0xFF8B5CF6);
        icon = Icons.verified_rounded;
        label = 'Completed';
        break;
      default:
        color = AppColors.textSecondary;
        icon = Icons.help_outline_rounded;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
