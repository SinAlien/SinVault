// database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/car.dart';
import '../models/service_record.dart';
import '../models/house.dart';
import '../models/house_contract.dart';

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
    String path = join(await getDatabasesPath(), 'sinvault_database.db');
    return await openDatabase(
      path,
      version: 3, // <-- این عدد را به 3 تغییر دادم
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // <-- اضافه کردن onUpgrade
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // جدول Cars
    await db.execute('''
      CREATE TABLE cars(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner TEXT NOT NULL,
        brand TEXT NOT NULL,
        model TEXT NOT NULL
      )
    ''');
    // جدول ServiceRecords
    // تغییر kilometer از INTEGER به TEXT
    await db.execute('''
      CREATE TABLE service_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        carId INTEGER NOT NULL,
        date TEXT NOT NULL,
        kilometer TEXT NOT NULL, -- تغییر نوع به TEXT
        operation TEXT NOT NULL,
        FOREIGN KEY (carId) REFERENCES cars (id) ON DELETE CASCADE
      )
    ''');
    // جدول Houses
    await db.execute('''
      CREATE TABLE houses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner TEXT NOT NULL,
        address TEXT NOT NULL,
        city TEXT NOT NULL
      )
    ''');
    // جدول HouseContracts
    // تغییر annualRent از REAL به TEXT
    await db.execute('''
      CREATE TABLE house_contracts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        houseId INTEGER NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        annualRent TEXT NOT NULL, -- تغییر نوع به TEXT
        additionalFields TEXT, -- برای ذخیره Map به صورت String (مثل 'key1:value1;key2:value2')
        FOREIGN KEY (houseId) REFERENCES houses (id) ON DELETE CASCADE
      )
    ''');
  }

  // اضافه کردن تابع _onUpgrade برای مدیریت تغییرات در ساختار جدول
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // این بخش برای زمانی است که دیتابیس از نسخه قدیمی‌تر (مثلاً 1 یا 2) به نسخه 3 ارتقاء می‌یابد.
      // برای تغییر نوع ستون‌ها (مانند kilometer و annualRent) در SQLite، باید:
      // 1. یک جدول موقت جدید با ساختار صحیح ایجاد کنید.
      // 2. داده‌های موجود را از جدول قدیمی به جدول جدید کپی کنید.
      // 3. جدول قدیمی را حذف کنید.
      // 4. جدول جدید را به نام جدول اصلی تغییر نام دهید.

      // برای service_records
      await db.execute('CREATE TABLE service_records_new('
          'id INTEGER PRIMARY KEY AUTOINCREMENT,'
          'carId INTEGER NOT NULL,'
          'date TEXT NOT NULL,'
          'kilometer TEXT NOT NULL,' // نوع جدید
          'operation TEXT NOT NULL,'
          'FOREIGN KEY (carId) REFERENCES cars (id) ON DELETE CASCADE'
          ')');
      await db.execute('INSERT INTO service_records_new (id, carId, date, kilometer, operation) '
          'SELECT id, carId, date, CAST(kilometer AS TEXT), operation FROM service_records'); // تبدیل به TEXT
      await db.execute('DROP TABLE service_records');
      await db.execute('ALTER TABLE service_records_new RENAME TO service_records');

      // برای house_contracts
      await db.execute('CREATE TABLE house_contracts_new('
          'id INTEGER PRIMARY KEY AUTOINCREMENT,'
          'houseId INTEGER NOT NULL,'
          'startDate TEXT NOT NULL,'
          'endDate TEXT NOT NULL,'
          'annualRent TEXT NOT NULL,' // نوع جدید
          'additionalFields TEXT,'
          'FOREIGN KEY (houseId) REFERENCES houses (id) ON DELETE CASCADE'
          ')');
      await db.execute('INSERT INTO house_contracts_new (id, houseId, startDate, endDate, annualRent, additionalFields) '
          'SELECT id, houseId, startDate, endDate, CAST(annualRent AS TEXT), additionalFields FROM house_contracts'); // تبدیل به TEXT
      await db.execute('DROP TABLE house_contracts');
      await db.execute('ALTER TABLE house_contracts_new RENAME TO house_contracts');
    }
    // اگر در آینده نیاز به ارتقاء به نسخه‌های بالاتر داشتید، if (oldVersion < X) جدید اضافه کنید.
  }

  // --- عملیات مربوط به Cars ---
  Future<int> insertCar(Car car) async {
    Database db = await database;
    return await db.insert('cars', car.toMap());
  }

  Future<List<Car>> getCars() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('cars');
    return List.generate(maps.length, (i) {
      return Car.fromMap(maps[i]);
    });
  }

  Future<int> updateCar(Car car) async {
    Database db = await database;
    return await db.update(
      'cars',
      car.toMap(),
      where: 'id = ?',
      whereArgs: [car.id],
    );
  }

  Future<int> deleteCar(int id) async {
    Database db = await database;
    return await db.delete(
      'cars',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- عملیات مربوط به ServiceRecords ---
  Future<int> insertServiceRecord(ServiceRecord record) async {
    Database db = await database;
    return await db.insert('service_records', record.toMap());
  }

  Future<List<ServiceRecord>> getServiceRecordsForCar(int carId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'service_records',
      where: 'carId = ?',
      whereArgs: [carId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return ServiceRecord.fromMap(maps[i]);
    });
  }

  Future<int> updateServiceRecord(ServiceRecord record) async {
    Database db = await database;
    return await db.update(
      'service_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteServiceRecord(int id) async {
    Database db = await database;
    return await db.delete(
      'service_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- عملیات مربوط به Houses ---
  Future<int> insertHouse(House house) async {
    Database db = await database;
    return await db.insert('houses', house.toMap());
  }

  Future<List<House>> getHouses() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('houses');
    return List.generate(maps.length, (i) {
      return House.fromMap(maps[i]);
    });
  }

  Future<int> updateHouse(House house) async {
    Database db = await database;
    return await db.update(
      'houses',
      house.toMap(),
      where: 'id = ?',
      whereArgs: [house.id],
    );
  }

  Future<int> deleteHouse(int id) async {
    Database db = await database;
    return await db.delete(
      'houses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- عملیات مربوط به HouseContracts ---
  Future<int> insertHouseContract(HouseContract contract) async {
    Database db = await database;
    return await db.insert('house_contracts', contract.toMap());
  }

  Future<List<HouseContract>> getHouseContractsForHouse(int houseId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'house_contracts',
      where: 'houseId = ?',
      whereArgs: [houseId],
      orderBy: 'startDate DESC',
    );
    return List.generate(maps.length, (i) {
      return HouseContract.fromMap(maps[i]);
    });
  }

  Future<int> updateHouseContract(HouseContract contract) async {
    Database db = await database;
    return await db.update(
      'house_contracts',
      contract.toMap(),
      where: 'id = ?',
      whereArgs: [contract.id],
    );
  }

  Future<int> deleteHouseContract(int id) async {
    Database db = await database;
    return await db.delete(
      'house_contracts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}