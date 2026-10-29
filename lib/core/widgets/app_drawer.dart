import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/main_navigation_shell.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _navigateToTab(BuildContext context, int index) {
    Navigator.pop(context); // Close the drawer
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => MainNavigationShell(initialIndex: index),
      ),
      (route) => false,
    );
  }

  String _getInitial(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    return name.trim().substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
            ),
            accountName: Text(
              auth.user?.displayName ?? 'User',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(auth.user?.email ?? ''),
                if (auth.shopId != null) 
                  Text('Shop ID: ${auth.shopId}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: theme.colorScheme.onPrimary,
              child: Text(
                _getInitial(auth.user?.displayName),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () => _navigateToTab(context, 0),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Products'),
            onTap: () => _navigateToTab(context, 1),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Billing'),
            onTap: () => _navigateToTab(context, 2),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Customers'),
            onTap: () => _navigateToTab(context, 3),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () => _navigateToTab(context, 4),
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context); // Close drawer
              auth.signOut();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
