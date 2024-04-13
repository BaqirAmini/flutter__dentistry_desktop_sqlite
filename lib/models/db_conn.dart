// For only Android & IOS this package is enough
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
// This package is only required by flutter web & desktop in addtion to sqflite
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// This function connects to SQLite database
void initSqflite() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

Future<Database> onConnToSqliteDb() async {
  initSqflite(); // Initialize sqflite_common_ffi
  try {
    // Get the path to the database.
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'dentistry_db.db');
    
    // Open the database. The `onCreate` callback will be called if the database doesn't exist.
    final db =
        await openDatabase(path, version: 3, onCreate: (db, version) async {
      await db.execute('PRAGMA foreign_keys = ON;');
      // TABLE = staff
      await db.execute('''
          CREATE TABLE staff(
            staff_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            firstname TEXT NOT NULL,
            lastname TEXT NOT NULL,
            hire_date TEXT,
            position TEXT,
            salary REAL,
            prepayment REAL,
            phone TEXT NOT NULL,
            family_phone1 TEXT NOT NULL,
            tazkira_ID TEXT,
            photo BLOB,
            contract_file BLOB,
            address TEXT,
            family_phone2 TEXT,
            file_type TEXT
          )
        ''');
      // TABLE = staff_auth
      await db.execute('''
          CREATE TABLE staff_auth(
            auth_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            staff_ID INTEGER NOT NULL,
            username TEXT NOT NULL,
            password TEXT NOT NULL,
            role TEXT NOT NULL,
            FOREIGN KEY(staff_ID) REFERENCES staff(staff_ID) ON DELETE CASCADE ON UPDATE CASCADE
          )
        ''');
      // TABLE = patients
      await db.execute('''
          CREATE TABLE patients(
            pat_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            staff_ID INTEGER NOT NULL,
            firstname TEXT,
            lastname TEXT,
            sex TEXT NOT NULL,
            age INTEGER NOT NULL,
            marital_status TEXT,
            phone TEXT,
            reg_date TEXT NOT NULL,
            blood_group TEXT,
            address TEXT,
            photo BLOB,
            FOREIGN KEY(staff_ID) REFERENCES staff(staff_ID) ON DELETE SET NULL ON UPDATE CASCADE
          )
        ''');
      // TABLE = expenses
      await db.execute('''
          CREATE TABLE expenses(
            exp_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            exp_name TEXT NOT NULL
          )
        ''');
      // TABLE = expense_detail
      await db.execute('''
          CREATE TABLE expense_detail(
            exp_detail_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            exp_ID INTEGER NOT NULL,
            purchased_by INTEGER NOT NULL,
            item_name TEXT NOT NULL,
            quantity REAL NOT NULL ,
            qty_unit TEXT,
            unit_price REAL NOT NULL,
            total REAL NOT NULL,
            purchase_date TEXT NOT NULL,
            invoice TEXT,
            note TEXT,
            FOREIGN KEY(exp_ID) REFERENCES expenses(exp_ID) ON DELETE CASCADE ON UPDATE CASCADE,
            FOREIGN KEY(purchased_by) REFERENCES staff(staff_ID) ON DELETE CASCADE ON UPDATE CASCADE
          )
        ''');
      // TABLE = services
      await db.execute('''
          CREATE TABLE services(
            ser_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            ser_name TEXT NOT NULL,
            ser_fee REAL DEFAULT 0
          )
        ''');
      // TABLE = appointments
      await db.execute('''
          CREATE TABLE appointments(
            apt_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            pat_ID INTEGER NOT NULL,
            service_ID INTEGER,
            installment INTEGER DEFAULT 1,
            round INTEGER NOT NULL DEFAULT 1,
            discount REAL DEFAULT 0,
            total_fee REAL DEFAULT 0,
            meet_date TEXT,
            staff_ID INTEGER,
            status TEXT,
            notification TEXT,
            details TEXT,
            FOREIGN KEY(pat_ID) REFERENCES patients(pat_ID) ON DELETE CASCADE ON UPDATE CASCADE,
            FOREIGN KEY(service_ID) REFERENCES services(ser_ID) ON DELETE CASCADE ON UPDATE CASCADE,
            FOREIGN KEY(staff_ID) REFERENCES staff(staff_ID) ON DELETE SET NULL ON UPDATE CASCADE
          )
        ''');
      // TABLE = service_requirements
      await db.execute('''
          CREATE TABLE service_requirements(
            req_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            req_name TEXT NOT NULL
          )
        ''');
      // TABLE = patient_services
      await db.execute('''
          CREATE TABLE patient_services(
            apt_ID INTEGER NOT NULL,
            pat_ID INTEGER NOT NULL,
            ser_ID INTEGER NOT NULL,
            req_ID INTEGER NOT NULL,
            value TEXT NOT NULL,
            FOREIGN KEY(apt_ID) REFERENCES appointments(apt_ID) ON DELETE CASCADE ON UPDATE CASCADE,
            FOREIGN KEY(pat_ID) REFERENCES patients(pat_ID) ON DELETE CASCADE ON UPDATE CASCADE,
            FOREIGN KEY(ser_ID) REFERENCES services(ser_ID) ON DELETE CASCADE ON UPDATE CASCADE,
            FOREIGN KEY(req_ID) REFERENCES service_requirements(req_ID) ON DELETE CASCADE ON UPDATE CASCADE
          )
        ''');
      // TABLE = fee_payments
      await db.execute('''
          CREATE TABLE fee_payments(
            payment_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            installment_counter INTEGER DEFAULT 1,
            payment_date TEXT NOT NULL,
            paid_amount REAL DEFAULT 0.0,
            due_amount REAL DEFAULT 0.0,
            whole_fee_paid INTEGER DEFAULT 0,
            staff_ID INTEGER,
            apt_ID INTEGER,
            FOREIGN KEY(staff_ID) REFERENCES staff(staff_ID) ON DELETE CASCADE ON UPDATE CASCADE,
            FOREIGN KEY(apt_ID) REFERENCES appointments(apt_ID) ON DELETE CASCADE ON UPDATE CASCADE
          )
        ''');
      // TABLE = patient_xrays
      await db.execute('''
          CREATE TABLE patient_xrays(
            xray_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            pat_ID INTEGER NOT NULL,
            xray_name TEXT NOT NULL,
            xray_type TEXT NOT NULL,
            reg_date TEXT NOT NULL,
            description TEXT ,
            FOREIGN KEY(pat_ID) REFERENCES staff(pat_ID) ON DELETE CASCADE ON UPDATE CASCADE
          )
        ''');
      // TABLE = conditions
      await db.execute('''
          CREATE TABLE conditions(
            cond_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
      // TABLE = condition_details
      await db.execute('''
          CREATE TABLE condition_details(
            cond_detail_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            cond_ID INTEGER,
            result INTEGER NOT NULL DEFAULT 0,
            severty TEXT,
            duration TEXT,
            diagnosis_date TEXT,
            pat_ID INTEGER,
            notes TEXT,
            FOREIGN KEY(pat_ID) REFERENCES patients(pat_ID) ON DELETE CASCADE ON UPDATE CASCADE,
            FOREIGN KEY(cond_ID) REFERENCES conditions(cond_ID) ON DELETE CASCADE ON UPDATE CASCADE
          )
        ''');
      // TABLE = retreatments
      await db.execute('''
          CREATE TABLE retreatments(
            retreat_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            apt_ID INTEGER,
            pat_ID INTEGER,
            help_service_ID INTEGER,
            damage_service_ID INTEGER,
            staff_ID INTEGER,
            retreat_date TEXT NOT NULL,
            retreat_cost REAL NOT NULL,
            retreat_reason TEXT NOT NULL,
            retreat_outcome TEXT NOT NULL,
            outcome_details TEXT,
            FOREIGN KEY(apt_ID) REFERENCES appointments(apt_ID) ON DELETE CASCADE ON UPDATE CASCADE,
            FOREIGN KEY(pat_ID) REFERENCES patients(pat_ID) ON DELETE CASCADE ON UPDATE CASCADE,
            FOREIGN KEY(help_service_ID) REFERENCES services(ser_ID) ON DELETE CASCADE ON UPDATE CASCADE,
            FOREIGN KEY(damage_service_ID) REFERENCES services(ser_ID) ON DELETE CASCADE ON UPDATE CASCADE,
            FOREIGN KEY(staff_ID) REFERENCES staff(staff_ID) ON DELETE SET NULL ON UPDATE CASCADE
          )
        ''');
      // TABLE = taxes
      await db.execute('''
          CREATE TABLE taxes(
            tax_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            annual_income REAL NOT NULL,
            tax_rate REAL,
            total_annual_tax REAL NOT NULL,
            TIN TEXT NOT NULL,
            tax_for_year INTEGER NOT NULL
          )
        ''');
      // TABLE = tax_payments
      await db.execute('''
          CREATE TABLE tax_payments(
            tax_pay_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            tax_ID INTEGER,
            paid_date TEXT NOT NULL,
            paid_by INTEGER NOT NULL,
            paid_amount REAL NOT NULL,
            due_amount REAL NOT NULL,
            note TEXT,
            modified_at TEXT,
            docs BLOB,
           FOREIGN KEY(paid_by) REFERENCES staff(staff_ID) ON DELETE CASCADE ON UPDATE CASCADE,
           FOREIGN KEY(tax_ID) REFERENCES taxes(tax_ID) ON DELETE CASCADE ON UPDATE CASCADE
          )
        ''');
    });

    return db;
  } catch (e) {
    print('Could not connect to the database. Error: ${e.toString()}');
    return Future.error(e);
  }
}
