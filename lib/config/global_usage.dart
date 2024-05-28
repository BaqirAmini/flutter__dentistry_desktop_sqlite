import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dentistry/models/db_conn.dart';
import 'package:flutter_dentistry/views/finance/fee/fee_related_fields.dart';
import 'package:flutter_dentistry/views/patients/patient_info.dart';
import 'package:flutter_dentistry/views/services/service_related_fields.dart';
import 'package:flutter_dentistry/views/staff/staff_info.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:win32/win32.dart';
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter_dentistry/config/private/private.dart';
import 'package:pdf/widgets.dart' as pw;

class GlobalUsage {
  // A toast message to be used anywhere required
  static void showCustomToast(BuildContext context, String message) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
            label: 'OK', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }

  /* ------------------- CHARACTERS/DIGITS ALLOWED ---------------- */
  // 0-9 and + are allowed
  static const allowedDigits = "[0-9+۰-۹]";
  //  alphabetical letters both in English & Persian allowed including comma
  static const allowedEPChar = "[a-zA-Z,، \u0600-\u06FFF]";
  // 0-9 and period(.) are allowed
  static const allowedDigPeriod = r"^\d*\.?\d{0,2}$";
  /* -------------------/. CHARACTERS/DIGITS ALLOWED ---------------- */

  static bool widgetVisible = false;
//  This static variable specifies whether the appointment
//is created with creating a new patient or an existing patient (true = new patient created, false = patient already existing)
  static bool newPatientCreated = true;

  // Fetch staff which will be needed later.
  Future<List<Map<String, dynamic>>> fetchStaff() async {
    try {
      // Fetch staff for purchased by fields
      var conn = await onConnToSqliteDb();
      var results = await conn.rawQuery(
          'SELECT staff_ID, firstname, lastname FROM staff WHERE position = ?',
          ['داکتر دندان']);

      List<Map<String, dynamic>> staffList = results
          .map((result) => {
                'staff_ID': result["staff_ID"].toString(),
                'firstname': result["firstname"],
                'lastname': result["lastname"] ?? ''
              })
          .toList();
      return staffList;
    } catch (e) {
      print('Error occured fetching staff (Global Usage): $e');
      return [];
    }
  }

  // Fetch clinics which will be needed later.
  Future<List<Map<String, dynamic>>> retrieveClinics() async {
    try {
      var conn = await onConnToSqliteDb();
      var results = await conn.rawQuery(
          'SELECT clinic_ID, clinic_name, clinic_address, clinic_phone1, clinic_phone2, clinic_email, clinic_founder, clinic_logo FROM clinics');

      List<Map<String, dynamic>> clinicList = results
          .map((result) => {
                'clinicId': result["clinic_ID"].toString(),
                'clinicName': result["clinic_name"] ?? '',
                'clinicAddr': result["clinic_address"] ?? '',
                'clinicPhone1': result["clinic_phone1"] ?? '',
                'clinicPhone2': result["clinic_phone2"] ?? '',
                'clinicEmail': result["clinic_email"] ?? '',
                'clinicLogo': result["clinic_logo"] ?? ''
              })
          .toList();
      return clinicList;
    } catch (e) {
      print('Error occured fetching clinics (Global Usage): $e');
      return [];
    }
  }

// Declare this function to fetch services from services table to be used globally
  Future<List<Map<String, dynamic>>> fetchServices() async {
    var conn = await onConnToSqliteDb();
    var queryService = await conn
        .rawQuery('SELECT ser_ID, ser_name FROM services WHERE ser_ID');

    List<Map<String, dynamic>> services = queryService
        .map((result) => {
              'ser_ID': result["ser_ID"].toString(),
              'ser_name': result["ser_name"]
            })
        .toList();

    return services;
  }

  // Create this function to make number of records responsive
  int calculateRowsPerPage(BuildContext context) {
    var minHeight = MediaQuery.of(context).size.height;
    int rowsPerPage = (minHeight / 50).floor();
    return rowsPerPage;
  }

  // This function is to give notifiction for users
  void alertUpcomingAppointment(
      int patId, String firstName, String? lastName, String notif) {
    final winNotifyPlugin = WindowsNotification(
        applicationId:
            r"{7C5A40EF-A0FB-4BFC-874A-C0F2E0B9FA8E}\Crown\crown.exe");
    NotificationMessage message = NotificationMessage.fromPluginTemplate(
        "appointment ($patId)",
        "Upcoming Appointment in $notif",
        "You have an appointment with $firstName $lastName");
    winNotifyPlugin.showNotificationPluginTemplate(message);
  }

  Future<void> onCreateReceipt(
      String clinicName,
      String clinicAddr,
      String clinicPhone1,
      String dentist,
      String service,
      double grossFee,
      int totalInstallment,
      int paidInstallment,
      double discRate,
      double payableFee,
      double paidFee,
      double dueFee,
      String paidDate) async {
    try {
      // Current date
      DateTime now = DateTime.now();
      String formattedDate = intl.DateFormat('yyyy/MM/dd').format(now);
      const assetImgProvider = AssetImage(
        'assets/graphics/logo1.png',
      );
      ImageProvider? blobImgProvider;
      final clinicLogo =
          await flutterImageProvider(blobImgProvider ?? assetImgProvider);
      final pdf = pw.Document();
      final fontData = await rootBundle.load('assets/fonts/per_sans_font.ttf');
      final ttf = pw.Font.ttf(fontData);
      final iconData = await rootBundle.load('assets/fonts/material-icons.ttf');
      final iconTtf = pw.Font.ttf(iconData);

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a5.applyMargin(
          left: 0.5 * PdfPageFormat.cm,
          right: 0.5 * PdfPageFormat.cm,
          top: 0.5 * PdfPageFormat.cm,
          bottom: 0.5 * PdfPageFormat.cm, // Adjust this value as needed
        ),
        build: (pw.Context context) {
          return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('INVOICE'),
                              pw.SizedBox(height: 30),
                              pw.Text(
                                  textDirection: pw.TextDirection.rtl,
                                  clinicName,
                                  style: pw.TextStyle(font: ttf)),
                              pw.Text(
                                  textDirection: pw.TextDirection.rtl,
                                  clinicAddr,
                                  style: pw.TextStyle(font: ttf)),
                              pw.Text(
                                textDirection: pw.TextDirection.rtl,
                                'Dr. $dentist',
                                style: pw.TextStyle(
                                  font: ttf,
                                ),
                              ),
                              pw.Text(
                                textDirection: pw.TextDirection.rtl,
                                clinicPhone1,
                                style: pw.TextStyle(
                                  font: ttf,
                                ),
                              ),
                            ]),
                        pw.ClipOval(
                            child: pw.Container(
                          width: 50,
                          height: 50,
                          child: pw.Image(clinicLogo),
                        )),
                      ]),
                ),
                pw.SizedBox(height: 15),
                pw.Column(children: [
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        (PatientInfo.newPatientCreated)
                            ? pw.Text(
                                textDirection: pw.TextDirection.rtl,
                                'Patient: ${PatientInfo.newPatientFName} ${PatientInfo.newPatientLName}',
                                style: pw.TextStyle(
                                  font: ttf,
                                ),
                              )
                            : pw.Text(
                                textDirection: pw.TextDirection.rtl,
                                'Patient: ${PatientInfo.firstName} ${PatientInfo.lastName}',
                                style: pw.TextStyle(
                                  font: ttf,
                                ),
                              ),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              (PatientInfo.newPatientCreated)
                                  ? pw.Text(
                                      textDirection: pw.TextDirection.rtl,
                                      'Invoice NO: INV-1234',
                                      style: pw.TextStyle(
                                        font: ttf,
                                      ),
                                    )
                                  : pw.Text(
                                      textDirection: pw.TextDirection.rtl,
                                      'Invoice NO: INV-${PatientInfo.age}${PatientInfo.patID}',
                                      style: pw.TextStyle(
                                        font: ttf,
                                      ),
                                    ),
                              pw.Text(
                                textDirection: pw.TextDirection.rtl,
                                'Date: ${intl.DateFormat('yyyy-MM-dd HH:MM').format(DateTime.parse(paidDate))}',
                                style: pw.TextStyle(
                                  font: ttf,
                                ),
                              ),
                              pw.Text(
                                textDirection: pw.TextDirection.rtl,
                                'Installments: $totalInstallment / $paidInstallment',
                                style: pw.TextStyle(
                                  font: ttf,
                                ),
                              ),
                            ])
                      ]),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    columnWidths: <int, pw.TableColumnWidth>{
                      0: const pw.IntrinsicColumnWidth(),
                      1: const pw.FlexColumnWidth(),
                      2: const pw.FixedColumnWidth(100),
                      3: const pw.FlexColumnWidth(),
                    },
                    defaultVerticalAlignment:
                        pw.TableCellVerticalAlignment.middle,
                    children: <pw.TableRow>[
                      pw.TableRow(
                        children: [
                          pw.Text('Description',
                              textAlign: pw.TextAlign.center),
                          pw.Text('Quantity', textAlign: pw.TextAlign.center),
                          pw.Text('Unit Price (AFN)',
                              textAlign: pw.TextAlign.center),
                          pw.Text('Amount (AFN)',
                              textAlign: pw.TextAlign.center),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Text(service, textAlign: pw.TextAlign.center),
                          pw.Text('1', textAlign: pw.TextAlign.center),
                          pw.Text('$grossFee', textAlign: pw.TextAlign.center),
                          pw.Text('$grossFee', textAlign: pw.TextAlign.center),
                        ],
                      ),
                      // Add more TableRow widgets for more rows
                    ],
                  )
                ]),
                pw.SizedBox(height: 15),
                pw.Text(
                  textDirection: pw.TextDirection.rtl,
                  'Procedure: $service',
                  style: pw.TextStyle(
                    font: ttf,
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Text(
                  textDirection: pw.TextDirection.rtl,
                  'Total: $grossFee AFN',
                  style: pw.TextStyle(
                    font: ttf,
                  ),
                ),
                pw.Text(
                  textDirection: pw.TextDirection.rtl,
                  'Discount: $discRate%',
                  style: pw.TextStyle(
                    font: ttf,
                  ),
                ),
                pw.Text(
                  textDirection: pw.TextDirection.rtl,
                  'Payable: $payableFee AFN',
                  style: pw.TextStyle(
                    font: ttf,
                  ),
                ),
                pw.Text(
                  textDirection: pw.TextDirection.rtl,
                  'Paid: $paidFee AFN',
                  style: pw.TextStyle(
                    font: ttf,
                  ),
                ),
                pw.Text(
                  textDirection: pw.TextDirection.rtl,
                  'Due: $dueFee AFN',
                  style: pw.TextStyle(
                    font: ttf,
                  ),
                ),
                pw.Text(
                  textDirection: pw.TextDirection.rtl,
                  '---------------------------------------------------------------------------',
                ),
              ]);
        },
      ));
      // Save the PDF
      final bytes = await pdf.save();
      const fileName = 'Receipt.pdf';
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      print('Exception: $e');
    }
  }

// This function fetches machine GUID.
  String getMachineGuid() {
    final hKey = calloc<HKEY>();
    final lpcbData = calloc<DWORD>()..value = 256;
    final lpData = calloc<Uint16>(lpcbData.value);

    final strKeyPath = TEXT('SOFTWARE\\Microsoft\\Cryptography');
    final strValueName = TEXT('MachineGuid');

    var result =
        RegOpenKeyEx(HKEY_LOCAL_MACHINE, strKeyPath, 0, KEY_READ, hKey);
    if (result == ERROR_SUCCESS) {
      result = RegQueryValueEx(
          hKey.value, strValueName, nullptr, nullptr, lpData.cast(), lpcbData);
      if (result == ERROR_SUCCESS) {
        String machineGuid = lpData
            .cast<Utf16>()
            .toDartString(); // Use cast<Utf16>().toDartString() here
        calloc.free(hKey);
        calloc.free(lpcbData);
        calloc.free(lpData);
        return machineGuid;
      }
    }

    calloc.free(hKey);
    calloc.free(lpcbData);
    calloc.free(lpData);

    throw Exception('Failed to get MachineGuid');
  }

// Create instance of Flutter Secure Store
  final storage = const FlutterSecureStorage();

  // Store the expiry date
  Future<void> storeExpiryDate(DateTime expiryDate) async {
    var formatter = intl.DateFormat('yyyy-MM-dd HH:mm');
    var formattedExpiryDate = formatter.format(expiryDate);
    await storage.write(key: 'expiryDate', value: formattedExpiryDate);
  }

// Get the expiry date
  Future<DateTime?> getExpiryDate() async {
    var formatter = intl.DateFormat('yyyy-MM-dd HH:mm');
    var formattedExpiryDate = await storage.read(key: 'expiryDate');
    return formattedExpiryDate != null
        ? formatter.parse(formattedExpiryDate)
        : null;
  }

  // Delete the expiry date
  Future<void> deleteExpiryDate() async {
    await storage.delete(key: 'expiryDate');
  }

// Check if the license key has expired
  Future<bool> hasLicenseKeyExpired() async {
    var expiryDate = await getExpiryDate();
    return expiryDate != null && DateTime.now().isAfter(expiryDate);
  }

/*-------------- For Developer -----------*/
  // XOR cipher
  String generateProductKey(DateTime expiryDate, String guid) {
    var formatter = intl.DateFormat('yyyy-MM-dd HH:mm');
    var formattedExpiryDate = formatter.format(expiryDate);
    var dataToEncrypt = guid + formattedExpiryDate;
    // Encrtypt value with XOR cipher
    var key = secretKey;
    var encryptedData = '';
    for (var i = 0; i < dataToEncrypt.length; i++) {
      var xorResult =
          dataToEncrypt.codeUnitAt(i) ^ key.codeUnitAt(i % key.length);
      encryptedData += xorResult.toRadixString(16).padLeft(2, '0');
    }
    return encryptedData;
  }
/*--------------/. For Developer -----------*/

/*----------------- For Users ----------*/
  String productKeyRelatedMsg =
      'Please enter the product key you have purchased and click \'Verify\' in below to activate the system or make a contact with the system owner.';
// Store the liscense key for a specific user
  Future<void> storeLicenseKey4User(String key) async {
    await storage.write(key: 'UserlicenseKey', value: key);
  }

  // Get the liscense key for a specific user
  Future<String?> getLicenseKey4User() async {
    return await storage.read(key: 'UserlicenseKey');
  }

// Delete the liscense for a specific user
  Future<void> deleteValue4User(String key) async {
    await storage.delete(key: key);
  }

  // Decrtype XOR Cypher
  String decryptProductKey(String encryptedData, String key) {
    var decryptedData = '';
    for (var i = 0; i < encryptedData.length; i += 2) {
      var hexValue = encryptedData.substring(i, i + 2);
      var xorResult = int.parse(hexValue, radix: 16);
      decryptedData += String.fromCharCode(
          xorResult ^ key.codeUnitAt(((i ~/ 2) % key.length)));
    }
    return decryptedData;
  }

/*-----------------/. For Users ----------*/
}
