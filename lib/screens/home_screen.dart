import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/product_provider.dart';
import '../providers/customer_provider.dart';
import 'ai/ai_assistant_screen.dart';
import '../core/widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const HomeScreen({
    super.key,
    this.onNavigateToTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadDetails();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          'Dashboard',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: theme.colorScheme.onSurface),
            onPressed: () {}, // Optional: Add notification logic
          ),
          IconButton(
            icon: const Icon(Icons.psychology, color: Colors.orange),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Section
            Consumer<AuthProvider>(
              builder: (context, auth, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${auth.user?.displayName ?? 'User'} 👋',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Here's what's happening today.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Statistics Grid
            Consumer3<AnalyticsProvider, ProductProvider, CustomerProvider>(
              builder: (context, analytics, prod, cust, _) {
                final summary = analytics.summary;
                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      context,
                      title: "Today's Sales",
                      value: '₹${summary.todayRevenue.toStringAsFixed(0)}',
                      trend: '+8.5%', // Placeholder for trend
                      isPositive: true,
                      icon: Icons.attach_money,
                    ),
                    _buildStatCard(
                      context,
                      title: "This Month's Sales",
                      value: '₹${summary.monthRevenue.toStringAsFixed(0)}',
                      trend: '+12.3%',
                      isPositive: true,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Total Products',
                      value: '${prod.products.length}',
                      icon: Icons.inventory_2_outlined,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Low Stock Items',
                      value: '${prod.lowStockProducts.length}',
                      icon: Icons.warning_amber_rounded,
                      isWarning: prod.lowStockProducts.isNotEmpty,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Total Customers',
                      value: '${cust.customers.length}',
                      icon: Icons.people_outline,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Total Invoices',
                      value: '${summary.totalInvoices}',
                      icon: Icons.receipt_long_outlined,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Sales Overview Chart
            Text(
              'Sales Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildChartCard(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    String? trend,
    bool isPositive = true,
    bool isWarning = false,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                icon,
                size: 20,
                color: isWarning
                    ? Colors.orange
                    : theme.colorScheme.primary.withAlpha(150),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isWarning ? Colors.orange : theme.colorScheme.onSurface,
                ),
              ),
              if (trend != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? Colors.green.withAlpha(30)
                        : Colors.red.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, ThemeData theme) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Consumer<AnalyticsProvider>(
        builder: (context, analytics, _) {
          if (analytics.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final sales = analytics.dailySales;
          if (sales.isEmpty) {
            return const Center(child: Text("No sales data available."));
          }

          List<FlSpot> spots = [];
          for (int i = 0; i < sales.length; i++) {
            spots.add(FlSpot(i.toDouble(), sales[i].revenue));
          }

          return LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(
                show: true,
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false), // Simplified for now
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: theme.colorScheme.primary,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: theme.colorScheme.primary.withAlpha(30),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
