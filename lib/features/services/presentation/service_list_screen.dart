import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../categories/data/category_provider.dart';
import '../../categories/data/category_model.dart';
import '../data/service_provider.dart';
import '../data/service_model.dart';
import 'service_detail_screen.dart';

class ServiceListScreen extends StatefulWidget {
  final int? categoryId;
  final String? categoryName;

  const ServiceListScreen({super.key, this.categoryId, this.categoryName});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final _scrollController = ScrollController();
  final _api = ApiClient();

  // Local state for filtered category view
  List<Service> _filteredServices = [];
  bool _isLoadingFiltered = false;

  bool get _isFilteredByCategory => widget.categoryId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_isFilteredByCategory) {
          // Load filtered services locally
          _fetchFilteredServices();
        } else {
          // Load all services via provider
          context.read<CategoryProvider>().fetchCategories();
          context.read<ServiceProvider>().fetchServices(refresh: true);
        }
      }
    });
  }

  Future<void> _fetchFilteredServices() async {
    if (_isLoadingFiltered) return;

    setState(() {
      _isLoadingFiltered = true;
      _filteredServices = [];
    });

    final params = {
      'category_id': widget.categoryId.toString(),
    };

    final response = await _api.get(ApiConstants.services, params: params);

    if (response.success && response.data != null) {
      final List<dynamic> data = response.data!['services'] ?? [];
      final services = data.map((json) => Service.fromJson(json)).toList();

      setState(() {
        _filteredServices = services;
        _isLoadingFiltered = false;
      });
    } else {
      setState(() => _isLoadingFiltered = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Group services by category
  Map<int, List<Service>> _groupServicesByCategory(List<Service> services) {
    final Map<int, List<Service>> grouped = {};
    for (final service in services) {
      if (!grouped.containsKey(service.categoryId)) {
        grouped[service.categoryId] = [];
      }
      grouped[service.categoryId]!.add(service);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.categoryName ?? 'Services'),
        elevation: 0,
      ),
      body: _isFilteredByCategory
          ? _buildFilteredView()
          : _buildCategoryWiseView(),
    );
  }

  Widget _buildFilteredView() {
    if (_isLoadingFiltered && _filteredServices.isEmpty) {
      return const LoadingWidget();
    }

    if (_filteredServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.build_circle_outlined,
                size: 60, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text(
              'No services found',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchFilteredServices(),
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.58,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _filteredServices.length,
        itemBuilder: (context, index) {
          final service = _filteredServices[index];
          return _ServiceGridCard(service: service);
        },
      ),
    );
  }

  Widget _buildCategoryWiseView() {
    return Consumer2<ServiceProvider, CategoryProvider>(
      builder: (context, serviceProvider, categoryProvider, _) {
        if (serviceProvider.isLoading && serviceProvider.services.isEmpty) {
          return const LoadingWidget();
        }

        if (serviceProvider.services.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.build_circle_outlined,
                    size: 60, color: AppColors.textSecondary),
                SizedBox(height: 12),
                Text(
                  'No services found',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final groupedServices =
            _groupServicesByCategory(serviceProvider.services);
        final categories = categoryProvider.categories;

        return RefreshIndicator(
          onRefresh: () async {
            await categoryProvider.fetchCategories();
            await serviceProvider.fetchServices(refresh: true);
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: groupedServices.keys.length,
            itemBuilder: (context, index) {
              final categoryId = groupedServices.keys.elementAt(index);
              final services = groupedServices[categoryId]!;

              final category = categories.firstWhere(
                (c) => c.id == categoryId,
                orElse: () => Category(
                  id: categoryId,
                  name: services.first.categoryName ?? 'Other',
                  slug: '',
                  sortOrder: 0,
                  status: 'active',
                ),
              );

              return _CategorySection(
                category: category,
                services: services,
                onViewAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServiceListScreen(
                      categoryId: categoryId,
                      categoryName: category.name,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CategorySection extends StatelessWidget {
  final Category category;
  final List<Service> services;
  final VoidCallback onViewAll;

  const _CategorySection({
    required this.category,
    required this.services,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.build_circle_rounded,
                      color: AppColors.secondary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: services.length,
              itemBuilder: (context, index) {
                return _ServiceCard(service: services[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceDetailScreen(serviceId: service.id),
        ),
      ),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              child: Container(
                height: 85,
                width: double.infinity,
                color: AppColors.background,
                child:
                    service.thumbnail != null && service.thumbnail!.isNotEmpty
                        ? Image.network(
                            service.thumbnail!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.build_circle_outlined,
                              size: 30,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : const Icon(
                            Icons.build_circle_outlined,
                            size: 30,
                            color: AppColors.textSecondary,
                          ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (service.vendorName != null)
                      Text(
                        service.vendorName!,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '₹${service.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 12, color: Colors.amber),
                            Text(
                              ' ${service.rating.toStringAsFixed(1)}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceGridCard extends StatelessWidget {
  final Service service;

  const _ServiceGridCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceDetailScreen(serviceId: service.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: Container(
                  width: double.infinity,
                  color: AppColors.background,
                  child:
                      service.thumbnail != null && service.thumbnail!.isNotEmpty
                          ? Image.network(
                              service.thumbnail!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.build_circle_outlined,
                                size: 40,
                                color: AppColors.textSecondary,
                              ),
                            )
                          : const Icon(
                              Icons.build_circle_outlined,
                              size: 40,
                              color: AppColors.textSecondary,
                            ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (service.vendorName != null)
                      Text(
                        service.vendorName!,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            '₹${service.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 12, color: Colors.amber),
                            Text(
                              ' ${service.rating.toStringAsFixed(1)}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
