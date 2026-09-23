import 'package:flutter/material.dart';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../location/data/location_provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../products/data/product_model.dart';
import '../../services/data/service_model.dart';
import '../../products/presentation/product_detail_screen.dart';
import '../../services/presentation/service_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _api = ApiClient();

  List<Product> _products = [];
  List<Service> _services = [];
  List<Map<String, dynamic>> _vendors = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _searchType = 'all';
  String? _errorMessage;
  Timer? _debounce;
  Timer? _silenceTimer;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  String? _currentLocaleId;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _search(widget.initialQuery!);
    }
    _searchController.addListener(_onSearchChanged);
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _silenceTimer?.cancel();
    if (_isListening) {
      _speech.stop();
    }
    _searchController.dispose();
    super.dispose();
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

    // Start silence timer - auto-stop after 5 seconds of no speech
    _startSilenceTimer();

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;

          // Reset silence timer on any speech activity
          _resetSilenceTimer();

          setState(() {
            _searchController.text = result.recognizedWords;
            _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: _searchController.text.length),
            );
          });

          if (result.finalResult) {
            _stopListening();
          }
        },
        localeId: _currentLocaleId,
        partialResults: true,
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('Error starting speech listening: $e');
      setState(() => _isListening = false);
    }
  }

  Future<void> _stopListening() async {
    _silenceTimer?.cancel();
    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    } finally {
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
        if (mounted && _searchController.text.isNotEmpty) {
          // Trigger search if there's text when timeout occurs
          _search(_searchController.text);
        }
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

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _search(_searchController.text);
      }
    });
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _hasSearched = false;
        _products = [];
        _services = [];
        _vendors = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final locationProvider = context.read<LocationProvider>();
      final city = locationProvider.city;

      final response = await _api.get(ApiConstants.search, params: {
        'q': query.trim(),
        'type': _searchType,
        if (city != null && city.isNotEmpty) 'city': city,
      });

      if (response.success && response.data != null) {
        final productsData = response.data!['products'] as List? ?? [];
        final servicesData = response.data!['services'] as List? ?? [];
        final vendorsData = response.data!['vendors'] as List? ?? [];

        debugPrint(
            '🔍 Search Response - Products count: ${productsData.length}');
        debugPrint(
            '🔍 Search Response - Services count: ${servicesData.length}');
        debugPrint(
            '🔍 Search Response - Vendors count: ${vendorsData.length}');

        setState(() {
          _products = productsData.map((json) {
            try {
              return Product.fromJson(json);
            } catch (e) {
              debugPrint('❌ Error parsing product: $e');
              rethrow;
            }
          }).toList();
          _services = servicesData.map((json) {
            try {
              return Service.fromJson(json);
            } catch (e) {
              debugPrint('❌ Error parsing service: $e');
              rethrow;
            }
          }).toList();
          _vendors = List<Map<String, dynamic>>.from(vendorsData);
          _hasSearched = true;
          _isLoading = false;
        });

        // Debug parsed products
        if (_products.isNotEmpty) {
          debugPrint(
              '✅ First parsed product: name=${_products.first.name}, price=${_products.first.price}, thumbnail=${_products.first.thumbnail}');
        }

        // Debug parsed services
        if (_services.isNotEmpty) {
          debugPrint(
              '✅ First parsed service: name=${_services.first.name}, price=${_services.first.price}, thumbnail=${_services.first.thumbnail}, images=${_services.first.images}');
        }
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Search failed';
          _hasSearched = true;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _hasSearched = true;
        _isLoading = false;
      });
      debugPrint('Search error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _onFilterChanged(String newType) {
    setState(() => _searchType = newType);
    if (_searchController.text.isNotEmpty) {
      _search(_searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search products & services...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            filled: false,
          ),
          onSubmitted: _search,
        ),
        actions: [
          // Mic button with animation and tooltip
          Tooltip(
            message: _isListening ? 'Stop listening' : 'Voice search',
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  key: ValueKey(_isListening),
                  color: _isListening ? Colors.redAccent : null,
                ),
              ),
              onPressed: () async {
                if (_isListening) {
                  await _stopListening();
                } else {
                  await _startListening();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => _search(_searchController.text),
          ),
        ],
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
          Consumer<LocationProvider>(
            builder: (context, locationProvider, _) {
              final city = locationProvider.city;
              if (city == null || city.isEmpty) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.primary.withAlpha(10),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Searching in: ',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    Text(
                      city,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _searchType == 'all',
                    onTap: () => _onFilterChanged('all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Products',
                    isSelected: _searchType == 'products',
                    onTap: () => _onFilterChanged('products'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Services',
                    isSelected: _searchType == 'services',
                    onTap: () => _onFilterChanged('services'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Stores',
                    isSelected: _searchType == 'vendors',
                    onTap: () => _onFilterChanged('vendors'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.error),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _search(_searchController.text),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : !_hasSearched
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search,
                                    size: 64, color: AppColors.textSecondary),
                                SizedBox(height: 16),
                                Text(
                                  'Search products, services, and stores',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _products.isEmpty && _services.isEmpty && _vendors.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off,
                                        size: 64,
                                        color: AppColors.textSecondary),
                                    SizedBox(height: 16),
                                    Text(
                                      'No results found',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Try different keywords',
                                      style: TextStyle(
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              )
                            : ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  if (_vendors.isNotEmpty) ...[
                                    const Text(
                                      'Stores & Vendors',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 12),
                                    ...(_vendors.map((v) => _SearchResultCard(
                                          title: v['store_name']?.toString() ?? 'Store',
                                          subtitle: '${v['city'] ?? ''} ${v['owner_name'] != null ? "• " + v['owner_name'].toString() : ""}',
                                          price: null,
                                          image: v['logo']?.toString() ?? v['banner']?.toString(),
                                          onTap: () => _showVendorDetails(v),
                                        ))),
                                    const SizedBox(height: 24),
                                  ],
                                  if (_products.isNotEmpty) ...[
                                    const Text(
                                      'Products',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 12),
                                    ...(_products.map((p) => _SearchResultCard(
                                          title: p.name,
                                          subtitle: p.vendorName ?? '',
                                          price: p.price,
                                          image: p.thumbnail ??
                                              (p.images.isNotEmpty
                                                  ? p.images.first
                                                  : null),
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ProductDetailScreen(
                                                      productId: p.id),
                                            ),
                                          ),
                                        ))),
                                    const SizedBox(height: 24),
                                  ],
                                  if (_services.isNotEmpty) ...[
                                    const Text(
                                      'Services',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 12),
                                    ...(_services.map((s) => _SearchResultCard(
                                          title: s.name,
                                          subtitle: s.vendorName ?? '',
                                          price: s.price,
                                          image: s.thumbnail ??
                                              (s.images.isNotEmpty
                                                  ? s.images.first
                                                  : null),
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ServiceDetailScreen(
                                                      serviceId: s.id),
                                            ),
                                          ),
                                        ))),
                                  ],
                                ],
                              ),
          ),
        ],
      ),
    );
  }

  void _showVendorDetails(Map<String, dynamic> vendor) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: vendor['logo'] != null && vendor['logo'].toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(vendor['logo'].toString(), fit: BoxFit.cover),
                        )
                      : const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor['store_name']?.toString() ?? 'Store',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Owner: ${vendor['owner_name'] ?? 'N/A'}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (vendor['address'] != null || vendor['city'] != null) ...[
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${vendor['address'] ?? ''} ${vendor['city'] ?? ''} ${vendor['pincode'] ?? ''}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (vendor['store_description'] != null) ...[
              Text(
                vendor['store_description'].toString(),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check),
                label: const Text('Close'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double? price;
  final String? image;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.title,
    required this.subtitle,
    this.price,
    this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: image != null && image!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    image!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                )
              : const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: price != null
            ? Text(
                '₹${price!.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              )
            : const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
      ),
    );
  }
}
