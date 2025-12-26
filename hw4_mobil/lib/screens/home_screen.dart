import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../widgets/product_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _barcodeSearch = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _barcodeSearch.dispose();
    super.dispose();
  }

  Future<void> _openForm({Product? product, String? initialBarcode}) async {
    await showDialog(
      context: context,
      builder: (_) => ProductForm(product: product, initialBarcode: initialBarcode),
    );
  }

  Future<void> _confirmDelete(Product product) async {
    final provider = context.read<ProductProvider>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Delete product with barcode "${product.barcodeNo}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
          ],
        );
      },
    );

    if (ok == true) {
      await provider.deleteProduct(product.barcodeNo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted')),
        );
      }
    }
  }

  Future<void> _search() async {
    final provider = context.read<ProductProvider>();
    final barcode = _barcodeSearch.text.trim();

    if (barcode.isEmpty) {
      provider.showAll();
      return;
    }

    final found = await provider.searchByBarcode(barcode);
    if (found != null) return;

    if (!mounted) return;

    final add = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Product Not Found'),
          content: const Text('Product not found. Would you like to add a new product?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
          ],
        );
      },
    );

    if (add == true) {
      await _openForm(initialBarcode: barcode);
    } else {
      provider.showAll();
    }
  }

  DataTable _buildTable(List<Product> products) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Barcode')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Category')),
        DataColumn(label: Text('Unit Price')),
        DataColumn(label: Text('Tax')),
        DataColumn(label: Text('Price')),
        DataColumn(label: Text('Stock')),
        DataColumn(label: Text('Actions')),
      ],
      rows: products.map((p) {
        return DataRow(
          cells: [
            DataCell(Text(p.barcodeNo)),
            DataCell(Text(p.productName)),
            DataCell(Text(p.category)),
            DataCell(Text(p.unitPrice.toStringAsFixed(2))),
            DataCell(Text('${p.taxRate}%')),
            DataCell(Text(p.price.toStringAsFixed(2))),
            DataCell(Text(p.stockInfo?.toString() ?? '-')),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit),
                    onPressed: () => _openForm(product: p),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmDelete(p),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Product App'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ProductProvider>().loadProducts(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          final products = provider.products;

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _barcodeSearch,
                        decoration: const InputDecoration(
                          labelText: 'Barcode',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _search,
                        icon: const Icon(Icons.search),
                        label: const Text('Search'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          _barcodeSearch.clear();
                          provider.showAll();
                        },
                        child: const Text('Show All'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: products.isEmpty
                      ? const Center(child: Text('No products found'))
                      : SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _buildTable(products),
                          ),
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
