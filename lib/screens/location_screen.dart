import 'package:flutter/material.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('Location'),
          backgroundColor: Colors.brown,
        ),
        const Expanded(
          child: Center(
            child: Text(
              'Location Screen',
              style: TextStyle(fontSize: 24),
            ),
          ),
        ),
      ],
    );
  }
}