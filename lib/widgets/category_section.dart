import 'package:flutter/material.dart';
import 'package:travel_companion_app/widgets/category_item.dart';
import 'package:travel_companion_app/widgets/stupa_card.dart';
import 'package:travel_companion_app/screens/all_monuments_screen.dart';

class CategorySection extends StatefulWidget {
  const CategorySection({super.key});

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  String _selectedCategory = 'Stupas'; // Default selected category

  // Data for different categories
  final Map<String, List<Map<String, String>>> _categoryData = {
    'Temples': [
      {
        'name': 'Pashupatinath Temple',
        'location': 'Gaushala, Ktm',
        'imageUrl': 'assets/images/pashupatinath.png',
      },
      {
        'name': 'Krishna Temple',
        'location': 'Patan, Ktm',
        'imageUrl': 'assets/images/krishnamandir.jpg',
      },
    ],
    'Stupas': [
      {
        'name': 'Boudhanath Stupa',
        'location': 'Boudha, Ktm',
        'imageUrl': 'assets/images/boudhanath.png',
      },
      {
        'name': 'Swoyambhu',
        'location': 'Boudha, Ktm',
        'imageUrl': 'assets/images/Swaymbu.jpeg',
      },
    ],
    'Monuments': [
      {
        'name': 'Dharahara',
        'location': 'Sundhara, Ktm',
        'imageUrl': 'assets/images/dharahara.png',
      },
      {
        'name': 'Basantapur',
        'location': 'Kathmandu, Ktm',
        'imageUrl': 'assets/images/basantapur.png',
      },
    ],
  };

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to all monuments with the selected category
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllMonumentsScreen(
                      title: 'All ',
                    ),
                  ),
                );
              },
              child: const Text(
                'View all',
                style: TextStyle(
                  color: Color.fromARGB(
                      255, 148, 20, 1), // Change to any color you want
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              CategoryItem(
                icon: Icons.temple_buddhist,
                label: 'Temples',
                isSelected: _selectedCategory == 'Temples',
                onTap: () => _onCategorySelected('Temples'),
              ),
              CategoryItem(
                icon: Icons.architecture,
                label: 'Stupas',
                isSelected: _selectedCategory == 'Stupas',
                onTap: () => _onCategorySelected('Stupas'),
              ),
              CategoryItem(
                icon: Icons.attractions_sharp,
                label: 'Monuments',
                isSelected: _selectedCategory == 'Monuments',
                onTap: () => _onCategorySelected('Monuments'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categoryData[_selectedCategory]!.map((item) {
              return Row(
                children: [
                  StupaCard(
                    name: item['name']!,
                    location: item['location']!,
                    imageUrl: item['imageUrl']!,
                  ),
                  const SizedBox(width: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
