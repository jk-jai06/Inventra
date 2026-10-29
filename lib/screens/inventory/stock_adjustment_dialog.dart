import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';

class StockAdjustmentDialog extends StatefulWidget {
  final ProductModel product;

  const StockAdjustmentDialog({super.key, required this.product});

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  String _movementType = 'purchase'; // 'purchase' (IN), 'adjustment' (IN/OUT), 'wastage' (OUT)
  bool _isAddition = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final enteredQty = int.parse(_qtyCtrl.text.trim());
    final delta = _isAddition ? enteredQty : -enteredQty;
    final newStock = widget.product.stockQuantity + delta;

    if (newStock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Cannot reduce stock below 0. Current stock: ${widget.product.stockQuantity}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirmation Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Stock Adjustment'),
        content: Text(
          'Adjust stock for "${widget.product.productName}"?\n\n'
          'Current Stock: ${widget.product.stockQuantity}\n'
          'Change: ${delta > 0 ? "+$delta" : "$delta"}\n'
          'New Stock: $newStock units\n'
          'Reason: $_movementType\n'
          '${_notesCtrl.text.trim().isNotEmpty ? "Notes: ${_notesCtrl.text.trim()}" : ""}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProductProvider>();

    setState(() => _isLoading = true);

    final error = await provider.adjustStock(
      widget.product.productId,
      delta,
      movementType: _movementType,
      notes: _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      navigator.pop(true);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
              'Stock adjusted successfully for "${widget.product.productName}".'),
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stock Adjustment',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  widget.product.productName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Stock:'),
                      Text(
                        '${widget.product.stockQuantity} ${widget.product.unit}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Adjustment Type Selector
                DropdownButtonFormField<String>(
                  value: _movementType,
                  decoration: const InputDecoration(labelText: 'Adjustment Reason'),
                  items: const [
                    DropdownMenuItem(
                      value: 'purchase',
                      child: Text('Stock In (Purchase / Restock)'),
                    ),
                    DropdownMenuItem(
                      value: 'adjustment',
                      child: Text('Manual Adjustment (Correction)'),
                    ),
                    DropdownMenuItem(
                      value: 'wastage',
                      child: Text('Stock Out (Damaged / Expired / Loss)'),
                    ),
                    DropdownMenuItem(
                      value: 'return',
                      child: Text('Customer Return'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _movementType = val;
                      if (val == 'purchase' || val == 'return') {
                        _isAddition = true;
                      } else if (val == 'wastage') {
                        _isAddition = false;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Direction Toggle (for manual adjustment)
                if (_movementType == 'adjustment')
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('+ Add Stock')),
                          selected: _isAddition,
                          selectedColor: Colors.green.withValues(alpha: 0.2),
                          onSelected: (val) => setState(() => _isAddition = true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('- Deduct Stock')),
                          selected: !_isAddition,
                          selectedColor: Colors.red.withValues(alpha: 0.2),
                          onSelected: (val) => setState(() => _isAddition = false),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),

                // Quantity Input
                TextFormField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter quantity';
                    }
                    final n = int.tryParse(v.trim());
                    if (n == null || n <= 0) {
                      return 'Must be greater than 0';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: _isAddition ? 'Units to Add *' : 'Units to Deduct *',
                    prefixIcon: Icon(
                      _isAddition ? Icons.add_circle_outline : Icons.remove_circle_outline,
                      color: _isAddition ? Colors.green : Colors.red,
                    ),
                    hintText: 'e.g. 10',
                  ),
                ),
                const SizedBox(height: 12),

                // Notes Input
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Reason (Optional)',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                    hintText: 'e.g. Batch #102 received from distributor',
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Stock'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
