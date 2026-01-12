import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/utils/helpers.dart';
import '../../auth/data/auth_provider.dart';
import '../data/enquiry_provider.dart';
import '../data/enquiry_model.dart';

class EnquiryDetailScreen extends StatefulWidget {
  final int enquiryId;

  const EnquiryDetailScreen({super.key, required this.enquiryId});

  @override
  State<EnquiryDetailScreen> createState() => _EnquiryDetailScreenState();
}

class _EnquiryDetailScreenState extends State<EnquiryDetailScreen> {
  final _responseController = TextEditingController();
  String? _respondingAction; // Track which action is in progress

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EnquiryProvider>().fetchEnquiryDetail(widget.enquiryId);
      }
    });
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _respond(String action) async {
    if (_responseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a response message'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _respondingAction = action);

    final provider = context.read<EnquiryProvider>();
    // Always set status to 'responded' as per your requirement
    final success = await provider.respondToEnquiry(
      widget.enquiryId,
      _responseController.text,
      'responded',
    );

    if (!mounted) return;

    setState(() => _respondingAction = null);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                action == 'accept' ? Icons.check_circle : Icons.info_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(action == 'accept'
                  ? 'Enquiry accepted successfully'
                  : 'Enquiry rejected'),
            ],
          ),
          backgroundColor:
              action == 'accept' ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVendor = context.watch<AuthProvider>().isVendor;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<EnquiryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading || provider.currentEnquiry == null) {
            return const LoadingWidget();
          }

          final enquiry = provider.currentEnquiry!;

          return CustomScrollView(
            slivers: [
              _buildAppBar(enquiry),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildItemCard(enquiry),
                      const SizedBox(height: 16),
                      _buildContactCard(enquiry, isVendor),
                      const SizedBox(height: 16),
                      _buildMessageCard(enquiry),
                      if (enquiry.preferredDate != null ||
                          enquiry.preferredTime != null) ...[
                        const SizedBox(height: 16),
                        _buildScheduleCard(enquiry),
                      ],
                      if (enquiry.vendorResponse != null) ...[
                        const SizedBox(height: 16),
                        _buildResponseCard(enquiry),
                      ],
                      if (isVendor && enquiry.isPending) ...[
                        const SizedBox(height: 24),
                        _buildReplySection(),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(Enquiry enquiry) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
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
              padding: const EdgeInsets.fromLTRB(56, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      _TypeBadge(type: enquiry.type),
                      const SizedBox(width: 10),
                      _StatusBadge(status: enquiry.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enquiry #${enquiry.id}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Helpers.formatDateTime(enquiry.createdAt),
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(Enquiry enquiry) {
    final isProduct = enquiry.type == 'product';
    final color = isProduct ? const Color(0xFF3B82F6) : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isProduct
                  ? Icons.inventory_2_rounded
                  : Icons.build_circle_rounded,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isProduct ? 'Product Enquiry' : 'Service Enquiry',
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  enquiry.itemName ?? 'Unknown Item',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppColors.textSecondary.withAlpha(100),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Enquiry enquiry, bool isVendor) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVendor ? Icons.person_rounded : Icons.store_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isVendor ? 'Customer Details' : 'Vendor Details',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isVendor ? Icons.person_rounded : Icons.store_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVendor
                          ? enquiry.userName ?? 'Customer'
                          : enquiry.vendorName ?? 'Vendor',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isVendor && enquiry.userPhone != null) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: enquiry.userPhone!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Phone number copied'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 14,
                              color: AppColors.textSecondary.withAlpha(150),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              enquiry.userPhone!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.copy_rounded,
                              size: 12,
                              color: AppColors.textSecondary.withAlpha(100),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(Enquiry enquiry) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.message_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Enquiry Message',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      size: 20,
                      color: AppColors.primary.withAlpha(100),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        enquiry.message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Enquiry enquiry) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Preferred Schedule',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (enquiry.preferredDate != null)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_rounded,
                          size: 20,
                          color: Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              enquiry.preferredDate!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (enquiry.preferredDate != null &&
                  enquiry.preferredTime != null)
                const SizedBox(width: 12),
              if (enquiry.preferredTime != null)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 20,
                          color: Color(0xFF8B5CF6),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Time',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              enquiry.preferredTime!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResponseCard(Enquiry enquiry) {
    final isAccepted =
        enquiry.status == 'accepted' || enquiry.status == 'completed';
    final color =
        isAccepted ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAccepted ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                'Vendor Response',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              if (enquiry.respondedAt != null)
                Text(
                  Helpers.timeAgo(enquiry.respondedAt!),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary.withAlpha(150),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withAlpha(30)),
            ),
            child: Text(
              enquiry.vendorResponse!,
              style: TextStyle(
                fontSize: 14,
                color: color.withAlpha(220),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplySection() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.reply_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                'Your Response',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _responseController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Type your response here...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withAlpha(150),
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Accept',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF10B981),
                  isLoading: _respondingAction == 'accept',
                  isDisabled: _respondingAction != null,
                  onPressed: () => _respond('accept'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'Reject',
                  icon: Icons.cancel_rounded,
                  color: const Color(0xFFEF4444),
                  isLoading: _respondingAction == 'reject',
                  isDisabled: _respondingAction != null,
                  onPressed: () => _respond('reject'),
                ),
              ),
            ],
          ),
        ],
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isProduct ? Icons.inventory_2_rounded : Icons.build_circle_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            type.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
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
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case 'pending':
        bgColor = const Color(0xFFF59E0B);
        textColor = Colors.white;
        icon = Icons.schedule_rounded;
        label = 'Pending';
        break;
      case 'responded':
        bgColor = const Color(0xFF3B82F6);
        textColor = Colors.white;
        icon = Icons.reply_rounded;
        label = 'Responded';
        break;
      case 'accepted':
        bgColor = const Color(0xFF10B981);
        textColor = Colors.white;
        icon = Icons.check_circle_rounded;
        label = 'Accepted';
        break;
      case 'rejected':
        bgColor = const Color(0xFFEF4444);
        textColor = Colors.white;
        icon = Icons.cancel_rounded;
        label = 'Rejected';
        break;
      case 'completed':
        bgColor = const Color(0xFF8B5CF6);
        textColor = Colors.white;
        icon = Icons.verified_rounded;
        label = 'Completed';
        break;
      default:
        bgColor = Colors.white.withAlpha(30);
        textColor = Colors.white;
        icon = Icons.help_outline_rounded;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.isLoading = false,
    this.isDisabled = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        isDisabled && !isLoading ? color.withAlpha(100) : color;

    return Material(
      color: effectiveColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: (isLoading || isDisabled) ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              else ...[
                Icon(
                  icon,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
