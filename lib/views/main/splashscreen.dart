import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dentistry/config/developer_options.dart';
import 'package:flutter_dentistry/config/global_usage.dart';
import 'package:flutter_dentistry/config/language_provider.dart';
import 'package:flutter_dentistry/config/liscense_verification.dart';
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
                  builder: (context) => const LiscenseVerification()))
          // ignore: use_build_context_synchronously
          : Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const Login()));
      try {
        // Call to create database and tables
        var conn = await onConnToSqliteDb();
        var query1 = await conn.rawQuery(
            'SELECT * FROM staff_auth WHERE username = ?', ['admin123']);
        if (query1.isEmpty) {
          int resultStaff = await conn.rawInsert(
              'INSERT INTO staff (firstname, lastname, position, phone, family_phone1) VALUES (?, ?, ?, ?, ?)',
              ['Ahmad', 'Ahmadi', 'داکتر دندان', '1234567890', '1234567891']);
          if (resultStaff > 0) {
            // Select to see if it exsits.
            var selectStaff = await conn.rawQuery(
                'SELECT staff_ID FROM staff WHERE firstname = ? AND lastname = ? AND phone = ?',
                ['Ahmad', 'Ahmadi', '1234567890']);
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
}
