import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../data/auth_provider.dart';
import 'account_type_selection_screen.dart';
import '../../location/presentation/location_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _tileControllers;
  late List<Animation<Offset>> _tileAnimations;
  late AnimationController _textController;
  late Animation<double> _textOpacity;
  int _loadedImageCount = 0;
  bool _hasNavigated = false;

  final List<_TileData> _tiles = [
    _TileData(
        'https://images.unsplash.com/photo-1580901369227-308f6f40bdeb?q=80&w=1172&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        const Color(0xFFe94560),
        0,
        0,
        2,
        2,
        const Offset(-2, -2)), // Excavator
    _TileData(
        'https://images.unsplash.com/photo-1694521787193-9293daeddbaa?q=80&w=1169&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        const Color(0xFF0f4c75),
        2,
        0,
        1,
        1,
        const Offset(2, -1)), // Construction workers
    _TileData(
        'https://plus.unsplash.com/premium_photo-1664302293475-aafd35d6abf6?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        const Color(0xFF3282b8),
        2,
        1,
        1,
        1,
        const Offset(2, 1)), // Tools
    _TileData(
        'https://images.unsplash.com/photo-1630288213265-64e4673b6f49?q=80&w=1332&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        const Color(0xFF00b894),
        0,
        2,
        1,
        1,
        const Offset(-2, 0)), // Bulldozer
    _TileData(
        'https://images.unsplash.com/photo-1660367439240-d38cb03a4365?q=80&w=1173&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        const Color(0xFFfdcb6e),
        1,
        2,
        1,
        1,
        const Offset(0, -2)), // Construction site
    _TileData(
        'https://images.unsplash.com/photo-1760445726817-74664c6c1703?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        const Color(0xFFe17055),
        2,
        2,
        1,
        1,
        const Offset(2, 0)), // Crane
    _TileData(
        'https://images.unsplash.com/photo-1763272594463-b56b1a82ed62?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        const Color(0xFF6c5ce7),
        0,
        3,
        1,
        2,
        const Offset(-2, 1)), // Construction helmet
    _TileData(
        'https://plus.unsplash.com/premium_photo-1677707394493-09962b13b675?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        const Color(0xFF00cec9),
        1,
        3,
        1,
        1,
        const Offset(0, 2)), // Building structure
    _TileData(
        'https://images.unsplash.com/photo-1572981779307-38b8cabb2407?w=300&h=300&fit=crop',
        const Color(0xFFffeaa7),
        2,
        3,
        1,
        1,
        const Offset(2, 2)), // Electrical work
    _TileData(
        'https://images.unsplash.com/photo-1605910347035-59a2b94f2061?q=80&w=709&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        const Color(0xFFa29bfe),
        1,
        4,
        1,
        1,
        const Offset(0, 2)), // Plumbing
    _TileData(
        'https://plus.unsplash.com/premium_photo-1663100854088-bd8ab87870a7?q=80&w=1172&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        const Color(0xFF74b9ff),
        2,
        4,
        1,
        2,
        const Offset(2, 2)), // Forklift
    _TileData(
        'https://images.unsplash.com/photo-1610831499021-8d206e50bbb6?q=80&w=1171&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        const Color(0xFFff7675),
        0,
        5,
        2,
        1,
        const Offset(-2, 2)), // Construction site aerial
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    // specific safety timer: if images take too long (e.g. > 8 seconds), force move on
    // This prevents the "infinite spinner" if network images hang
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && !_hasNavigated) {
        debugPrint('Splash: Image loading timed out, forcing navigation.');
        _proceedToNavigation();
      }
    });
  }

  void _onImageLoaded() {
    if (!mounted) return;

    setState(() {
      _loadedImageCount++;
    });

    // Check if all images are loaded
    if (_loadedImageCount >= _tiles.length && !_hasNavigated) {
      // All images loaded fine, wait a bit for effect then go
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _proceedToNavigation();
      });
    }
  }

  Future<void> _proceedToNavigation() async {
    if (_hasNavigated) return;
    _hasNavigated = true;

    if (!mounted) return;

    _checkAuth();
  }

  void _setupAnimations() {
    _tileControllers = List.generate(
      _tiles.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 600 + (index * 80)),
        vsync: this,
      ),
    );

    _tileAnimations = List.generate(
      _tiles.length,
      (index) => Tween<Offset>(
        begin: _tiles[index].startOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _tileControllers[index],
        curve: Curves.easeOutBack,
      )),
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
  }

  void _startAnimations() {
    for (int i = 0; i < _tileControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _tileControllers[i].forward();
        }
      });
    }

    // Start text animation after tiles
    Future.delayed(Duration(milliseconds: _tiles.length * 100 + 300), () {
      if (mounted) {
        _textController.forward();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _tileControllers) {
      controller.dispose();
    }
    _textController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    // Add try-catch block to prevent auth check failure from hanging the app
    try {
      await authProvider.checkAuthStatus();
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      // Assume not authenticated on error, or handle as needed
      // But proceed to navigation
    }

    if (!mounted) return;

    final nextScreen = authProvider.isAuthenticated
        ? const LocationScreen()
        : const AccountTypeSelectionScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const gridPadding = 16.0;
    const gap = 10.0;
    const cols = 3;
    const rows = 6;
    final availableHeight = screenHeight -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;
    final tileWidth = (screenWidth - gridPadding * 2 - gap * (cols - 1)) / cols;
    final tileHeight =
        (availableHeight - gridPadding * 2 - gap * (rows - 1)) / rows;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Bento Grid - Full Screen
              Padding(
                padding: const EdgeInsets.all(gridPadding),
                child: Stack(
                  children: List.generate(_tiles.length, (index) {
                    final tile = _tiles[index];
                    final left = tile.col * (tileWidth + gap);
                    final top = tile.row * (tileHeight + gap);
                    final width =
                        tile.colSpan * tileWidth + (tile.colSpan - 1) * gap;
                    final height =
                        tile.rowSpan * tileHeight + (tile.rowSpan - 1) * gap;

                    return AnimatedBuilder(
                      animation: _tileAnimations[index],
                      builder: (context, child) {
                        return Positioned(
                          left: left +
                              _tileAnimations[index].value.dx * screenWidth,
                          top: top +
                              _tileAnimations[index].value.dy * screenHeight,
                          width: width,
                          height: height,
                          child: _BentoTile(
                            imageUrl: tile.imageUrl,
                            color: tile.color,
                            onImageLoaded: _onImageLoaded,
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),

              // Bottom Content - Overlay on top of grid
              Positioned(
                left: 0,
                right: 0,
                bottom: 30,
                child: FadeTransition(
                  opacity: _textOpacity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo Image
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.warning.withOpacity(0.2),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warning.withOpacity(0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/askus_logo.png',
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to text if image not found
                            return Column(
                              children: [
                                const Icon(
                                  Icons.question_answer_rounded,
                                  color: Colors.white,
                                  size: 60,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Ask Us',
                                  style: TextStyle(
                                    fontSize: 52,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your Marketplace',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a1a2e).withAlpha(220),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: AppColors.warning.withAlpha(100)),
                        ),
                        child: const Text(
                          'Construction & Equipment',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: AppColors.warning,
                              strokeWidth: 3,
                              backgroundColor: Colors.white.withAlpha(25),
                            ),
                            if (_loadedImageCount > 0 &&
                                _loadedImageCount < _tiles.length)
                              Text(
                                '${_loadedImageCount}/${_tiles.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileData {
  final String imageUrl;
  final Color color;
  final int col;
  final int row;
  final int colSpan;
  final int rowSpan;
  final Offset startOffset;

  const _TileData(
    this.imageUrl,
    this.color,
    this.col,
    this.row,
    this.colSpan,
    this.rowSpan,
    this.startOffset,
  );
}

class _BentoTile extends StatefulWidget {
  final String imageUrl;
  final Color color;
  final VoidCallback onImageLoaded;

  const _BentoTile({
    required this.imageUrl,
    required this.color,
    required this.onImageLoaded,
    Key? key,
  }) : super(key: key);

  @override
  State<_BentoTile> createState() => _BentoTileState();
}

class _BentoTileState extends State<_BentoTile> {
  bool _reported = false;

  void _reportLoadedOnce() {
    if (_reported) return;
    _reported = true;
    widget.onImageLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final imageUrl = widget.imageUrl;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withAlpha(80),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              cacheWidth: 800,
              cacheHeight: 800,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  // finished loading
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _reportLoadedOnce();
                  });
                  return child;
                }
                return Container(
                  color: color.withAlpha(30),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        color: color.withAlpha(150),
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                // Count errors as "loaded" so we don't block forever
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _reportLoadedOnce();
                });
                return Container(
                  color: color.withAlpha(30),
                  child: Icon(
                    Icons.construction,
                    size: 40,
                    color: color.withAlpha(150),
                  ),
                );
              },
            ),
            // Gradient overlay for better text visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withAlpha(80),
                    color.withAlpha(40),
                    Colors.transparent,
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
