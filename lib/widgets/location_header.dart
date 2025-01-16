import 'package:flutter/material.dart';

class LocationHeader extends StatelessWidget {
  final String location;

  const LocationHeader({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_on, color: Colors.red),
        const SizedBox(width: 8),
        Text(
          location,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}