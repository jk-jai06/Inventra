import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/validators.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';

class ProductAddEditScreen extends StatefulWidget {
  final ProductModel? productToEdit;

  const ProductAddEditScreen({super.key, this.productToEdit});

  @override
  State<ProductAddEditScreen> createState() => _ProductAddEditScreenState();
}

class _ProductAddEditScreenState extends State<ProductAddEditScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _purchasePriceCtrl;
  late final TextEditingController _sellingPriceCtrl;
  late final TextEditingController _gstCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _minStockCtrl;
  String _unit = 'Units';

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final product = widget.productToEdit;

    _nameCtrl = TextEditingController(text: product?.productName ?? '');
    _skuCtrl = TextEditingController(text: product?.sku ?? '');
    _categoryCtrl = TextEditingController(text: product?.category ?? '');
    _descriptionCtrl = TextEditingController(text: product?.description ?? '');
    _barcodeCtrl = TextEditingController(text: product?.barcode ?? '');
    _purchasePriceCtrl =
        TextEditingController(text: product != null ? product.purchasePrice.toString() : '');
    _sellingPriceCtrl =
        TextEditingController(text: product != null ? product.sellingPrice.toString() : '');
    _gstCtrl =
        TextEditingController(text: product?.gstPercentage.toString() ?? '18');
    _stockCtrl =
        TextEditingController(text: product?.stockQuantity.toString() ?? '0');
    _minStockCtrl = TextEditingController(
        text: product?.minimumStockLevel.toString() ?? '5');
    _unit = product?.unit ?? 'Units';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _categoryCtrl.dispose();
    _descriptionCtrl.dispose();
    _barcodeCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _gstCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final product = ProductModel(
        productId: widget.productToEdit?.productId ?? '',
        productName: _nameCtrl.text.trim(),
        sku: _skuCtrl.text.trim().toUpperCase(),
        category: _categoryCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        barcode:
            _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
        purchasePrice: double.parse(_purchasePriceCtrl.text.trim()),
        sellingPrice: double.parse(_sellingPriceCtrl.text.trim()),
        gstPercentage: double.parse(
            _gstCtrl.text.trim().isEmpty ? '0' : _gstCtrl.text.trim()),
        stockQuantity: int.parse(_stockCtrl.text.trim()),
        minimumStockLevel: int.parse(_minStockCtrl.text.trim()),
        unit: _unit,
        createdAt: widget.productToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final provider = context.read<ProductProvider>();
      final success = widget.productToEdit == null
          ? await provider.addProduct(product)
          : await provider.updateProduct(product);

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.productToEdit == null
                  ? 'Product added successfully'
                  : 'Product updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to save product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.productToEdit != null;

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
          isEditing ? 'Edit Product' : 'Add Product',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info
              _buildSectionHeader(context, 'Basic Information'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                validator: AppValidators.productName,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  hintText: 'e.g., Basmati Rice 1kg',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skuCtrl,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'SKU (Optional)',
                        hintText: 'e.g. RICE-01',
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _categoryCtrl,
                      validator: (v) =>
                          AppValidators.required(v, fieldName: 'Category'),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        hintText: 'e.g., Grocery',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 2,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Product details or notes',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 32),

              // Pricing
              _buildSectionHeader(context, 'Pricing & GST'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceCtrl,
                      validator: (v) => AppValidators.positiveNumber(v,
                          fieldName: 'Purchase price'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Purchase Price (₹) *',
                        hintText: '0.00',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceCtrl,
                      validator: AppValidators.sellingPrice,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price (₹) *',
                        hintText: '0.00',
                        prefixIcon: Icon(Icons.sell_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gstCtrl,
                validator: AppValidators.gstPercent,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'GST Rate % *',
                  hintText: '0, 5, 12, 18, 28',
                  prefixIcon: Icon(Icons.percent),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['0', '5', '12', '18', '28'].map((rate) {
                  final isSelected = _gstCtrl.text.trim() == rate;
                  return ChoiceChip(
                    label: Text('$rate%'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _gstCtrl.text = rate;
                        });
                      }
                    },
                    backgroundColor: theme.colorScheme.surface,
                    selectedColor: theme.colorScheme.primary.withAlpha(20),
                    labelStyle: TextStyle(
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Inventory
              _buildSectionHeader(context, 'Stock details'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      validator: AppValidators.stockQuantity,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Current Stock *',
                        hintText: '0',
                        prefixIcon: Icon(Icons.warehouse_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _unit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: const [
                        DropdownMenuItem(value: 'Units', child: Text('Units')),
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                        DropdownMenuItem(value: 'g', child: Text('g')),
                        DropdownMenuItem(value: 'L', child: Text('L')),
                        DropdownMenuItem(value: 'ml', child: Text('ml')),
                        DropdownMenuItem(value: 'Box', child: Text('Box')),
                        DropdownMenuItem(value: 'Pack', child: Text('Pack')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _unit = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minStockCtrl,
                      validator: (v) => AppValidators.positiveNumber(v,
                          fieldName: 'Minimum stock level'),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Min Stock Alert',
                        hintText: '5',
                        prefixIcon: Icon(Icons.low_priority),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeCtrl,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Barcode',
                        hintText: 'Optional',
                        prefixIcon: Icon(Icons.barcode_reader),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEditing ? 'Update Product' : 'Save Product',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }
}
