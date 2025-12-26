import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('products.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ProductTable (
        barcodeNo TEXT PRIMARY KEY,
        productName TEXT NOT NULL,
        category TEXT NOT NULL,
        unitPrice REAL NOT NULL,
        taxRate INTEGER NOT NULL,
        price REAL NOT NULL,
        stockInfo INTEGER
      )
    ''');
  }

  Future<Product?> getProductByBarcode(String barcodeNo) async {
    final db = await instance.database;
    final rows = await db.query(
      'ProductTable',
      where: 'barcodeNo = ?',
      whereArgs: [barcodeNo],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('ProductTable', orderBy: 'productName ASC');
    return result.map((e) => Product.fromMap(e)).toList();
  }

  Future<void> insertProduct(Product product) async {
    final db = await instance.database;
    await db.insert(
      'ProductTable',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> updateProduct(Product product) async {
    final db = await instance.database;
    await db.update(
      'ProductTable',
      product.toMap(),
      where: 'barcodeNo = ?',
      whereArgs: [product.barcodeNo],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> deleteProduct(String barcodeNo) async {
    final db = await instance.database;
    await db.delete(
      'ProductTable',
      where: 'barcodeNo = ?',
      whereArgs: [barcodeNo],
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
