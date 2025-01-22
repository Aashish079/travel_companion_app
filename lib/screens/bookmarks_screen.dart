import 'package:flutter/material.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        backgroundColor: Colors.brown,
      ),
      body: const Center(
        child: Text(
          'Bookmarks Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}