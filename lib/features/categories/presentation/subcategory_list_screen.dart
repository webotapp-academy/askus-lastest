import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/category_provider.dart';
import '../data/subcategory_model.dart';
import '../../products/presentation/product_list_screen.dart';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SubcategoryListScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const SubcategoryListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<SubcategoryListScreen> createState() => _SubcategoryListScreenState();
}

class _SubcategoryListScreenState extends State<SubcategoryListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String? _currentLocaleId;
  Timer? _silenceTimer;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadSubcategories();
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

  void _loadSubcategories() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CategoryProvider>().fetchSubcategories(widget.categoryId);
      }
    });
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    if (_isListening) {
      _speech.stop();
    }
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

  List<Subcategory> _getFilteredSubcategories(List<Subcategory> subcategories) {
    if (_searchQuery.isEmpty) return subcategories;
    return subcategories.where((subcategory) {
      final searchLower = _searchQuery.toLowerCase();
      return subcategory.name.toLowerCase().contains(searchLower) ||
          (subcategory.description?.toLowerCase().contains(searchLower) ??
              false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.categoryName),
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
                  hintText: 'Search subcategories...',
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
            child: Consumer<CategoryProvider>(
              builder: (context, provider, _) {
                final subcategories = _getFilteredSubcategories(
                  provider.getSubcategoriesByCategory(widget.categoryId),
                );

                if (provider.isLoadingSubcategories && subcategories.isEmpty) {
                  return const LoadingWidget();
                }

                if (subcategories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No subcategories match your search'
                              : 'No subcategories available',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Navigate directly to products if no subcategories
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductListScreen(
                                    categoryId: widget.categoryId,
                                    categoryName: widget.categoryName,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.shopping_bag_outlined,
                                size: 18),
                            label: const Text('View All Products'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await provider.fetchSubcategories(widget.categoryId);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select a subcategory',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: subcategories.length,
                            itemBuilder: (context, index) {
                              return _SubcategoryCard(
                                subcategory: subcategories[index],
                                categoryName: widget.categoryName,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SubcategoryCard extends StatelessWidget {
  final Subcategory subcategory;
  final String categoryName;

  const _SubcategoryCard({
    required this.subcategory,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductListScreen(
            categoryId: subcategory.categoryId,
            categoryName: subcategory.name,
            subcategoryId: subcategory.id,
            subcategoryName: subcategory.name,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image or gradient
              _buildBackground(),

              // Dark gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),

              // Subcategory name at bottom
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subcategory.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subcategory.description != null &&
                        subcategory.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subcategory.description!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // View arrow indicator
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (subcategory.image != null && subcategory.image!.isNotEmpty) {
      return Image.network(
        subcategory.image!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.primary.withOpacity(0.1),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildFallbackBackground(),
      );
    }
    return _buildFallbackBackground();
  }

  Widget _buildFallbackBackground() {
    // Generate a color based on the subcategory name for variety
    final colors = [
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF6366F1), // Indigo
    ];
    final colorIndex = subcategory.name.hashCode.abs() % colors.length;
    final color = colors[colorIndex];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.4),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _getIconForSubcategory(),
          size: 48,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  IconData _getIconForSubcategory() {
    final name = subcategory.name.toLowerCase();

    // Construction & machinery related
    if (name.contains('excavator')) return Icons.construction_rounded;
    if (name.contains('bulldozer')) return Icons.agriculture_rounded;
    if (name.contains('crane')) return Icons.precision_manufacturing_rounded;
    if (name.contains('loader')) return Icons.local_shipping_rounded;

    // Hardware related
    if (name.contains('fastener') ||
        name.contains('screw') ||
        name.contains('bolt')) {
      return Icons.handyman_rounded;
    }
    if (name.contains('tool')) return Icons.build_rounded;
    if (name.contains('door') || name.contains('hardware')) {
      return Icons.door_front_door_outlined;
    }

    // Workers/Labor related
    if (name.contains('worker') || name.contains('labor')) {
      return Icons.engineering_rounded;
    }
    if (name.contains('technician')) return Icons.settings_rounded;
    if (name.contains('staff')) return Icons.groups_rounded;

    // Design related
    if (name.contains('design') || name.contains('interior')) {
      return Icons.design_services_rounded;
    }
    if (name.contains('furniture')) return Icons.chair_rounded;
    if (name.contains('color') || name.contains('paint')) {
      return Icons.palette_rounded;
    }
    if (name.contains('lighting') || name.contains('light')) {
      return Icons.lightbulb_rounded;
    }

    // Electrical related
    if (name.contains('wiring') ||
        name.contains('wire') ||
        name.contains('cable')) {
      return Icons.cable_rounded;
    }
    if (name.contains('switch') || name.contains('outlet')) {
      return Icons.electrical_services_rounded;
    }
    if (name.contains('panel') || name.contains('board')) {
      return Icons.developer_board_rounded;
    }

    // Default
    return Icons.category_rounded;
  }
}
