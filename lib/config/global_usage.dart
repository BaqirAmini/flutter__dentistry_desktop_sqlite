import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dentistry/models/db_conn.dart';
import 'package:flutter_dentistry/views/patients/patient_info.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:win32/win32.dart';
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter_dentistry/config/private/private.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:ui' as ui;

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

  int _invoiceNumber = 0;

// This function generates invoice number.
  String generateInvoiceNumber() {
    final String datePart =
        DateTime.now().toString().substring(0, 10).replaceAll('-', '');
    final String numberPart = (_invoiceNumber++).toString().padLeft(3, '0');
    return '$datePart-$numberPart';
  }

// This function creates a receipt for a patient
  Future<void> onCreateReceipt(
      int? patientId,
      String? clinicName,
      String? clinicAddr,
      String? clinicPhone1,
      Uint8List? firtClinicLogo,
      String? dentist,
      String? service,
      double? grossFee,
      int? totalInstallment,
      int? paidInstallment,
      double? discRate,
      double? payableFee,
      double? paidFee,
      double? dueFee,
      String? paidDate) async {
    try {
      const assetImgProvider = AssetImage(
        'assets/graphics/logo1.png',
      );
      ImageProvider? blobImgProvider;

      Uint8List? firstClinicLogoBuffer = firtClinicLogo?.buffer.asUint8List();
      if (firstClinicLogoBuffer != null && firstClinicLogoBuffer.isNotEmpty) {
        final Completer<ui.Image> completer = Completer();
        ui.decodeImageFromList(firstClinicLogoBuffer, (ui.Image img) {
          return completer.complete(img);
        });
        blobImgProvider = MemoryImage(firstClinicLogoBuffer);
      }

      final clinicLogo =
          await flutterImageProvider(blobImgProvider ?? assetImgProvider);
      final pdf = pw.Document();
      final fontData = await rootBundle.load('assets/fonts/per_sans_font.ttf');
      final ttf = pw.Font.ttf(fontData);
      final iconData = await rootBundle.load('assets/fonts/material-icons.ttf');
      final iconTtf = pw.Font.ttf(iconData);

      double? payableAmount =
          (PatientInfo.newPatientCreated) ? payableFee : (dueFee! + paidFee!);

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
                pw.Column(children: [
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 50,
                          height: 50,
                          child: pw.FittedBox(
                            child: pw.Image(clinicLogo),
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                        pw.Container(
                          padding:
                              const pw.EdgeInsets.symmetric(horizontal: 25.0),
                          color: const PdfColor(0.122, 0.545, 0.831),
                          child: pw.Text('INVOICE',
                              style: pw.Theme.of(context).header1.copyWith(
                                  fontSize: 25.0,
                                  color: const PdfColor(1, 1, 1),
                                  fontWeight: pw.FontWeight.bold)),
                        ),
                      ]),
                  pw.SizedBox(height: 30.0),
                  pw.Row(children: [
                    pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Bill From',
                              style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text(
                              textDirection: pw.TextDirection.rtl,
                              clinicName!,
                              style: pw.TextStyle(font: ttf)),
                          pw.Text(
                              textDirection: pw.TextDirection.rtl,
                              clinicAddr!,
                              style: pw.TextStyle(font: ttf)),
                        ]),
                  ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: []),
                        pw.Text(
                          textDirection: pw.TextDirection.rtl,
                          'Dr. $dentist',
                          style: pw.TextStyle(
                            font: ttf,
                          ),
                        ),
                        pw.Text(
                          textDirection: pw.TextDirection.rtl,
                          clinicPhone1!,
                          style: pw.TextStyle(
                            font: ttf,
                          ),
                        ),
                      ]),
                ]),
                pw.SizedBox(height: 15),
                pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Bill To',
                                style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Column(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        (PatientInfo.newPatientCreated)
                                            ? pw.Text(
                                                textDirection:
                                                    pw.TextDirection.rtl,
                                                'Patient: ${PatientInfo.newPatientFName} ${PatientInfo.newPatientLName}',
                                                style: pw.TextStyle(
                                                  font: ttf,
                                                ),
                                              )
                                            : pw.Text(
                                                textDirection:
                                                    pw.TextDirection.rtl,
                                                'Patient: ${PatientInfo.firstName} ${PatientInfo.lastName}',
                                                style: pw.TextStyle(
                                                  font: ttf,
                                                ),
                                              ),
                                        (PatientInfo.newPatientCreated)
                                            ? pw.Text(
                                                'Age: ${PatientInfo.newPatientAge} Yrs')
                                            : pw.Text(
                                                'Age: ${PatientInfo.age} Yrs'),
                                        (PatientInfo.newPatientCreated)
                                            ? pw.Text(
                                                'Phone: ${PatientInfo.newPatientPhone}')
                                            : pw.Text(
                                                'Phone: ${PatientInfo.phone}'),
                                      ]),
                                  pw.Column(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        (PatientInfo.newPatientCreated)
                                            ? pw.Text(
                                                textDirection:
                                                    pw.TextDirection.rtl,
                                                'Invoice NO: P-${PatientInfo.newPatientAge}$patientId',
                                                style: pw.TextStyle(
                                                  font: ttf,
                                                ),
                                              )
                                            : pw.Text(
                                                textDirection:
                                                    pw.TextDirection.rtl,
                                                'Invoice NO: ${PatientInfo.formattedPatId}',
                                                style: pw.TextStyle(
                                                  font: ttf,
                                                ),
                                              ),
                                        pw.Text(
                                          textDirection: pw.TextDirection.rtl,
                                          'Date: ${intl.DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.parse(paidDate.toString()))}',
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
                          ]),
                      pw.Table(
                        columnWidths: <int, pw.TableColumnWidth>{
                          0: const pw.FixedColumnWidth(100),
                          1: const pw.FixedColumnWidth(50),
                        },
                        defaultVerticalAlignment:
                            pw.TableCellVerticalAlignment.middle,
                        children: <pw.TableRow>[
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(
                              border:
                                  pw.Border(bottom: pw.BorderSide(width: 0.5)),
                              color: PdfColor(0.122, 0.545,
                                  0.831), // This is a light gray color
                            ),
                            children: [
                              pw.Text('Procedure',
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(
                                      color: const PdfColor(1, 1, 1),
                                      font: ttf,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text('Amount (AFN)',
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(
                                      color: const PdfColor(1, 1, 1),
                                      font: ttf,
                                      fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(
                              border:
                                  pw.Border(bottom: pw.BorderSide(width: 0.5)),
                            ),
                            children: [
                              pw.Directionality(
                                  child: pw.Text(service!,
                                      textAlign: pw.TextAlign.center,
                                      style: pw.TextStyle(font: ttf)),
                                  textDirection: pw.TextDirection.rtl),
                              pw.Text('$grossFee',
                                  textAlign: pw.TextAlign.center),
                            ],
                          ),
                          // Add more TableRow widgets for more rows
                        ],
                      ),
                      pw.SizedBox(height: 30.0),
                      pw.SizedBox(
                          child: pw.Column(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Container(
                                  color: const PdfColor(0.922, 0.906, 0.906),
                                  padding: const pw.EdgeInsets.symmetric(
                                      horizontal: 5.0),
                                  child: pw.Row(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Text(
                                          textDirection: pw.TextDirection.rtl,
                                          'Total:',
                                          style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold),
                                        ),
                                        pw.Text(
                                          textDirection: pw.TextDirection.rtl,
                                          '$grossFee AFN',
                                          style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold),
                                        ),
                                      ]),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                      horizontal: 5.0),
                                  child: pw.Row(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Text(
                                          textDirection: pw.TextDirection.rtl,
                                          'Discount:',
                                          style: pw.TextStyle(
                                            font: ttf,
                                          ),
                                        ),
                                        pw.Text(
                                          textDirection: pw.TextDirection.rtl,
                                          '$discRate%',
                                          style: pw.TextStyle(
                                            font: ttf,
                                          ),
                                        ),
                                      ]),
                                ),
                                pw.Container(
                                  color: const PdfColor(0.922, 0.906, 0.906),
                                  padding: const pw.EdgeInsets.symmetric(
                                      horizontal: 5.0),
                                  child: pw.Row(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Text(
                                          textDirection: pw.TextDirection.rtl,
                                          'Payable:',
                                          style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold),
                                        ),
                                        pw.Text(
                                          textDirection: pw.TextDirection.rtl,
                                          '$payableAmount AFN',
                                          style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold),
                                        ),
                                      ]),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                      horizontal: 5.0),
                                  child: pw.Row(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Text(
                                          textDirection: pw.TextDirection.rtl,
                                          'Paid:',
                                          style: pw.TextStyle(
                                            font: ttf,
                                          ),
                                        ),
                                        pw.Text(
                                          textDirection: pw.TextDirection.rtl,
                                          '$paidFee AFN',
                                          style: pw.TextStyle(
                                            font: ttf,
                                          ),
                                        ),
                                      ]),
                                ),
                                pw.Container(
                                  color: const PdfColor(0.922, 0.906, 0.906),
                                  padding: const pw.EdgeInsets.symmetric(
                                      horizontal: 5.0),
                                  child: pw.Row(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Text(
                                          textDirection: pw.TextDirection.rtl,
                                          'Due:',
                                          style: pw.TextStyle(
                                            font: ttf,
                                          ),
                                        ),
                                        pw.Text(
                                          textDirection: pw.TextDirection.rtl,
                                          '$dueFee AFN',
                                          style: pw.TextStyle(
                                            font: ttf,
                                          ),
                                        ),
                                      ]),
                                )
                              ]),
                          width: 150.0)
                    ]),
                pw.SizedBox(height: 15),
                pw.Divider(thickness: 1.5)
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
