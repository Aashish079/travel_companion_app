import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:travel_companion_app/widgets/category_section.dart';
import 'package:travel_companion_app/widgets/destination_card.dart';
import 'package:travel_companion_app/widgets/location_header.dart';
import 'package:travel_companion_app/widgets/custom_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: const [
          CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('assets/images/person.png'),
          ),
          SizedBox(width: 16),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const LocationHeader(
                location: 'Patan, Kathmandu',
              ),
              const SizedBox(height: 24),
              const CategorySection(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Best Destination',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const DestinationGrid(),
            ],
          ),
        ),
      ),
    );
  }
}
