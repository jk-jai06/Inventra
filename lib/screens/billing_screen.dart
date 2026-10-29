import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/customer_model.dart';
import '../models/product_model.dart';
import '../providers/customer_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/product_provider.dart';
import 'invoice_detail_screen.dart';
import 'invoice_history_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'POS Billing',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.receipt_long_outlined, color: theme.colorScheme.onSurface),
            tooltip: 'Invoice History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InvoiceHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          final filteredProducts = (productProvider.products)
              .where((product) =>
                  _searchText.isEmpty ||
                  product.productName
                      .toLowerCase()
                      .contains(_searchText.toLowerCase()) ||
                  product.category
                      .toLowerCase()
                      .contains(_searchText.toLowerCase()) ||
                  product.sku
                      .toLowerCase()
                      .contains(_searchText.toLowerCase()))
              .toList();

          return Consumer<CustomerProvider>(
            builder: (context, customerProvider, _) {
              return Consumer<InvoiceProvider>(
                builder: (context, invoiceProvider, _) {
                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Customer selection
                      _buildCustomerSelector(context, customerProvider, invoiceProvider),
                      const SizedBox(height: 24),

                      // Product Search
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search products by name, SKU, category',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchText.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchText = '');
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() => _searchText = value.trim());
                        },
                      ),
                      const SizedBox(height: 16),

                      if (productProvider.isLoading &&
                          productProvider.products.isEmpty)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        )),
                      if (productProvider.errorMessage != null)
                        _buildErrorCard(context, productProvider.errorMessage!),

                      // Product Picker List
                      if (filteredProducts.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Available Products',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${filteredProducts.length} items',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...filteredProducts.map(
                            (product) => _buildProductTile(context, product, invoiceProvider)),
                      ] else if (_searchText.isNotEmpty) ...[
                        _buildEmptyState(context),
                      ],

                      const SizedBox(height: 32),

                      // Cart & Checkout Section
                      _buildCartSection(context, invoiceProvider),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCustomerSelector(
    BuildContext context,
    CustomerProvider customerProvider,
    InvoiceProvider invoiceProvider,
  ) {
    final theme = Theme.of(context);
    final customers = customerProvider.customers;
    final selected = invoiceProvider.selectedCustomer;
    final isInterState = invoiceProvider.cartTotals.isInterState;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.person_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Customer Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isInterState ? Colors.purple : theme.colorScheme.primary)
                      .withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isInterState ? 'IGST' : 'CGST+SGST',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isInterState ? Colors.purple : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<CustomerModel?>(
            value: selected,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down),
            decoration: const InputDecoration(
              labelText: 'Select Customer',
              prefixIcon: Icon(Icons.account_circle_outlined),
            ),
            items: [
              const DropdownMenuItem<CustomerModel?>(
                value: null,
                child: Text('Walk-in Customer (B2C)'),
              ),
              ...customers.map(
                (customer) => DropdownMenuItem<CustomerModel?>(
                  value: customer,
                  child: Text(
                    '${customer.name} • ${customer.phone ?? "No phone"}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              invoiceProvider.selectCustomer(value);
            },
          ),
          if (selected != null && selected.gstin != null && selected.gstin!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.verified_user_outlined, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'GSTIN: ${selected.gstin} (State: ${selected.gstStateCode ?? "N/A"})',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductTile(
    BuildContext context,
    ProductModel product,
    InvoiceProvider invoiceProvider,
  ) {
    final theme = Theme.of(context);
    final isAvailable = product.stockQuantity > 0;
    final inCart = invoiceProvider.cart
        .where((c) => c.product.productId == product.productId)
        .firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          onTap: isAvailable ? () => invoiceProvider.addToCart(product) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isAvailable ? theme.colorScheme.primary.withAlpha(20) : Colors.grey.withAlpha(50),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    product.productName.substring(0, 1).toUpperCase(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isAvailable ? theme.colorScheme.primary : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${product.sellingPrice.toStringAsFixed(2)} • GST ${product.gstPercentage}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Stock: ${product.stockQuantity} ${product.unit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isAvailable ? Colors.grey[500] : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                if (inCart != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${inCart.quantity} in Cart',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  IconButton.filledTonal(
                    onPressed: isAvailable ? () => invoiceProvider.addToCart(product) : null,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: isAvailable ? theme.colorScheme.primary.withAlpha(20) : Colors.grey.withAlpha(20),
                      foregroundColor: isAvailable ? theme.colorScheme.primary : Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartSection(BuildContext context, InvoiceProvider invoiceProvider) {
    final theme = Theme.of(context);
    final cartItems = invoiceProvider.cart;
    final totals = invoiceProvider.cartTotals;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_cart_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Order Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (cartItems.isNotEmpty)
                TextButton(
                  onPressed: invoiceProvider.clearCart,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (cartItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.shopping_basket_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'Your cart is empty',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ...cartItems.map((item) => _buildCartRow(context, item, invoiceProvider)),
            const SizedBox(height: 24),

            // Tax breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildTotalsRow(context, 'Subtotal (Taxable Amount)', totals.subtotal),
                  const SizedBox(height: 8),
                  if (!totals.isInterState) ...[
                    _buildTotalsRow(context, 'CGST', totals.cgst),
                    const SizedBox(height: 8),
                    _buildTotalsRow(context, 'SGST', totals.sgst),
                  ] else ...[
                    _buildTotalsRow(context, 'IGST', totals.igst),
                  ],
                  const SizedBox(height: 8),
                  _buildTotalsRow(context, 'Total Tax', totals.totalGst),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  _buildTotalsRow(context, 'Grand Total', totals.grandTotal, isGrandTotal: true),
                ],
              ),
            ),
          ],

          if (invoiceProvider.createError != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        invoiceProvider.createError!,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Checkout Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: invoiceProvider.canCheckout
                  ? () => _confirmAndCompleteSale(context, invoiceProvider)
                  : null,
              icon: invoiceProvider.isCreatingInvoice
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              label: Text(
                invoiceProvider.isCreatingInvoice
                    ? 'Processing...'
                    : 'Complete Sale (₹${totals.grandTotal.toStringAsFixed(2)})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndCompleteSale(
    BuildContext context,
    InvoiceProvider invoiceProvider,
  ) async {
    final totals = invoiceProvider.cartTotals;
    final customer = invoiceProvider.selectedCustomer;

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Sale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${customer?.name ?? "Walk-in Customer"}'),
            if (customer?.gstin != null && customer!.gstin!.isNotEmpty)
              Text('GSTIN: ${customer.gstin}'),
            const SizedBox(height: 8),
            Text('Total Items: ${invoiceProvider.cart.length}'),
            Text('Payment Method: Cash'),
            Text('Tax Regime: ${totals.isInterState ? "IGST (Inter-State)" : "CGST + SGST (Intra-State)"}'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Amount Payable:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '₹${totals.grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm & Print'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final success = await invoiceProvider.createInvoice();
    if (!mounted) return;

    if (success) {
      final lastInvoice = invoiceProvider.lastInvoice;
      if (lastInvoice != null) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => InvoiceDetailScreen(invoice: lastInvoice),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Sale completed successfully.'), backgroundColor: Colors.green),
        );
      }
    } else {
      final error = invoiceProvider.createError ?? 'Checkout failed.';
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildCartRow(BuildContext context, CartItem item, InvoiceProvider invoiceProvider) {
    final theme = Theme.of(context);
    final product = item.product;
    final quantity = item.quantity;
    final lineTotal = item.taxableAmount + item.gstAmount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${product.sellingPrice.toStringAsFixed(2)} (GST ${product.gstPercentage}%)',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: quantity > 1
                      ? () => invoiceProvider.setQuantity(
                          product.productId, quantity - 1)
                      : () => invoiceProvider.removeFromCart(product.productId),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Icon(Icons.remove, size: 16, color: theme.textTheme.bodySmall?.color),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$quantity',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                InkWell(
                  onTap: quantity < product.stockQuantity
                      ? () => invoiceProvider.setQuantity(
                          product.productId, quantity + 1)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Icon(Icons.add, size: 16, color: quantity < product.stockQuantity ? theme.colorScheme.primary : Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: Text(
              '₹${lineTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsRow(BuildContext context, String label, double value, {bool isGrandTotal = false}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isGrandTotal ? 16 : 14,
            fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.w500,
            color: isGrandTotal ? theme.colorScheme.onSurface : theme.textTheme.bodySmall?.color,
          ),
        ),
        Text(
          '₹${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.w600,
            fontSize: isGrandTotal ? 18 : 14,
            color: isGrandTotal ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(BuildContext context, String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No matching products found',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
