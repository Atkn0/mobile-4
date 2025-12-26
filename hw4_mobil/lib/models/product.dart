class Product {
  final String barcodeNo;
  final String productName;
  final String category;
  final double unitPrice;
  final int taxRate;
  final double price;
  final int? stockInfo;

  const Product({
    required this.barcodeNo,
    required this.productName,
    required this.category,
    required this.unitPrice,
    required this.taxRate,
    required this.price,
    this.stockInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'barcodeNo': barcodeNo,
      'productName': productName,
      'category': category,
      'unitPrice': unitPrice,
      'taxRate': taxRate,
      'price': price,
      'stockInfo': stockInfo,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      barcodeNo: (map['barcodeNo'] ?? '').toString(),
      productName: (map['productName'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      unitPrice: (map['unitPrice'] is int)
          ? (map['unitPrice'] as int).toDouble()
          : (map['unitPrice'] as num).toDouble(),
      taxRate: (map['taxRate'] as num).toInt(),
      price: (map['price'] is int)
          ? (map['price'] as int).toDouble()
          : (map['price'] as num).toDouble(),
      stockInfo: map['stockInfo'] == null ? null : (map['stockInfo'] as num).toInt(),
    );
  }

  Product copyWith({
    String? barcodeNo,
    String? productName,
    String? category,
    double? unitPrice,
    int? taxRate,
    double? price,
    int? stockInfo,
  }) {
    return Product(
      barcodeNo: barcodeNo ?? this.barcodeNo,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate ?? this.taxRate,
      price: price ?? this.price,
      stockInfo: stockInfo,
    );
  }
}
