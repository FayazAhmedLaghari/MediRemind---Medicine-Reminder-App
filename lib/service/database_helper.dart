import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../models/medicine_model.dart';
import '../models/reminder_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    // Try normal DB path first, otherwise fallback to in-memory (useful on web)
    try {
      String path;
      if (kIsWeb) {
        // On web, just use the database name directly
        // sqflite_common_ffi_web stores data in IndexedDB
        path = 'medicines.db';
      } else {
        try {
          final dbPath = await getDatabasesPath();
          // If getDatabasesPath returns empty, fall back
          if (dbPath.isEmpty) {
            throw Exception('getDatabasesPath returned empty');
          }
          path = '$dbPath/medicines.db';
        } catch (e) {
          debugPrint(
              'Using in-memory database fallback because getDatabasesPath failed: $e');
          path = inMemoryDatabasePath;
        }
      }

      return await openDatabase(
        path,
        version: 4,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE medicines (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              dosage TEXT,
              frequency TEXT,
              time TEXT,
              notes TEXT,
              userId TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE reminders (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              medicineId TEXT,
              medicineName TEXT,
              reminderDate TEXT,
              reminderTime TEXT,
              dosage TEXT,
              status TEXT DEFAULT 'pending',
              notes TEXT,
              createdAt TEXT,
              userId TEXT,
              soundEnabled INTEGER DEFAULT 1,
              vibrationEnabled INTEGER DEFAULT 1
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('''
              CREATE TABLE reminders (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                medicineId TEXT,
                medicineName TEXT,
                reminderDate TEXT,
                reminderTime TEXT,
                dosage TEXT,
                status TEXT DEFAULT 'pending',
                notes TEXT,
                createdAt TEXT
              )
            ''');
          }
          if (oldVersion < 3) {
            // Add userId column to existing tables
            try {
              await db.execute('ALTER TABLE medicines ADD COLUMN userId TEXT');
            } catch (e) {
              debugPrint('medicines.userId already exists or error: $e');
            }
            try {
              await db.execute('ALTER TABLE reminders ADD COLUMN userId TEXT');
            } catch (e) {
              debugPrint('reminders.userId already exists or error: $e');
            }
          }
          if (oldVersion < 4) {
            // Add sound and vibration preference columns
            try {
              await db.execute(
                  'ALTER TABLE reminders ADD COLUMN soundEnabled INTEGER DEFAULT 1');
            } catch (e) {
              debugPrint('reminders.soundEnabled already exists or error: $e');
            }
            try {
              await db.execute(
                  'ALTER TABLE reminders ADD COLUMN vibrationEnabled INTEGER DEFAULT 1');
            } catch (e) {
              debugPrint(
                  'reminders.vibrationEnabled already exists or error: $e');
            }
          }
        },
      );
    } catch (e, st) {
      debugPrint('Fatal DB init failed, opening in-memory DB: $e\n$st');
      return await openDatabase(inMemoryDatabasePath, version: 4,
          onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE medicines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            dosage TEXT,
            frequency TEXT,
            time TEXT,
            notes TEXT,
            userId TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            medicineId TEXT,
            medicineName TEXT,
            reminderDate TEXT,
            reminderTime TEXT,
            dosage TEXT,
            status TEXT DEFAULT 'pending',
            notes TEXT,
            createdAt TEXT,
            userId TEXT,
            soundEnabled INTEGER DEFAULT 1,
            vibrationEnabled INTEGER DEFAULT 1
          )
        ''');
      });
    }
  }

  // ➕ Insert
  Future<int> insertMedicine(Medicine medicine) async {
    final db = await database;
    return db.insert('medicines', medicine.toMap());
  }

  // 📄 Read
  Future<List<Medicine>> getMedicines(String userId) async {
    final db = await database;
    final result = await db.query(
      'medicines',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return result.map((e) => Medicine.fromMap(e)).toList();
  }

  // ✏️ Update
  Future<int> updateMedicine(Medicine medicine) async {
    final db = await database;
    return db.update(
      'medicines',
      medicine.toMap(),
      where: 'id = ?',
      whereArgs: [medicine.id],
    );
  }

  // ❌ Delete
  Future<int> deleteMedicine(int id) async {
    final db = await database;
    return db.delete(
      'medicines',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== REMINDERS ==========

  // ➕ Insert Reminder
  Future<int> insertReminder(Reminder reminder) async {
    final db = await database;
    return db.insert('reminders', reminder.toMap());
  }

  // 📄 Read All Reminders
  Future<List<Reminder>> getReminders(String userId) async {
    try {
      final db = await database;
      final result = await db.query(
        'reminders',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'reminderDate DESC, reminderTime DESC',
      );
      return result.map((e) => Reminder.fromMap(e)).toList();
    } catch (e, st) {
      debugPrint('getReminders failed: $e\n$st');
      return [];
    }
  }

  // 📄 Get Reminders by Date
  Future<List<Reminder>> getRemindersByDate(String date, String userId) async {
    try {
      final db = await database;
      final result = await db.query(
        'reminders',
        where: 'reminderDate = ? AND userId = ?',
        whereArgs: [date, userId],
        orderBy: 'reminderTime ASC',
      );
      return result.map((e) => Reminder.fromMap(e)).toList();
    } catch (e, st) {
      debugPrint('getRemindersByDate failed: $e\n$st');
      return [];
    }
  }

  // 📄 Get Reminders by Medicine
  Future<List<Reminder>> getRemindersByMedicine(
      String medicineId, String userId) async {
    final db = await database;
    final result = await db.query(
      'reminders',
      where: 'medicineId = ? AND userId = ?',
      whereArgs: [medicineId, userId],
      orderBy: 'reminderDate DESC',
    );
    return result.map((e) => Reminder.fromMap(e)).toList();
  }

  // ✏️ Update Reminder
  Future<int> updateReminder(Reminder reminder) async {
    final db = await database;
    return db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  // ❌ Delete Reminder
  Future<int> deleteReminder(int id) async {
    final db = await database;
    return db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 🔍 Get Upcoming Reminders (next 7 days)
  Future<List<Reminder>> getUpcomingReminders(String userId) async {
    try {
      final db = await database;
      final today = DateTime.now();
      final nextWeek = today.add(const Duration(days: 7));

      final result = await db.query(
        'reminders',
        where: 'reminderDate BETWEEN ? AND ? AND userId = ?',
        whereArgs: [
          today.toString().split(' ')[0],
          nextWeek.toString().split(' ')[0],
          userId,
        ],
        orderBy: 'reminderDate ASC, reminderTime ASC',
      );
      return result.map((e) => Reminder.fromMap(e)).toList();
    } catch (e, st) {
      debugPrint('getUpcomingReminders failed: $e\n$st');
      return [];
    }
  }
}
