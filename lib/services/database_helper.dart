import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'kasir_seafood.db');

    return await openDatabase(
      path,
      version: 8,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        resto_name TEXT,
        resto_logo TEXT,
        resto_address TEXT,
        receipt_message TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        table_number TEXT,
        notes TEXT,
        guest_count INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE menu (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        price_base REAL,
        price_sell REAL NOT NULL,
        is_available INTEGER NOT NULL DEFAULT 1,
        weight_unit TEXT,
        image TEXT,
        category_id INTEGER,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        payment_method TEXT,
        total_amount REAL,
        order_status TEXT NOT NULL,
        order_time TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        menu_id INTEGER NOT NULL,
        menu_name TEXT, 
        quantity REAL NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id),
        FOREIGN KEY (menu_id) REFERENCES menu(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await db.execute("ALTER TABLE order_items ADD COLUMN menuName TEXT;");
    }
    if (oldVersion < 6) {
      await db.execute("ALTER TABLE categories ADD COLUMN orderPosition INTEGER;");
      await db.execute("ALTER TABLE categories ADD COLUMN createdAt TEXT;");
      await db.execute("ALTER TABLE categories ADD COLUMN updatedAt TEXT;");
    }
    if (oldVersion < 7) {
      await db.execute("ALTER TABLE orders ADD COLUMN paid_amount REAL;");
      await db.execute("ALTER TABLE orders ADD COLUMN change_amount REAL;");
    }
    if (oldVersion < 8) {
      await db.execute("ALTER TABLE settings ADD COLUMN resto_phone TEXT;");
      await db.execute("ALTER TABLE settings ADD COLUMN resto_phone2 TEXT;");
    }
  }
}
