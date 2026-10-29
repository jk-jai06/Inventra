import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/customer_provider.dart';
import '../ai/ai_assistant_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final shopId = auth.shopId ?? 'N/A';
    final role = (auth.role ?? 'owner').toUpperCase();

    final displayName = user?.displayName ??
        (user?.email != null ? user!.email!.split('@').first : 'Shop Owner');
    final email = user?.email ?? 'No email';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Store Profile & Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // User & Shop Profile Header Card
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              role,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.store_mall_directory_outlined, size: 14, color: Colors.blue[700]),
                          const SizedBox(width: 6),
                          Text(
                            'Shop ID: $shopId',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Business Overview Summary
          Consumer3<ProductProvider, CustomerProvider, AnalyticsProvider>(
            builder: (context, prod, cust, analytics, _) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shop Overview',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Products', '${prod.products.length}', Colors.purple),
                        _buildDivider(),
                        _buildStatItem('Customers', '${cust.customers.length}', Colors.teal),
                        _buildDivider(),
                        _buildStatItem(
                          'Total Sales',
                          '₹${analytics.summary.totalRevenue.toStringAsFixed(0)}',
                          Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Settings & Modules List
          _buildSectionHeader(theme, 'Store & Business Configuration'),
          const SizedBox(height: 12),

          _buildSettingsTile(
            context,
            icon: Icons.store_mall_directory_outlined,
            iconColor: Colors.blue,
            title: 'Business Information',
            subtitle: 'Store name, address & default invoice header',
            onTap: () => _showBusinessInfoDialog(context, displayName, shopId),
          ),
          const SizedBox(height: 12),

          _buildSettingsTile(
            context,
            icon: Icons.receipt_long_outlined,
            iconColor: Colors.teal,
            title: 'GST & Tax Settings',
            subtitle: 'Default state code (27 - MH), CGST, SGST & IGST rules',
            onTap: () => _showGstSettingsDialog(context),
          ),
          const SizedBox(height: 12),

          _buildSettingsTile(
            context,
            icon: Icons.psychology_outlined,
            iconColor: Colors.orange,
            title: 'AI Assistant & Demand Forecasts',
            subtitle: 'Smart inventory depletion predictions & shop intelligence',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AiAssistantScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          _buildSectionHeader(theme, 'System & Information'),
          const SizedBox(height: 12),

          _buildSettingsTile(
            context,
            icon: Icons.cloud_done_outlined,
            iconColor: Colors.green,
            title: 'Cloud Firestore Sync',
            subtitle: 'Real-time synchronization active • inventra-retail-ai',
            onTap: () => _showSyncStatusDialog(context),
          ),
          const SizedBox(height: 12),

          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            iconColor: Colors.indigo,
            title: 'About INVENTRA',
            subtitle: 'Version 1.0.0 • AI-Assisted Smart Inventory System',
            onTap: () => _showAboutDialog(context),
          ),
          const SizedBox(height: 40),

          // Sign Out Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => _showSignOutDialog(context, auth),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 32,
      width: 1,
      color: Colors.grey.withAlpha(50),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.grey[500],
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBusinessInfoDialog(
      BuildContext context, String displayName, String shopId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Store Information', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shop Name: $displayName'),
            const SizedBox(height: 8),
            Text('Shop ID: $shopId'),
            const SizedBox(height: 8),
            const Text('Invoice Prefix: INV'),
            const SizedBox(height: 8),
            const Text('Currency: Indian Rupee (₹)'),
            const SizedBox(height: 8),
            const Text('Status: Active & Verified', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showGstSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('GST & Tax Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Default State Code: 27 (Maharashtra)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text(
                '• Intra-State Billing: CGST (50%) + SGST (50%) applied when customer state code matches or for Walk-in (B2C) sales.'),
            SizedBox(height: 12),
            Text(
                '• Inter-State Billing: Full IGST applied when customer GSTIN state code differs from shop state code.'),
            SizedBox(height: 12),
            Text('• Standard Brackets: 0%, 5%, 12%, 18%, 28%'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSyncStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cloud Synchronization', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                SizedBox(width: 12),
                Text('Firestore Online & Syncing',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            SizedBox(height: 16),
            Text('Database: (default) - asia-south1'),
            SizedBox(height: 8),
            Text('Project: inventra-retail-ai'),
            SizedBox(height: 8),
            Text('Offline Persistence: Enabled'),
            SizedBox(height: 8),
            Text('Listeners: Products, Invoices, Customers, Analytics'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('INVENTRA', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI-Assisted Smart Inventory and GST Billing System for Retail Shops',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Platform: Flutter & Dart'),
            SizedBox(height: 8),
            Text('Backend: Firebase Authentication & Cloud Firestore'),
            SizedBox(height: 8),
            Text('Intelligence: FastAPI ML Engine & Demand Forecasting'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to sign out of your INVENTRA session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
