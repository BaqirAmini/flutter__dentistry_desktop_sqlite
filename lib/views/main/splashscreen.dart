import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dentistry/config/developer_options.dart';
import 'package:flutter_dentistry/config/global_usage.dart';
import 'package:flutter_dentistry/config/language_provider.dart';
import 'package:flutter_dentistry/config/license_verification.dart';
import 'package:flutter_dentistry/models/db_conn.dart';
import 'package:flutter_dentistry/views/main/login.dart';
import 'package:provider/provider.dart';

void main() {
  Features.setVersion('Premium'); // For premium version
  // Features.setVersion('Standard'); // For standard version
  runApp(const CrownApp());
}

class CrownApp extends StatelessWidget {
  const CrownApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LanguageProvider>(
      create: (_) => LanguageProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'My App',
        theme: ThemeData(
          useMaterial3: false,
          primarySwatch: Colors.blue,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Create an instance of this class
  final GlobalUsage _globalUsage = GlobalUsage();

  @override
  void initState() {
    super.initState();

    // Navigate to the login page after 3 seconds
    Future.delayed(const Duration(seconds: 3), () async {
      /*    _globalUsage.deleteValue4User('UserlicenseKey');
      _globalUsage.deleteExpiryDate(); */
      await _globalUsage.hasLicenseKeyExpired() ||
              await _globalUsage.getLicenseKey4User() == null
          // ignore: use_build_context_synchronously
          ? Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const LicenseVerification()))
          // ignore: use_build_context_synchronously
          : Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const Login()));
      try {
        // Call to create database and tables
        var conn = await onConnToSqliteDb();
        var query1 = await conn.rawQuery('SELECT * FROM staff_auth');
        if (query1.isEmpty) {
          int resultStaff = await conn.rawInsert(
              'INSERT INTO staff (firstname, lastname, position, phone, family_phone1) VALUES (?, ?, ?, ?, ?)',
              ['Ahmad', 'Ahmadi', 'داکتر دندان', '1234567890', '1234567891']);
          if (resultStaff > 0) {
            // Select to see if it exsits.
            var selectStaff = await conn.rawQuery('SELECT staff_ID FROM staff');
            int staffId = selectStaff.first['staff_ID'] as int;

            //  Do some hashing for password
            var bytes = utf8.encode('admin123');
            var digest = sha256.convert(bytes);
            String hashedPwd = digest.toString();

            int resultAuth = await conn.rawInsert(
                'INSERT INTO staff_auth (staff_ID, username, password, role) VALUES (?, ?, ?, ?)',
                [staffId, 'admin123', hashedPwd, 'مدیر سیستم']);

            if (resultAuth > 0) {
              print('User ID = $staffId created.');
            } else {
              print('Oops! User ID = $staffId not created!');
            }
          } else {
            print('Staff not created.');
          }
        }
        await _onAddServices();
        await _onAddServiceRequirement();
        await _onAddPatientHistory();
        await _onAddDefaultClinic();
        await _onAddExpenseType();
      } catch (e) {
        print('Exception in splashscreen: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.1,
              height: MediaQuery.of(context).size.height * 0.1,
              child: Image.asset('assets/graphics/crown_logo_blue.png'),
            ), // Replace with your logo
            const SizedBox(height: 30),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.1,
              child: const LinearProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }

// Add patients histories
  Future<void> _onAddPatientHistory() async {
    try {
      var conn = await onConnToSqliteDb();
      var results = await conn.rawQuery('SELECT * FROM conditions');
      if (results.isEmpty) {
        var addPatientHistories = await conn.rawInsert('''
              INSERT INTO conditions (cond_ID, name) VALUES
              (1, 'آیا دخانیات مصرف میکنید؟'),
              (2, 'آیا گاهی اوقات گیج میشوید؟'),
              (3, 'آیا حمل دارید؟'),
              (4, 'آیا حساسیت جلدی دارید؟'),
              (5, 'آیا درد در ناحیه قفسه سینه دارید؟'),
              (6, 'آیا زردی سیاه و یا دیگر انواع زردی دارید؟'),
              (7, 'آیا مرض قند دارید؟'),
              (8, 'آیا نسبت به بعضی داروها حساسیت دارید؟'),
              (9, 'آیا دچار افت فشار خون و یا بالا رفتن آن میشوید؟');
      ''');
        if (addPatientHistories > 0) {
          print('Patients histories Created.');
        }
      } else {
        print('Patients histories are existing.');
      }
    } catch (e) {
      print('Error occured with creating patients histories: $e');
    }
  }

  // Add Services
  Future<void> _onAddServices() async {
    try {
      var conn = await onConnToSqliteDb();
      var results = await conn.rawQuery('SELECT * FROM services');
      if (results.isEmpty) {
        var addServices = await conn.rawInsert('''
              INSERT INTO services (ser_ID, ser_name, ser_fee) VALUES
                (1, 'عصب کشی(R.C.T)', '999.99'),
                (2, 'پرکاری(Filling)', '0.00'),
                (3, 'Bleaching', '1000.00'),
                (4, 'Scaling and Polishing', '0.00'),
                (5, 'Orthodontics', '0.00'),
                (7, 'Maxillofacial Surgery', '0.00'),
                (8, 'Oral Examination', '0.00'),
                (9, 'Denture', '0.00'),
                (11, 'پوش کردن(Crown)', '0.00'),
                (12, 'Flouride Therapy', '0.00'),
                (13, 'Night Gaurd Prothesis', '0.00'),
                (14, 'Snap-on Smile', '0.00'),
                (15, 'Implant', '0.00'),
                (16, 'Smile Design Correction', '0.00');
      ''');
        if (addServices > 0) {
          print('Services Created.');
        }
      } else {
        print('Services are existing.');
      }
    } catch (e) {
      print('Error occured with creating services: $e');
    }
  }

  // Add Services Requirements
  Future<void> _onAddServiceRequirement() async {
    try {
      var conn = await onConnToSqliteDb();
      var results = await conn.rawQuery('SELECT * FROM service_requirements');
      if (results.isEmpty) {
        var addSerReq = await conn.rawInsert('''
              INSERT INTO service_requirements (req_ID, req_name) VALUES
                (1, 'Teeth Selection'),
                (2, 'Description'),
                (3, 'Procedure Type'),
                (4, 'Materials'),
                (5, 'Bleaching Steps'),
                (7, 'Gum Selection'),
                (9, 'Affected Area');
      ''');
        if (addSerReq > 0) {
          print('Services requirements Created.');
        }
      } else {
        print('Services requirements are existing.');
      }
    } catch (e) {
      print('Error occured with creating service requirements: $e');
    }
  }

  // Add a default clinic name
  Future<void> _onAddDefaultClinic() async {
    try {
      var conn = await onConnToSqliteDb();
      var results = await conn.rawQuery('SELECT * FROM clinics');
      if (results.isEmpty) {
        var addClinic = await conn.rawInsert('''
              INSERT INTO clinics (clinic_name, clinic_address, clinic_phone1) VALUES
                ('Your Clinic Name', 'Your Clinic Address', '07XXXXXXXX');
      ''');
        if (addClinic > 0) {
          print('Clinic Created.');
        }
      } else {
        print('Clinic Existing.');
      }
    } catch (e) {
      print('Error occured with creating clinic: $e');
    }
  }

  // Add default expense types
  Future<void> _onAddExpenseType() async {
    try {
      var conn = await onConnToSqliteDb();
      var results = await conn.rawQuery('SELECT * FROM expenses');
      if (results.isEmpty) {
        var addClinic = await conn.rawInsert('''
              INSERT INTO expenses (exp_name) VALUES
                ('لابراتوار'),
                ('تجهیزات کلینیک'),
                ('ترمیم ابزار'),
                ('شاروالی'),
                ('خوراک'),
                ('آب');
      ''');
        if (addClinic > 0) {
          print('Expense Types Created.');
        }
      } else {
        print('Expense Types Existing.');
      }
    } catch (e) {
      print('Error occured with creating expense types: $e');
    }
  }
}
