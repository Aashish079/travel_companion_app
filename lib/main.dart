import 'package:flutter/material.dart';
import 'package:travel_companion_app/screens/bookmarks_screen.dart';
import 'package:travel_companion_app/screens/camera_screen.dart';
import 'package:travel_companion_app/screens/home_screen.dart';
import 'package:travel_companion_app/screens/location_screen.dart';
import 'package:travel_companion_app/screens/profile_screen.dart';
import 'package:travel_companion_app/widgets/bottom_navigation_bar.dart';

void main() {
  runApp(const TravelApp());
}

class TravelApp extends StatefulWidget {
  const TravelApp({super.key});

  @override
  State<TravelApp> createState() => _TravelAppState();
}

class _TravelAppState extends State<TravelApp> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BookmarksScreen(),
    const CameraScreen(),
    const LocationScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Travel App',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: CustomBottomNavigation(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
