// lib/views/screens/location_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/location_model.dart';
import '../viewmodels/location_viewmodel.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool _isLoading = false;

  Future<void> _getLocation(LocationViewModel viewModel) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Force a fresh location reading by using Duration.zero as maxAge
      await viewModel.getLocation(maxAge: Duration.zero);
    } catch (e) {
      // Error handling is done by the ViewModel
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure location services are initialized when screen loads
      final viewModel = Provider.of<LocationViewModel>(context, listen: false);
      if (!viewModel.isInitialized) {
        viewModel.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location'),
      ),
      body: Consumer<LocationViewModel>(
        builder: (context, locationViewModel, child) {
          final location = locationViewModel.currentLocation;
          final error = locationViewModel.errorMessage;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Location button - always visible
                  ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _getLocation(locationViewModel),
                    icon: const Icon(Icons.my_location),
                    label: Text(_isLoading ? 'Getting Location...' : 'Locate'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Show loading indicator if getting location
                  if (_isLoading)
                    const CircularProgressIndicator()

                  // Show error message if there is one
                  else if (error != null)
                    Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: $error',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )

                  // Show location data if available
                  else if (location != null)
                    _buildLocationInfo(location)

                  // Show placeholder text if no location yet
                  else
                    const Text(
                      'Tap the button to get your current location',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationInfo(LocationModel location) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Your Location',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.location_on,
            label: 'Latitude',
            value: '${location.latitude.toStringAsFixed(6)}°',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.location_on,
            label: 'Longitude',
            value: '${location.longitude.toStringAsFixed(6)}°',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.compass_calibration,
            label: 'Orientation',
            value: location.heading != null
                ? '${location.heading!.toStringAsFixed(1)}°'
                : 'Not available',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Timestamp',
            value: _formatTimestamp(location.timestamp),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 22),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    // Format the timestamp in a readable way
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }
}
