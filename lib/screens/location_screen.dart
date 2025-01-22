import 'package:flutter/material.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location'),
        backgroundColor: Colors.brown,
      ),
      body: const Center(
        child: Text(
          'Location Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}