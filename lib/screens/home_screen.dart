import 'package:flutter/material.dart';
import '../widgets/location_header.dart';
import '../widgets/category_section.dart';
import '../widgets/destination_card.dart';
import '../widgets/bottom_navigation_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {debugPrint('Menu button pressed');},
        ),
        actions: const [
          CircleAvatar(
            radius: 20,
            // backgroundColor: Colors.grey[300],
            // child: const Icon(Icons.person),
            backgroundImage: AssetImage('assets/images/person.png'),
          ),
          SizedBox(width: 16),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
      bottomNavigationBar: const CustomBottomNavigation(),
    );
  }
}
