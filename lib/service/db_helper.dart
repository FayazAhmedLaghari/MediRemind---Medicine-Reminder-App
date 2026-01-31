// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// import 'package:path/path.dart';

// class DBHelper {
//   static Database? _db;

//   static Future<Database> get database async {
//     if (_db != null) return _db!;
//     _db = await _initDB();
//     return _db!;
//   }

//   static Future<Database> _initDB() async {
//     final dbPath = await databaseFactory.getDatabasesPath();
//     final path = join(dbPath, 'medicine.db');

//     return await databaseFactory.openDatabase(
//       path,
//       options: OpenDatabaseOptions(
//         version: 1,
//         onCreate: (db, version) async {
//           await db.execute('''
//             CREATE TABLE medicines(
//               id INTEGER PRIMARY KEY AUTOINCREMENT,
//               name TEXT,
//               dosage TEXT,
//               frequency TEXT,
//               time TEXT,
//               notes TEXT
//             )
//           ''');
//         },
//       ),
//     );
//   }
// }
