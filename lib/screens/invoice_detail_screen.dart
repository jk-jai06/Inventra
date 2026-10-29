import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/invoice_model.dart';

class InvoiceDetailScreen extends StatelessWidget {
  const InvoiceDetailScreen({super.key, required this.invoice});

  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final created =
        DateFormat('dd MMM yyyy, hh:mm a').format(invoice.createdAt);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Invoice Preview',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Share / Print Receipt',
            icon: Icon(Icons.share_outlined, color: theme.colorScheme.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Invoice ${invoice.invoiceNumber} receipt prepared for printing/sharing.'),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header
          _buildSectionCard(
            context,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    invoice.invoiceNumber,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      invoice.paymentStatus.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildHeaderRow(context, 'Date & Time', created),
              const SizedBox(height: 8),
              _buildHeaderRow(context, 'Payment Mode', invoice.paymentMethod.toUpperCase()),
              const SizedBox(height: 8),
              _buildHeaderRow(context, 'Tax Type',
                  invoice.isInterState ? 'IGST (Inter-State)' : 'CGST + SGST (Intra-State)'),
            ],
          ),
          const SizedBox(height: 16),

          // Customer Card
          _buildSectionCard(
            context,
            title: 'Customer Details',
            children: [
              Text(
                invoice.customerName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (invoice.customerPhone != null &&
                  invoice.customerPhone!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 16, color: theme.textTheme.bodySmall?.color),
                    const SizedBox(width: 8),
                    Text(invoice.customerPhone!, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ],
              if (invoice.customerGstin != null &&
                  invoice.customerGstin!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.verified_user_outlined, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'GSTIN: ${invoice.customerGstin}',
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Line items
          _buildSectionCard(
            context,
            title: 'Invoice Items (${invoice.items.length})',
            children: [
              ...invoice.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.productName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '₹${item.total.toStringAsFixed(2)}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Qty: ${item.quantity} × ₹${item.unitPrice.toStringAsFixed(2)}',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              'Tax: ₹${item.gstAmount.toStringAsFixed(2)} (${item.gstPercentage}%)',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                      ],
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 16),

          // Totals summary
          _buildSectionCard(
            context,
            title: 'Tax & Payment Breakdown',
            children: [
              _buildHeaderRow(context, 
                  'Subtotal (Taxable)', '₹${invoice.subtotal.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              if (!invoice.isInterState) ...[
                _buildHeaderRow(context, 'CGST', '₹${invoice.cgst.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _buildHeaderRow(context, 'SGST', '₹${invoice.sgst.toStringAsFixed(2)}'),
              ] else ...[
                _buildHeaderRow(context, 'IGST', '₹${invoice.igst.toStringAsFixed(2)}'),
              ],
              const SizedBox(height: 8),
              _buildHeaderRow(context, 
                  'Total Tax', '₹${invoice.totalGst.toStringAsFixed(2)}'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),
              _buildHeaderRow(context, 
                'Grand Total',
                '₹${invoice.grandTotal.toStringAsFixed(2)}',
                isTotal: true,
              ),
            ],
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(Icons.home_outlined),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              label: const Text('Back to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {String? title, required List<Widget> children}) {
    final theme = Theme.of(context);
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
          if (title != null) ...[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context, String label, String value, {bool isTotal = false}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? theme.colorScheme.onSurface : theme.textTheme.bodySmall?.color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            fontSize: isTotal ? 18 : 14,
            color: isTotal ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
