import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
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
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  String? _currentLocaleId;
  Timer? _silenceTimer;

  // Local state for filtered category view
  List<Service> _filteredServices = [];
  bool _isLoadingFiltered = false;

  bool get _isFilteredByCategory => widget.categoryId != null;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    _loadData();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          debugPrint('Speech init error: $error');
          setState(() => _isListening = false);
        },
      );
      if (!mounted) return;
      setState(() {
        _speechAvailable = available;
      });
      if (available) {
        final sysLocale = await _speech.systemLocale();
        if (!mounted) return;
        setState(() {
          _currentLocaleId = sysLocale?.localeId;
        });
      }
    } catch (e) {
      debugPrint('Failed to initialize speech: $e');
      setState(() {
        _speechAvailable = false;
      });
    }
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
        // Fetch all subcategories for all categories
        final categories = context.read<CategoryProvider>().categories;
        for (final category in categories) {
          context.read<CategoryProvider>().fetchSubcategories(category.id);
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

    try {
      final params = {
        'category_id': widget.categoryId.toString(),
      };

      final response = await _api.get(ApiConstants.services, params: params);

      if (response.success && response.data != null) {
        final List<dynamic> data =
            response.data!['services'] ?? response.data!['data'] ?? [];
        final services = data.map((json) => Service.fromJson(json)).toList();

        setState(() {
          _filteredServices = services;
          _isLoadingFiltered = false;
        });
      } else {
        setState(() => _isLoadingFiltered = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response.message ?? 'Failed to load services')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoadingFiltered = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    if (_isListening) {
      _speech.stop();
    }
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    // Check microphone permission first
    final micPermission = await Permission.microphone.status;

    if (micPermission.isDenied) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        if (!mounted) return;
        _showPermissionDialog();
        return;
      }
    } else if (micPermission.isPermanentlyDenied) {
      if (!mounted) return;
      _showPermissionDialog();
      return;
    }

    // Initialize speech if not available
    if (!_speechAvailable) {
      await _initSpeech();
    }

    if (!_speechAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition is not available on this device'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isListening = true);

    _startSilenceTimer();

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;

          _resetSilenceTimer();

          setState(() {
            _searchController.text = result.recognizedWords;
            _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: _searchController.text.length),
            );
            _searchQuery = result.recognizedWords;
          });

          if (result.finalResult) {
            _stopListening();
          }
        },
        localeId: _currentLocaleId,
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      if (!mounted) return;
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start voice recognition: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _stopListening() async {
    _silenceTimer?.cancel();
    try {
      await _speech.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
      if (!mounted) return;
      setState(() => _isListening = false);
    }
  }

  void _startSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 5), () {
      if (_isListening) {
        debugPrint('Auto-stopping listening after 5 seconds of silence');
        _stopListening();
      }
    });
  }

  void _resetSilenceTimer() {
    if (_isListening) {
      _startSilenceTimer();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission Required'),
        content: const Text(
          'This app needs microphone access to convert your voice to text for searching. '
          'Please enable microphone permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
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

  Widget _buildServiceCard(Service service) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceDetailScreen(
            serviceId: service.id,
            initialService: service,
          ),
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
                        fontSize: 10,
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
                          fontSize: 8,
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
                              fontSize: 10,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 10, color: Colors.amber),
                            Text(
                              ' ${service.rating.toStringAsFixed(1)}',
                              style: const TextStyle(fontSize: 9),
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

  List<Service> _getFilteredServices(List<Service> services) {
    if (_searchQuery.isEmpty) return services;
    return services.where((service) {
      final searchLower = _searchQuery.toLowerCase();
      final descriptionMatch =
          service.description.toLowerCase().contains(searchLower);
      final categoryMatch =
          (service.categoryName?.toLowerCase().contains(searchLower) ?? false);
      return service.name.toLowerCase().contains(searchLower) ||
          descriptionMatch ||
          categoryMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.categoryName ?? 'Services'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.primary, size: 22),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none_rounded,
                          color: _isListening
                              ? AppColors.error
                              : AppColors.primary,
                          size: 22,
                        ),
                        onPressed:
                            _isListening ? _stopListening : _startListening,
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Listening indicator banner
          if (_isListening)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.red.shade200, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Listening... Speak now',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.red.shade600),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isFilteredByCategory
                ? _buildFilteredView()
                : _buildCategoryWiseView(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredView() {
    if (_isLoadingFiltered && _filteredServices.isEmpty) {
      return const LoadingWidget();
    }

    final displayServices = _getFilteredServices(_filteredServices);

    if (displayServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.build_circle_outlined,
                size: 60, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty
                  ? 'No services found'
                  : 'No services match your search',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
          childAspectRatio: 0.65,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: displayServices.length,
        itemBuilder: (context, index) {
          final service = displayServices[index];
          return _buildServiceCard(service);
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

        // Show error if loading failed
        if (serviceProvider.error != null && serviceProvider.services.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 60, color: AppColors.error),
                const SizedBox(height: 12),
                Text(
                  'Error: ${serviceProvider.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error, fontSize: 14),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => serviceProvider.fetchServices(refresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final filteredServices = _getFilteredServices(serviceProvider.services);

        if (filteredServices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.build_circle_outlined,
                    size: 60, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text(
                  _searchQuery.isEmpty
                      ? 'No services found'
                      : 'No services match your search',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final groupedServices = _groupServicesByCategory(filteredServices);
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
          const SizedBox(height: 8),
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
          builder: (_) => ServiceDetailScreen(
            serviceId: service.id,
            initialService: service,
          ),
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
