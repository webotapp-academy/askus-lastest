import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../data/location_provider.dart';
import '../../auth/data/auth_provider.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../categories/presentation/home_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final locationProvider = context.read<LocationProvider>();
    await locationProvider.loadSavedLocation();
    
    if (locationProvider.hasLocation && mounted) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    debugPrint('📍 LocationScreen: Navigating to HomeScreen...');
    try {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      debugPrint('✅ LocationScreen: Navigation initiated successfully');
    } catch (e) {
      debugPrint('❌ LocationScreen: Navigation error: $e');
    }
  }

  Future<void> _detectLocation() async {
    final locationProvider = context.read<LocationProvider>();
    final success = await locationProvider.getCurrentLocation();
    
    if (success && mounted) {
      _navigateToHome();
    } else if (mounted && locationProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locationProvider.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(authProvider.isVendor ? 'Set Store Location' : 'Set Your Location'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<LocationProvider>(
        builder: (context, location, _) {
          if (location.isLoading) {
            return const LoadingWidget(message: 'Detecting your location...');
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 100,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  authProvider.isVendor
                      ? 'Set your store location to start receiving enquiries'
                      : 'We need your location to show nearby products and services',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Detect My Location',
                    icon: Icons.my_location,
                    onPressed: _detectLocation,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Enter Manually',
                    isOutlined: true,
                    icon: Icons.edit_location_alt,
                    onPressed: () => _showManualLocationDialog(context),
                  ),
                ),
                if (location.hasLocation) ...[
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.success, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            location.currentAddress ?? 'Location detected',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            text: 'Continue',
                            onPressed: _navigateToHome,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showManualLocationDialog(BuildContext context) {
    final pincodeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Pincode'),
        content: CustomTextField(
          controller: pincodeController,
          label: 'Pincode',
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (pincodeController.text.length == 6) {
                final locationProvider = context.read<LocationProvider>();
                await locationProvider.setManualLocation(
                  latitude: 0,
                  longitude: 0,
                  pincode: pincodeController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  _navigateToHome();
                }
              }
            },
            child: const Text('Set Location'),
          ),
        ],
      ),
    );
  }
}
