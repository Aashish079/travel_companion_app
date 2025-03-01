import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Close button at the top
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              padding: const EdgeInsets.all(16),
            ),
          ),
          
          // Drawer items
          _buildDrawerItem(
            icon: Icons.bookmark_outline,
            title: 'Bookmarks',
            onTap: () {
              Navigator.pop(context);
              // Add navigation logic here
            },
          ),
          
          _buildDrawerItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            badge: '8',
            onTap: () {
              Navigator.pop(context);
              // Add navigation logic here
            },
          ),
          
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              // Add navigation logic here
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? badge,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 24,
        color: Colors.black87,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF2F4F4F),
                shape: BoxShape.circle,
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}