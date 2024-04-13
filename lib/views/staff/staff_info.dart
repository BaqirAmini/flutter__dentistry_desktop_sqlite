import 'dart:typed_data';
import 'package:flutter_dentistry/models/db_conn.dart';


class StaffInfo {
  static int? staffID;
  static String? staffRole;
  static String? firstName;
  static String? lastName;
  static double? salary;
  static String? position;
  static String? phone;
  static String? tazkira;
  static String? address;
  static Function? onUpdateProfile;
  static Uint8List? userPhoto;
  static Uint8List? contractFile;
  static String? fileType;

  // position types dropdown variables
  static String staffDefaultPosistion = 'داکتر دندان';
  static var staffPositionItems = [
    'داکتر دندان',
    'پروتیزین',
    'آشپز',
    'حسابدار',
    'کار آموز'
  ];

  static Uint8List? uint8list;
  // This function fetches staff photo
  static Future<void> onFetchStaffPhoto(int staffID) async {
    final conn = await onConnToSqliteDb();
    final result = await conn
        .rawQuery('SELECT photo FROM staff WHERE staff_ID = ?', [staffID]);

    Uint8List? staffPhoto =
        result.first['photo'] != null ? result.first['photo'] as Uint8List : null;

    // Convert image of BLOB type to binary first.
    uint8list =
        staffPhoto != null ? Uint8List.fromList(staffPhoto) : null;
  }
}
