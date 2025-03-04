import 'package:flutter/material.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text(
            'Bookmarks',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 255, 255) // Make text bold
                ),
          ),
          backgroundColor: const Color.fromARGB(255, 148, 20, 1),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'Bookmarks Screen',
              style: TextStyle(fontSize: 24),
            ),
          ),
        ),
      ],
    );
  }
}
