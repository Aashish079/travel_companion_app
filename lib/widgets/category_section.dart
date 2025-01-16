import 'package:flutter/material.dart';
import 'package:travel_companion_app/widgets/category_item.dart';
import 'package:travel_companion_app/widgets/stupa_card.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

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
              onPressed: () {},
              child: const Text('View all'),
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
                label: 'Temple',
                isSelected: false,
                onTap: () {},
              ),
              CategoryItem(
                icon: Icons.architecture,
                label: 'Stupa',
                isSelected: true,
                onTap: () {},
              ),
              CategoryItem(
                icon: Icons.water,
                label: 'River',
                isSelected: false,
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: const [
              StupaCard(
                name: 'Boudhanath Stupa',
                location: 'Boudha, Ktm',
                imageUrl: 'assets/images/boudhanath.png',
              ),
              SizedBox(width: 16),
              StupaCard(
                name: 'Swoyambhu',
                location: 'Boudha, Ktm',
                imageUrl: 'assets/images/Swaymbu.jpeg',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
