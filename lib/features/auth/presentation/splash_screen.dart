import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../data/auth_provider.dart';
import 'login_screen.dart';
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

  final List<_TileData> _tiles = [
    _TileData(Icons.front_loader, const Color(0xFFe94560), 0, 0, 2, 2,
        const Offset(-2, -2)),
    _TileData(Icons.precision_manufacturing, const Color(0xFF0f4c75), 2, 0, 1,
        1, const Offset(2, -1)),
    _TileData(Icons.handyman, const Color(0xFF3282b8), 2, 1, 1, 1,
        const Offset(2, 1)),
    _TileData(Icons.agriculture, const Color(0xFF00b894), 0, 2, 1, 1,
        const Offset(-2, 0)),
    _TileData(Icons.local_shipping, const Color(0xFFfdcb6e), 1, 2, 1, 1,
        const Offset(0, -2)),
    _TileData(Icons.fire_truck, const Color(0xFFe17055), 2, 2, 1, 1,
        const Offset(2, 0)),
    _TileData(Icons.engineering, const Color(0xFF6c5ce7), 0, 3, 1, 2,
        const Offset(-2, 1)),
    _TileData(Icons.build_circle, const Color(0xFF00cec9), 1, 3, 1, 1,
        const Offset(0, 2)),
    _TileData(Icons.electrical_services, const Color(0xFFffeaa7), 2, 3, 1, 1,
        const Offset(2, 2)),
    _TileData(Icons.plumbing, const Color(0xFFa29bfe), 1, 4, 1, 1,
        const Offset(0, 2)),
    _TileData(Icons.forklift, const Color(0xFF74b9ff), 2, 4, 1, 2,
        const Offset(2, 2)),
    _TileData(Icons.construction, const Color(0xFFff7675), 0, 5, 2, 1,
        const Offset(-2, 2)),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
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
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.checkAuthStatus();

    if (!mounted) return;

    final nextScreen = authProvider.isAuthenticated
        ? const LocationScreen()
        : const LoginScreen();

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
                            icon: tile.icon,
                            color: tile.color,
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
                      const Text(
                        'Ask Us',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 20,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
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
                        child: CircularProgressIndicator(
                          color: AppColors.warning,
                          strokeWidth: 3,
                          backgroundColor: Colors.white.withAlpha(25),
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
  final IconData icon;
  final Color color;
  final int col;
  final int row;
  final int colSpan;
  final int rowSpan;
  final Offset startOffset;

  const _TileData(
    this.icon,
    this.color,
    this.col,
    this.row,
    this.colSpan,
    this.rowSpan,
    this.startOffset,
  );
}

class _BentoTile extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _BentoTile({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withAlpha(60),
            color.withAlpha(30),
          ],
        ),
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
      child: Center(
        child: Icon(
          icon,
          size: 40,
          color: color,
        ),
      ),
    );
  }
}
