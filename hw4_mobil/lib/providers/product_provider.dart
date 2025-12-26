import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _allProducts = [];
  List<Product> _visibleProducts = [];
  String? _selectedBarcode;

  List<Product> get products => _visibleProducts;
  String? get selectedBarcode => _selectedBarcode;

  Future<void> loadProducts() async {
    _allProducts = await DatabaseHelper.instance.getAllProducts();
    _visibleProducts = List<Product>.from(_allProducts);
    _selectedBarcode = null;
    notifyListeners();
  }

  Future<Product?> searchByBarcode(String barcodeNo) async {
    final trimmed = barcodeNo.trim();
    if (trimmed.isEmpty) {
      _visibleProducts = List<Product>.from(_allProducts);
      _selectedBarcode = null;
      notifyListeners();
      return null;
    }

    final product = await DatabaseHelper.instance.getProductByBarcode(trimmed);
    if (product == null) {
      return null;
    }

    _visibleProducts = [product];
    _selectedBarcode = product.barcodeNo;
    notifyListeners();
    return product;
  }

  void showAll() {
    _visibleProducts = List<Product>.from(_allProducts);
    _selectedBarcode = null;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    await DatabaseHelper.instance.insertProduct(product);
    await loadProducts();
    _selectedBarcode = product.barcodeNo;
    _visibleProducts = [product];
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    await DatabaseHelper.instance.updateProduct(product);
    await loadProducts();
    _selectedBarcode = product.barcodeNo;
    _visibleProducts = [product];
    notifyListeners();
  }

  Future<void> deleteProduct(String barcodeNo) async {
    await DatabaseHelper.instance.deleteProduct(barcodeNo);
    await loadProducts();
  }
}
