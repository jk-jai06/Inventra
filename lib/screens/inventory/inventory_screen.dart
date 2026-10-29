import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../models/stock_movement_model.dart';
import '../../providers/product_provider.dart';
import 'stock_adjustment_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory & Stock Movements'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'All'),
            Tab(icon: Icon(Icons.warning_amber_rounded), text: 'Low Stock'),
            Tab(icon: Icon(Icons.remove_circle_outline), text: 'Out of Stock'),
            Tab(icon: Icon(Icons.history_outlined), text: 'Movement Logs'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Global KPI Summary Cards at the top of Inventory
          Consumer<ProductProvider>(
            builder: (context, provider, _) {
              final all = provider.products.length;
              final low = provider.lowStockProducts.length;
              final out = provider.outOfStockProducts.length;

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Total Products',
                        count: '$all',
                        color: Colors.blue,
                        onTap: () => _tabController.animateTo(0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Low Stock',
                        count: '$low',
                        color: Colors.orange,
                        onTap: () => _tabController.animateTo(1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Out of Stock',
                        count: '$out',
                        color: Colors.red,
                        onTap: () => _tabController.animateTo(2),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                labelText: 'Search inventory by name, category, SKU',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductStockList(filterMode: 'all'),
                _buildProductStockList(filterMode: 'low'),
                _buildProductStockList(filterMode: 'out'),
                _buildMovementLogsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductStockList({required String filterMode}) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final all = provider.products;

        final filtered = all.where((p) {
          if (filterMode == 'low' && (!p.isLowStock || p.isOutOfStock)) {
            return false;
          }
          if (filterMode == 'out' && !p.isOutOfStock) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            return p.productName.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q) ||
                p.sku.toLowerCase().contains(q);
          }
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No items match your search'
                      : filterMode == 'low'
                          ? 'No low stock items'
                          : filterMode == 'out'
                              ? 'No out of stock items'
                              : 'No products found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            provider.startListening(force: true);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final product = filtered[index];
              return _buildProductStockCard(context, product);
            },
          ),
        );
      },
    );
  }

  Widget _buildProductStockCard(BuildContext context, ProductModel product) {
    final isOut = product.isOutOfStock;
    final isLow = product.isLowStock && !isOut;

    final badgeColor = isOut
        ? Colors.red
        : isLow
            ? Colors.orange
            : Colors.green;
    final statusText = isOut
        ? 'OUT OF STOCK'
        : isLow
            ? 'LOW STOCK'
            : 'IN STOCK';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${product.category} • SKU: ${product.sku.isNotEmpty ? product.sku : "N/A"}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Stock: ',
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          '${product.stockQuantity} ${product.unit}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Reorder Level: ${product.minimumStockLevel} units',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => StockAdjustmentDialog(product: product),
                    );
                  },
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Adjust Stock'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementLogsTab() {
    final productProvider = context.read<ProductProvider>();

    return FutureBuilder<List<StockMovementModel>>(
      future: productProvider.getRecentMovements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final movements = snapshot.data ?? [];
        if (movements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No stock movement logs recorded yet.'),
                const SizedBox(height: 8),
                const Text(
                  'Movements will record automatically on sales and stock adjustments.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: movements.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final m = movements[index];
              final isPositive = m.quantityChange > 0;
              final changeColor = isPositive ? Colors.green : Colors.red;
              final dateStr =
                  DateFormat('dd MMM yyyy, hh:mm a').format(m.timestamp);

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: changeColor.withValues(alpha: 0.15),
                    child: Icon(
                      isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                      color: changeColor,
                      size: 20,
                    ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          m.productName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '${isPositive ? "+" : ""}${m.quantityChange}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: changeColor,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              m.movementType.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Stock: ${m.previousQuantity} → ${m.newQuantity}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      if (m.notes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Note: ${m.notes}',
                            style: const TextStyle(
                                fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
