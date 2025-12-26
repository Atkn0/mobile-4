import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';

class ProductForm extends StatefulWidget {
  final Product? product;
  final String? initialBarcode;

  const ProductForm({super.key, this.product, this.initialBarcode});

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _barcode;
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _unitPrice;
  late final TextEditingController _taxRate;
  late final TextEditingController _price;
  late final TextEditingController _stockInfo;

  @override
  void initState() {
    super.initState();

    final p = widget.product;
    _barcode = TextEditingController(text: p?.barcodeNo ?? widget.initialBarcode ?? '');
    _name = TextEditingController(text: p?.productName ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _unitPrice = TextEditingController(text: p == null ? '' : p.unitPrice.toStringAsFixed(2));
    _taxRate = TextEditingController(text: p == null ? '' : p.taxRate.toString());
    _price = TextEditingController(text: p == null ? '' : p.price.toStringAsFixed(2));
    _stockInfo = TextEditingController(text: p?.stockInfo?.toString() ?? '');

    _unitPrice.addListener(_recalculatePrice);
    _taxRate.addListener(_recalculatePrice);
  }

  @override
  void dispose() {
    _unitPrice.removeListener(_recalculatePrice);
    _taxRate.removeListener(_recalculatePrice);

    _barcode.dispose();
    _name.dispose();
    _category.dispose();
    _unitPrice.dispose();
    _taxRate.dispose();
    _price.dispose();
    _stockInfo.dispose();
    super.dispose();
  }

  void _recalculatePrice() {
    final unit = double.tryParse(_unitPrice.text.replaceAll(',', '.'));
    final tax = int.tryParse(_taxRate.text);
    if (unit == null || tax == null) return;
    if (unit < 0 || tax < 0) return;

    final computed = unit * (1 + (tax / 100));
    final txt = computed.toStringAsFixed(2);
    if (_price.text != txt) {
      _price.text = txt;
    }
  }

  String? _requiredText(String? v, String message) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return message;
    return null;
  }

  String? _requiredNonNegativeDouble(String? v, String message) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return message;
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) return 'Please enter a valid number';
    if (parsed < 0) return 'Value cannot be negative';
    return null;
  }

  String? _requiredNonNegativeInt(String? v, String message) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return message;
    final parsed = int.tryParse(value);
    if (parsed == null) return 'Please enter a valid integer';
    if (parsed < 0) return 'Value cannot be negative';
    return null;
  }

  String? _optionalNonNegativeInt(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return null;
    final parsed = int.tryParse(value);
    if (parsed == null) return 'Please enter a valid integer';
    if (parsed < 0) return 'Value cannot be negative';
    return null;
  }

  Future<void> _save() async {
    final provider = context.read<ProductProvider>();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final barcodeNo = _barcode.text.trim();
    final unit = double.parse(_unitPrice.text.trim().replaceAll(',', '.'));
    final tax = int.parse(_taxRate.text.trim());
    final price = double.parse(_price.text.trim().replaceAll(',', '.'));

    final stockText = _stockInfo.text.trim();
    final stock = stockText.isEmpty ? null : int.parse(stockText);

    final product = Product(
      barcodeNo: barcodeNo,
      productName: _name.text.trim(),
      category: _category.text.trim(),
      unitPrice: unit,
      taxRate: tax,
      price: price,
      stockInfo: stock,
    );

    try {
      if (widget.product == null) {
        await provider.addProduct(product);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully')),
          );
        }
      } else {
        await provider.updateProduct(product);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully')),
          );
        }
      }
    } on DatabaseException catch (e) {
      final msg = (e.isUniqueConstraintError())
          ? 'This barcode already exists'
          : 'Database error occurred';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Product' : 'Add Product'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _barcode,
                  decoration: const InputDecoration(labelText: 'Barcode No'),
                  enabled: !isEdit,
                  validator: (v) => _requiredText(v, 'Barcode is required'),
                ),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  validator: (v) => _requiredText(v, 'Product name is required'),
                ),
                TextFormField(
                  controller: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  validator: (v) => _requiredText(v, 'Category is required'),
                ),
                TextFormField(
                  controller: _unitPrice,
                  decoration: const InputDecoration(labelText: 'Unit Price'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => _requiredNonNegativeDouble(v, 'Unit price is required'),
                ),
                TextFormField(
                  controller: _taxRate,
                  decoration: const InputDecoration(labelText: 'Tax Rate (%)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => _requiredNonNegativeInt(v, 'Tax rate is required'),
                ),
                TextFormField(
                  controller: _price,
                  decoration: const InputDecoration(labelText: 'Price (auto)'),
                  readOnly: true,
                  validator: (v) => _requiredNonNegativeDouble(v, 'Price is required'),
                ),
                TextFormField(
                  controller: _stockInfo,
                  decoration: const InputDecoration(labelText: 'Stock Info (optional)'),
                  keyboardType: TextInputType.number,
                  validator: _optionalNonNegativeInt,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
