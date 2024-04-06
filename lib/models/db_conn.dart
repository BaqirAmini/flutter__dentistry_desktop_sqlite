import 'dart:io';
import 'package:galileo_mysql/galileo_mysql.dart';
import 'package:flutter_dentistry/config/private/private.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Future<MySqlConnection> onConnToDb() async {
  try {
    final conn = await MySqlConnection.connect(ConnectionSettings(
        host: 'localhost',
        port: 3306,
        user: username,
        password: pwd,
        db: 'dentistry_db'));
    return conn;
  } on SocketException catch (e) {
    print('Could not connect to the database. Error: ${e.message}');
    return Future.error(e);
  } catch (e) {
    print(e);
    return Future.error(e);
  }
}

// This function connects to SQLite database
Future<Database> onConnToSqliteDb() async {
  try {
    // Get the path to the database.
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'dentistry_db.db');

    // Open the database. The `onCreate` callback will be called if the database doesn't exist.
    final db =
        await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('PRAGMA foreign_keys = ON;');
      await db.execute('''
    CREATE TABLE staff(
      staff_ID INTEGER PRIMARY KEY AUTOINCREMENT,
      firstname TEXT,
      lastname TEXT,
      hire_date TEXT,
      position TEXT,
      salary REAL,
      prepayment REAL,
      phone TEXT,
      family_phone1 TEXT,
      tazkira_ID TEXT,
      photo BLOB,
      contract_file BLOB,
      address TEXT,
      family_phone2 TEXT,
      file_type TEXT
    )
  ''');
      await db.execute('''
    CREATE TABLE staff_auth(
      auth_ID INTEGER PRIMARY KEY AUTOINCREMENT,
      staff_ID INTEGER,
      username TEXT,
      password TEXT,
      role TEXT,
      FOREIGN KEY(staff_ID) REFERENCES staff(staff_ID) ON DELETE CASCASE ON UPDATE CASCADE
    )
  ''');
    });

    return db;
  } catch (e) {
    print('Could not connect to the database. Error: ${e.toString()}');
    return Future.error(e);
  }
}
