import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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
    final path = join(await getDatabasesPath(), 'medicines.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE medicines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            dosage TEXT,
            frequency TEXT,
            time TEXT,
            notes TEXT
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
            createdAt TEXT
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
      },
    );
  }

  // ➕ Insert
  Future<int> insertMedicine(Medicine medicine) async {
    final db = await database;
    return db.insert('medicines', medicine.toMap());
  }

  // 📄 Read
  Future<List<Medicine>> getMedicines() async {
    final db = await database;
    final result = await db.query('medicines');
    return result
        .map((e) => Medicine(
              id: e['id'] as int,
              name: e['name'] as String,
              dosage: e['dosage'] as String,
              frequency: e['frequency'] as String,
              time: e['time'] as String,
              notes: e['notes'] as String,
            ))
        .toList();
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
  Future<List<Reminder>> getReminders() async {
    final db = await database;
    final result = await db.query(
      'reminders',
      orderBy: 'reminderDate DESC, reminderTime DESC',
    );
    return result.map((e) => Reminder.fromMap(e)).toList();
  }

  // 📄 Get Reminders by Date
  Future<List<Reminder>> getRemindersByDate(String date) async {
    final db = await database;
    final result = await db.query(
      'reminders',
      where: 'reminderDate = ?',
      whereArgs: [date],
      orderBy: 'reminderTime ASC',
    );
    return result.map((e) => Reminder.fromMap(e)).toList();
  }

  // 📄 Get Reminders by Medicine
  Future<List<Reminder>> getRemindersByMedicine(String medicineId) async {
    final db = await database;
    final result = await db.query(
      'reminders',
      where: 'medicineId = ?',
      whereArgs: [medicineId],
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
  Future<List<Reminder>> getUpcomingReminders() async {
    final db = await database;
    final today = DateTime.now();
    final nextWeek = today.add(const Duration(days: 7));

    final result = await db.query(
      'reminders',
      where: 'reminderDate BETWEEN ? AND ?',
      whereArgs: [
        today.toString().split(' ')[0],
        nextWeek.toString().split(' ')[0],
      ],
      orderBy: 'reminderDate ASC, reminderTime ASC',
    );
    return result.map((e) => Reminder.fromMap(e)).toList();
  }
}
