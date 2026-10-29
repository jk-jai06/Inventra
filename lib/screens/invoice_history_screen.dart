import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/invoice_provider.dart';
import 'invoice_detail_screen.dart';

class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<InvoiceProvider>().startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<InvoiceProvider>().startListening(),
          ),
        ],
      ),
      body: Consumer<InvoiceProvider>(
        builder: (context, provider, _) {
          if (provider.historyLoading && provider.invoices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.historyError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 52, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.historyError!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.startListening(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.invoices.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No invoices yet. Complete a sale to create one.'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.invoices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final invoice = provider.invoices[index];
              final formattedDate =
                  DateFormat('dd MMM yyyy').format(invoice.createdAt);

              return Card(
                child: ListTile(
                  title: Text(invoice.invoiceNumber),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formattedDate),
                      Text(invoice.customerName),
                    ],
                  ),
                  trailing: Text(
                    '₹${invoice.grandTotal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InvoiceDetailScreen(invoice: invoice),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
