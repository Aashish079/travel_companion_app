import 'package:flutter/material.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('Bookmarks'),
          backgroundColor: Colors.brown,
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