import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dentistry/config/global_usage.dart';
import 'package:flutter_dentistry/config/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dentistry/config/translations.dart';
import 'package:flutter_dentistry/models/db_conn.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_dentistry/views/main/sidebar.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:intl/intl.dart' as intl;

void main() => runApp(const Dashboard());

// ignore: prefer_typing_uninitialized_variables
var selectedLanguage;
// ignore: prefer_typing_uninitialized_variables
var isEnglish;

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // This function is to refresh the dashboard when called.
  void refresh() {
    // Clear the old data to not causing unexpected results.
    patientData.clear();
    _getLastSixMonthPatient();
    _getPieData();
    _fetchAllPatient();
    _fetchFinance();
    _retrieveClinics();
  }

  int _allPatients = 0;
  int _todaysPatients = 0;
  var _transExpenses;
  var _transEarnings;
  var _transReceivable;
  File? _selectedLogo;
  bool _isLodingLogo = false;
  // This list to be assigned clinic info.
  List<Map<String, dynamic>> clinics = [];
  String? firstClinicID;
  String? firstClinicName;
  String? firstClinicAddr;
  String? firstClinicPhone1;
  String? firstClinicPhone2;
  String? firstClinicEmail;
  Uint8List? firstClinicLogo;
  // This variable is to set the first filter value of doughnut chart dropdown
  String incomeDuration = '1 Month';
// This function fetch patients' records
  Future<void> _fetchAllPatient() async {
    try {
      final conn = await onConnToSqliteDb();
      // Fetch all patients
      var allPatResults = await conn
          .rawQuery('SELECT COUNT(*) AS num_of_patient FROM patients');
      int allPatients = allPatResults.isNotEmpty
          ? allPatResults.first["num_of_patient"] as int
          : 0;

      // Fetch the patients who are added today
      var todayResult = await conn.rawQuery(
          'SELECT COUNT(*) AS today_patient FROM patients WHERE DATE(reg_date) = date(\'now\')');
      int todayPat = todayResult.isNotEmpty
          ? todayResult.first["today_patient"] as int
          : 0;
      setState(() {
        _allPatients = allPatients;
        _todaysPatients = todayPat;
      });
    } on SocketException catch (e) {
      print('Error in dashboard: $e');
    } catch (e) {
      print('Error in dashboard: $e');
    }
  }

  double _currentMonthExp = 0;
  double _curYearTax = 0;
  Future<void> _fetchFinance() async {
    try {
      final conn = await onConnToSqliteDb();
      // Fetch sum of current month expenses
      var expResults = await conn.rawQuery(
          'SELECT SUM(total) AS sum_of_cur_exp FROM expense_detail WHERE strftime(\'%Y\', purchase_date) = strftime(\'%Y\', date(\'now\')) AND strftime(\'%m\', purchase_date) = strftime(\'%m\', date(\'now\'))');

      double curMonthExp =
          (expResults.isNotEmpty && expResults.first["sum_of_cur_exp"] != null)
              ? double.parse(expResults.first["sum_of_cur_exp"].toString())
              : 0;
      // Firstly, fetch jalali(hijri shamsi) from current date.
      final jalaliDate = Jalali.now();
      final hijriYear = jalaliDate.year;
      // Query taxes of current hijri year
      var taxResults = await conn.rawQuery(
          'SELECT total_annual_tax FROM taxes WHERE tax_for_year = ?',
          [hijriYear]);
      double curYearTax = (taxResults.isNotEmpty &&
              taxResults.first["total_annual_tax"] != null)
          ? double.parse(taxResults.first["total_annual_tax"].toString())
          : 0;
      setState(() {
        _currentMonthExp = curMonthExp;
        _curYearTax = curYearTax;
      });
    } on SocketException catch (e) {
      print('Error in dashboard: $e');
    } catch (e) {
      print('Error in dashboard: $e');
    }
  }

  bool _isPatientDataInitialized = false;
  // Declare to assign total income to use it in the doughnut chart
  double netIncome = 0;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _fetchAllPatient();
    try {
      _fetchFinance();
    } catch (e) {
      print('Data not loaded $e');
    }
    _getPieData();
    _getLastSixMonthPatient();
    // Alert notifications
    _timer = Timer.periodic(
        const Duration(minutes: 5), (Timer t) => _alertNotification());

    _getRemainValidDays().then((_) {
      setState(() {});
    });

    _retrieveClinics();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  PageController page = PageController();
  List<_PatientsData> patientData = [];

  Future<void> _getLastSixMonthPatient() async {
    final conn = await onConnToSqliteDb();
    final results = await conn.rawQuery('''
  SELECT reg_date, COUNT(*) as count
  FROM patients
  WHERE julianday('now') - julianday(reg_date) <= 180
  GROUP BY strftime('%m', reg_date)
''');

    for (var row in results) {
      patientData.add(_PatientsData(
          intl.DateFormat('MMMM, y')
              .format(DateTime.parse(row["reg_date"].toString())),
          double.parse(row["count"].toString())));
    }
    setState(() {
      _isPatientDataInitialized = true;
    });
  }

// Fetch the expenses of last three months into pie char
  Future<List<_PieDataIncome>> _getPieData() async {
    try {
      int numberOnly = int.parse(incomeDuration.split(' ')[0]);
      final conn = await onConnToSqliteDb();
      // Fetch total paid amount
      var result = await conn.rawQuery('''
  SELECT SUM(paid_amount) as total_paid_amount 
  FROM fee_payments 
  WHERE julianday('now') - julianday(payment_date) <= ? * 30
''', [numberOnly]);

      double totalEarnings = (result.first['total_paid_amount'] != null)
          ? double.parse(result.first['total_paid_amount'].toString())
          : 0.0;

      // Fetch total fee (whole may be earned are still due)
      result = await conn.rawQuery('''
  SELECT SUM(total_fee) as totalFee 
  FROM appointments 
  WHERE julianday('now') - julianday(meet_date) <= ? * 30
''', [numberOnly]);

      double totalFee = (result.first['totalFee'] != null)
          ? double.parse(result.first['totalFee'].toString())
          : 0.0;

      // Fetch total expenses
      result = await conn.rawQuery('''
  SELECT SUM(total) as sum 
  FROM expense_detail 
  WHERE julianday('now') - julianday(purchase_date) <= ? * 30
''', [numberOnly]);

      double totalExpenses = (result.first['sum'] != null)
          ? double.parse(result.first['sum'].toString())
          : 0.0;

      // Whole due amount on patients
      result = await conn.rawQuery('''
        SELECT SUM(due_amount) as due_amount 
        FROM (
            SELECT due_amount 
            FROM fee_payments 
            WHERE (payment_ID, apt_ID) IN (
                SELECT MAX(payment_ID), apt_ID 
                FROM fee_payments 
                WHERE julianday('now') - julianday(payment_date) <= ? * 30
                GROUP BY apt_ID
            )
        ) AS total_due_amount
      ''', [numberOnly]);

      double totalDueAmount = (result.first['due_amount'] != null)
          ? double.parse(result.first['due_amount'].toString())
          : 0.0;
      // Total Income
      // netIncome = totalFee - totalExpenses - totalDueAmount;
      netIncome = totalEarnings - totalExpenses - totalDueAmount;
      return [
        _PieDataIncome(_transExpenses, totalExpenses, Colors.red),
        _PieDataIncome(_transEarnings, totalEarnings, Colors.green),
        _PieDataIncome(_transReceivable, totalDueAmount, Colors.indigo),
      ];
    } on SocketException catch (e) {
      print('Error in dashboard: $e');
      return [];
    } catch (e) {
      print('Error in dashboard: $e');
      return [];
    }
  }

  Future<void> _alertNotification() async {
    try {
      final conn = await onConnToSqliteDb();
      // Here Afghanistan Timezone is addressed
      final results = await conn.rawQuery(
          'SELECT *, meet_date as local_meet_date FROM appointments a INNER JOIN patients p ON a.pat_ID = p.pat_ID WHERE status = ? AND meet_date > date(\'now\')',
          ['Pending']);

      // Loop through the results
      for (final row in results) {
        // Get the notification frequency for this appointment
        final notificationFrequency = row['notification'].toString();
        final patientId = row['pat_ID'] as int;
        final patientFName = row['firstname'].toString();
        final patientLName = row['lastname'].toString();

        // Calculate the time until the notification should be shown
        final appointmentTime =
            DateTime.parse(row['local_meet_date'].toString());
        // Convert to not contain 'Z' as UTC timezone contains by default
        final formattedApptTime =
            intl.DateFormat('yyyy-MM-dd HH:mm:ss').format(appointmentTime);
        DateTime? alertTime;

        if (notificationFrequency == '30 Minutes') {
          alertTime = appointmentTime.subtract(const Duration(minutes: 30));
        } else if (notificationFrequency == '1 Hour') {
          alertTime = appointmentTime.subtract(const Duration(hours: 1));
        } else if (notificationFrequency == '2 Hours') {
          alertTime = appointmentTime.subtract(const Duration(hours: 2));
        } else if (notificationFrequency == '6 Hours') {
          alertTime = appointmentTime.subtract(const Duration(hours: 6));
        } else if (notificationFrequency == '12 Hours') {
          alertTime = appointmentTime.subtract(const Duration(hours: 12));
        } else if (notificationFrequency == '1 Day') {
          alertTime = appointmentTime.subtract(const Duration(days: 1));
        }

        // Make a copy of the variables
        final patientIdCopy = patientId;
        final patientFNameCopy = patientFName;
        final patientLNameCopy = patientLName;

        // Schedule the notification
        // Get the current time
        final currentTime = DateTime.now();
        // Convert current time to yyyy-mm-dd hh:mm (without seconds or microseconds)
        final currentTimeRounded = DateTime(currentTime.year, currentTime.month,
            currentTime.day, currentTime.hour, currentTime.minute);

        // Convert to not contain 'Z' as UTC timezone contains by default
        final formattedAlertTime =
            intl.DateFormat('yyyy-MM-dd HH:mm:ss').format(alertTime!);

        if (currentTimeRounded.isAfter(DateTime.parse(formattedAlertTime)) &&
            currentTimeRounded
                    .difference(DateTime.parse(formattedAlertTime))
                    .inMinutes <=
                15) {
          // Create an instance of this class to access its method to alert for upcoming notification
          GlobalUsage gu = GlobalUsage();
          gu.alertUpcomingAppointment(patientIdCopy, patientFNameCopy,
              patientLNameCopy, notificationFrequency);
          print('Current Time: $currentTimeRounded');
          print('Frequency: $notificationFrequency');
          print('Notification time: $formattedAlertTime');
          print('appointment time: $formattedApptTime');
        }
      }
    } catch (e) {
      print('Error occured with notification: $e');
    }
  }

  final GlobalUsage _globalUsage = GlobalUsage();

  int _validDays = 0;
  Future<void> _getRemainValidDays() async {
    // Get the current date and time
    DateTime now = DateTime.now();
    DateTime? expiryDate = await _globalUsage.getExpiryDate();
    if (expiryDate != null) {
      int diffInHours = expiryDate.difference(now).inHours;
      _validDays = (diffInHours / 24).floor();
    }
  }

// This function fetches clinic info by instantiation
  void _retrieveClinics() async {
    try {
      clinics = await _globalUsage.retrieveClinics();
      setState(() {
        firstClinicID = clinics[0]["clinicId"];
        firstClinicName = clinics[0]["clinicName"];
        firstClinicAddr = clinics[0]["clinicAddr"];
        firstClinicPhone1 = clinics[0]["clinicPhone1"];
        firstClinicPhone2 = clinics[0]["clinicPhone2"];
        firstClinicEmail = clinics[0]["clinicEmail"];
        if (clinics[0]["clinicLogo"] is Uint8List) {
          firstClinicLogo = clinics[0]["clinicLogo"];
        } else if (clinics[0]["clinicLogo"] == null) {
          print('clinicLogo is null');
        } else {
          // Handle the case when clinicLogo is not a Uint8List
          print('clinicLogo is not a Uint8List');
        }
      }); // Call setState to trigger a rebuild of the widget with the new data.
    } catch (e) {
      print('No clinic found.');
    }
  }

  @override
  Widget build(BuildContext context) {
    /*  final userData =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>;
    final staffId = userData["staffID"];
    final staffRole = userData["role"]; */
    // Fetch translations keys based on the selected language.
    var languageProvider = Provider.of<LanguageProvider>(context);
    selectedLanguage = languageProvider.selectedLanguage;
    isEnglish = selectedLanguage == 'English';
    return ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        builder: (context, child) {
          final languageProvider = Provider.of<LanguageProvider>(context);
          final isEnglish = languageProvider.selectedLanguage == 'English';
          return MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate
            ],
            supportedLocales: const [
              Locale('en', ''), // English, no country code
              Locale('fa', ''), // Dari, no country code
              Locale('ps', ''), // Pashto, no country code
            ],
            debugShowCheckedModeBanner: false,
            home: Directionality(
              textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
              child: Scaffold(
                appBar: AppBar(
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        firstClinicName ?? 'Your Clinic Name Goes Here',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        tooltip: 'تغییر معلومات کلینیک شما',
                        splashRadius: 22.0,
                        onPressed: () => _onAddClinicInfo().then(
                          (_) => _retrieveClinics(),
                        ),
                        icon: const Icon(Icons.mode_edit_outlined, size: 14.0),
                      ),
                    ],
                  ),
                  leading: Builder(
                    builder: (BuildContext context) {
                      // Assign translated values to be accessed by doughnut chart since directly translations cause the chart to get missing
                      _transExpenses =
                          translations[languageProvider.selectedLanguage]
                                  ?["Expenses"] ??
                              'Expenses';
                      _transEarnings =
                          translations[languageProvider.selectedLanguage]
                                  ?["Earnings"] ??
                              'Earnings';
                      _transReceivable =
                          translations[languageProvider.selectedLanguage]
                                  ?["Receivable"] ??
                              'Receivable';
                      return IconButton(
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                          setState(() {});
                        },
                        tooltip: translations[languageProvider.selectedLanguage]
                                ?["OpenDrawerMsg"] ??
                            '',
                        icon: const Icon(Icons.menu),
                      );
                    },
                  ),
                  actions: [
                    IconButton(
                        splashRadius: 25.0,
                        tooltip: 'Refresh',
                        onPressed: () => refresh(),
                        icon: const Icon(Icons.rotate_left_rounded)),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.09),
                    Visibility(
                      visible: _validDays < 4 ? true : false,
                      child: Container(
                        margin: const EdgeInsets.only(left: 200),
                        child: Center(
                          child: Card(
                            elevation: 5,
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Text(
                                'Your Product Key Will Expire in: $_validDays Days',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: ClipRect(
                          child: BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                            child: Container(
                              padding: const EdgeInsets.all(6.0),
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade200.withOpacity(0.1)),
                              child: const _DigitalClock(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15.0),
                  ],
                ),
                drawer: Sidebar(),
                body: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 150),
                    ),
                    Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 50.0),
                          child: Row(
                            children: [
                              Card(
                                color: Colors.indigo,
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.16,
                                  width:
                                      MediaQuery.of(context).size.width * 0.19,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.indigo[400],
                                        child: const Icon(
                                            Icons.supervised_user_circle,
                                            color: Colors.white),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.only(
                                            left: 15.0,
                                            top: 0.0,
                                            right: 15.0,
                                            bottom: 0.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                                (translations[languageProvider
                                                                .selectedLanguage]
                                                            ?['TodayPatient'] ??
                                                        '')
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontSize: 16.0,
                                                    color: Colors.white)),
                                            Text(
                                                '$_todaysPatients ${(translations[languageProvider.selectedLanguage]?['People'] ?? '').toString()}',
                                                style: const TextStyle(
                                                    fontSize: 16.0,
                                                    color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Card(
                                color: Colors.orange,
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.16,
                                  width:
                                      MediaQuery.of(context).size.width * 0.19,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.orange[400],
                                        child: const Icon(
                                            Icons.attach_money_rounded,
                                            color: Colors.white),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.only(
                                            left: 15.0,
                                            top: 0.0,
                                            right: 15.0,
                                            bottom: 0.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                                (translations[languageProvider
                                                                .selectedLanguage]
                                                            ?[
                                                            'CurrentMonthExpenses'] ??
                                                        '')
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontSize: 16.0,
                                                    color: Colors.white)),
                                            Text(
                                                '$_currentMonthExp ${(translations[languageProvider.selectedLanguage]?['Afn'] ?? '').toString()}',
                                                style: const TextStyle(
                                                    fontSize: 16.0,
                                                    color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Card(
                                color: Colors.green,
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.16,
                                  width:
                                      MediaQuery.of(context).size.width * 0.19,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.green[400],
                                        child: const Icon(
                                            Icons.money_off_csred_outlined,
                                            color: Colors.white),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.only(
                                            left: 15.0,
                                            top: 0.0,
                                            right: 15.0,
                                            bottom: 0.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                                (translations[languageProvider
                                                                .selectedLanguage]
                                                            ?[
                                                            'CurrentYearTaxes'] ??
                                                        '')
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontSize: 16.0,
                                                    color: Colors.white)),
                                            Text(
                                                '$_curYearTax ${(translations[languageProvider.selectedLanguage]?['Afn'] ?? '').toString()}',
                                                style: const TextStyle(
                                                    fontSize: 16.0,
                                                    color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Card(
                                color: Colors.brown,
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.16,
                                  width:
                                      MediaQuery.of(context).size.width * 0.19,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.brown[400],
                                        child: const Icon(Icons.people_outline,
                                            color: Colors.white),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.only(
                                            left: 15.0,
                                            top: 0.0,
                                            right: 15.0,
                                            bottom: 0.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                                (translations[languageProvider
                                                                .selectedLanguage]
                                                            ?['AllPatients'] ??
                                                        '')
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontSize: 16.0,
                                                    color: Colors.white)),
                                            Text(
                                                '$_allPatients ${(translations[languageProvider.selectedLanguage]?['People'] ?? '').toString()}',
                                                style: const TextStyle(
                                                    fontSize: 16.0,
                                                    color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 30.0),
                          child: Row(
                            children: [
                              Card(
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.6,
                                  width:
                                      MediaQuery.of(context).size.width * 0.47,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (!_isPatientDataInitialized)
                                        const CircularProgressIndicator()
                                      else
                                        SfCartesianChart(
                                            primaryXAxis: CategoryAxis(),
                                            title: ChartTitle(
                                                text: (translations[languageProvider
                                                                .selectedLanguage]
                                                            ?[
                                                            'LastSixMonthPatients'] ??
                                                        '')
                                                    .toString()),
                                            // Enable legend
                                            legend: Legend(isVisible: true),
                                            // Enable tooltip
                                            tooltipBehavior: TooltipBehavior(
                                              enable: true,
                                              format:
                                                  'point.y ${(translations[languageProvider.selectedLanguage]?['People'] ?? '').toString()} : point.x',
                                            ),
                                            series: <ChartSeries<_PatientsData,
                                                String>>[
                                              LineSeries<_PatientsData, String>(
                                                  animationDuration:
                                                      CircularProgressIndicator
                                                          .strokeAlignCenter,
                                                  dataSource: patientData,
                                                  xValueMapper:
                                                      (_PatientsData patients,
                                                              _) =>
                                                          patients.month,
                                                  yValueMapper: (_PatientsData
                                                              patients,
                                                          _) =>
                                                      patients.numberOfPatient,
                                                  name: (translations[languageProvider
                                                                  .selectedLanguage]
                                                              ?['Patients'] ??
                                                          '')
                                                      .toString(),
                                                  // Enable data label
                                                  dataLabelSettings:
                                                      const DataLabelSettings(
                                                          isVisible: true))
                                            ]),
                                    ],
                                  ),
                                ),
                              ),
                              Card(
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.6,
                                  width:
                                      MediaQuery.of(context).size.width * 0.3,
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(15.0),
                                            child: SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.1,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.06,
                                              child: InputDecorator(
                                                decoration: InputDecoration(
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8.0),
                                                  border:
                                                      const OutlineInputBorder(),
                                                  labelText: translations[
                                                              languageProvider
                                                                  .selectedLanguage]
                                                          ?["DDLDuration"] ??
                                                      '',
                                                  enabledBorder:
                                                      const OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          10.0)),
                                                          borderSide:
                                                              BorderSide(
                                                                  color: Colors
                                                                      .grey)),
                                                  focusedBorder:
                                                      const OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          10.0)),
                                                          borderSide:
                                                              BorderSide(
                                                                  color: Colors
                                                                      .blue)),
                                                ),
                                                child:
                                                    DropdownButtonHideUnderline(
                                                  child: SizedBox(
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.03,
                                                    child: ButtonTheme(
                                                      alignedDropdown: true,
                                                      child: DropdownButton(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        // isExpanded: true,
                                                        icon: const Icon(Icons
                                                            .arrow_drop_down),
                                                        value: incomeDuration,

                                                        items: <String>[
                                                          '1 Month',
                                                          '3 Months',
                                                          '6 Months',
                                                          '9 Months',
                                                          '12 Months'
                                                        ].map<
                                                            DropdownMenuItem<
                                                                String>>((String
                                                            value) {
                                                          return DropdownMenuItem<
                                                              String>(
                                                            value: value,
                                                            child: Text(value,
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodyMedium),
                                                          );
                                                        }).toList(),
                                                        onChanged:
                                                            (String? newValue) {
                                                          setState(() {
                                                            incomeDuration =
                                                                newValue!;
                                                            _getPieData();
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      /* SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.05),
 */
                                      FutureBuilder<List<_PieDataIncome>>(
                                        future: _getPieData(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.4,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.4,
                                              child: SfCircularChart(
                                                margin: EdgeInsets.zero,
                                                legend: Legend(
                                                    isVisible: true,
                                                    isResponsive: true,
                                                    overflowMode:
                                                        LegendItemOverflowMode
                                                            .wrap),
                                                tooltipBehavior:
                                                    TooltipBehavior(
                                                  color: const Color.fromARGB(
                                                      255, 106, 105, 105),
                                                  tooltipPosition:
                                                      TooltipPosition.auto,
                                                  textStyle: const TextStyle(
                                                      fontSize: 12.0),
                                                  enable: true,
                                                  format:
                                                      'point.y ${translations[languageProvider.selectedLanguage]?['Afn'] ?? ''}',
                                                ),
                                                annotations: [
                                                  CircularChartAnnotation(
                                                    widget: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(3.0),
                                                          child: netIncome >= 0
                                                              ? Text(
                                                                  translations[languageProvider
                                                                              .selectedLanguage]
                                                                          ?[
                                                                          "Profit"] ??
                                                                      '',
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .labelSmall!
                                                                      .copyWith(
                                                                          fontWeight: FontWeight
                                                                              .bold,
                                                                          fontSize:
                                                                              MediaQuery.of(context).size.width * 0.009),
                                                                )
                                                              : Text(
                                                                  translations[languageProvider
                                                                              .selectedLanguage]
                                                                          ?[
                                                                          "Loss"] ??
                                                                      '',
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .labelSmall!
                                                                      .copyWith(
                                                                          color: Colors
                                                                              .red,
                                                                          fontWeight: FontWeight
                                                                              .bold,
                                                                          fontSize:
                                                                              MediaQuery.of(context).size.width * 0.009),
                                                                ),
                                                        ),
                                                        netIncome >= 0
                                                            ? Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        3.0),
                                                                child: Text(
                                                                  '${netIncome.toString()} ${translations[languageProvider.selectedLanguage]?["Afn"] ?? ''}',
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .labelSmall!
                                                                      .copyWith(
                                                                          fontSize: MediaQuery.of(context).size.width *
                                                                              0.009,
                                                                          fontWeight:
                                                                              FontWeight.bold),
                                                                ),
                                                              )
                                                            : Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        3.0),
                                                                child: Text(
                                                                  '${netIncome.toString()} ${translations[languageProvider.selectedLanguage]?["Afn"] ?? ''}',
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .labelSmall!
                                                                      .copyWith(
                                                                          color: Colors
                                                                              .red,
                                                                          fontSize: MediaQuery.of(context).size.width *
                                                                              0.009,
                                                                          fontWeight:
                                                                              FontWeight.bold),
                                                                ),
                                                              ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                                series: <CircularSeries>[
                                                  DoughnutSeries<_PieDataIncome,
                                                      String>(
                                                    explode: true,
                                                    explodeOffset: '10%',
                                                    dataSource: snapshot.data,
                                                    innerRadius: '70%',
                                                    explodeGesture:
                                                        ActivationMode
                                                            .singleTap,
                                                    dataLabelMapper:
                                                        (_PieDataIncome data,
                                                                _) =>
                                                            '${data.y} ${translations[languageProvider.selectedLanguage]?["Afn"] ?? ''}',
                                                    pointColorMapper:
                                                        (_PieDataIncome data,
                                                                _) =>
                                                            data.color,
                                                    xValueMapper:
                                                        (_PieDataIncome data,
                                                                _) =>
                                                            data.x,
                                                    yValueMapper:
                                                        (_PieDataIncome data,
                                                                _) =>
                                                            data.y,
                                                    dataLabelSettings:
                                                        DataLabelSettings(
                                                      isVisible: true,
                                                      labelPosition:
                                                          ChartDataLabelPosition
                                                              .inside,
                                                      connectorLineSettings:
                                                          const ConnectorLineSettings(
                                                              type:
                                                                  ConnectorType
                                                                      .line),
                                                      textStyle: TextStyle(
                                                          fontSize: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.0045,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    selectionBehavior:
                                                        SelectionBehavior(
                                                            enable: true,
                                                            selectedBorderWidth:
                                                                2.0),
                                                  )
                                                ],
                                              ),
                                            );
                                          } else if (snapshot.hasError) {
                                            return Text("${snapshot.error}");
                                          }
                                          return const CircularProgressIndicator();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            theme: ThemeData(useMaterial3: false),
          );
        });
  }

  Future<void> _onAddClinicInfo() async {
    TextEditingController clinicNameController = TextEditingController();
    TextEditingController clinicAddrController = TextEditingController();
    TextEditingController clinicPhoneController1 = TextEditingController();
    TextEditingController clinicPhoneController2 = TextEditingController();
    TextEditingController clinicEmailController = TextEditingController();
    final clinicFormKey = GlobalKey<FormState>();
    clinicNameController.text = firstClinicName ?? '';
    clinicAddrController.text = firstClinicAddr ?? '';
    clinicPhoneController1.text = firstClinicPhone1 ?? '';
    clinicPhoneController2.text = firstClinicPhone2 ?? '';
    clinicEmailController.text = firstClinicEmail ?? '';

    // ignore: use_build_context_synchronously
    return showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
              builder: (context, setState) {
                final clinicLogoMessage = ValueNotifier<String>('');
                return AlertDialog(
                  title: Directionality(
                    textDirection:
                        isEnglish ? TextDirection.ltr : TextDirection.rtl,
                    child: const Text('تغییر معلومات مربوط کلینیک شما',
                        style: TextStyle(color: Colors.blue)),
                  ),
                  content: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.39,
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Center(
                        child: SingleChildScrollView(
                          child: Form(
                            key: clinicFormKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            width: 1.0, color: Colors.blue),
                                        shape: BoxShape.circle,
                                      ),
                                      margin: const EdgeInsets.all(5.0),
                                      width: MediaQuery.of(context).size.width *
                                          0.06,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.06,
                                      child: ClipOval(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () async {
                                              setState(() {
                                                _isLodingLogo = true;
                                              });

                                              final result = await FilePicker
                                                  .platform
                                                  .pickFiles(
                                                      allowMultiple: true,
                                                      type: FileType.custom,
                                                      allowedExtensions: [
                                                    'ico',
                                                    'jpg',
                                                    'jpeg',
                                                    'png'
                                                  ]);
                                              if (result != null) {
                                                setState(() {
                                                  _isLodingLogo = false;
                                                  _selectedLogo = File(result
                                                      .files.single.path
                                                      .toString());
                                                });
                                              }
                                            },
                                            child: _selectedLogo == null &&
                                                    !_isLodingLogo
                                                ? Icon(Icons.add,
                                                    size: MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.015,
                                                    color: Colors.blue)
                                                : _isLodingLogo
                                                    ? const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                                strokeWidth:
                                                                    3.0))
                                                    : CircleAvatar(
                                                        radius:
                                                            50, // adjust the size of the CircleAvatar by changing the radius
                                                        backgroundImage:
                                                            FileImage(
                                                                _selectedLogo!),
                                                      ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_selectedLogo == null)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 8.0),
                                        child: Text(
                                          'لوگو را انتخاب کنید (اختیاری)',
                                          style: TextStyle(
                                              fontSize: 12.0,
                                              color: Colors.blue),
                                        ),
                                      ),
                                    ValueListenableBuilder<String>(
                                      valueListenable: clinicLogoMessage,
                                      builder: (context, value, child) {
                                        if (value.isEmpty) {
                                          return const SizedBox
                                              .shrink(); // or Container()
                                        } else {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8.0),
                                            child: SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.3,
                                              child: Text(
                                                value,
                                                style: const TextStyle(
                                                    fontSize: 12.0,
                                                    color: Colors.redAccent),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    )
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      '*',
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.335,
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 10.0, horizontal: 20.0),
                                      child: TextFormField(
                                        autovalidateMode:
                                            AutovalidateMode.always,
                                        controller: clinicNameController,
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return 'نام کلینیک الزامی میباشد.';
                                          } else if (value.length < 10 ||
                                              value.length > 35) {
                                            return 'نام کلینیک باید بیشتر از 10 حرف و کمتر از 35 حرف باشد.';
                                          }
                                          return null;
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(GlobalUsage.allowedEPChar))
                                        ],
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: 'نام کلینیک',
                                          suffixIcon: Icon(Icons.info_outline),
                                          enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(50.0)),
                                              borderSide: BorderSide(
                                                  color: Colors.grey)),
                                          focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(50.0)),
                                              borderSide: BorderSide(
                                                  color: Colors.blue)),
                                          errorBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(50.0)),
                                              borderSide: BorderSide(
                                                  color: Colors.red)),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(
                                                              50.0)),
                                                  borderSide: BorderSide(
                                                      color: Colors.red,
                                                      width: 1.5)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      '*',
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.335,
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 10.0, horizontal: 20.0),
                                      child: TextFormField(
                                        autovalidateMode:
                                            AutovalidateMode.always,
                                        controller: clinicAddrController,
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return 'آدرس کلینیک الزامی میباشد.';
                                          } else if (value.length < 10 ||
                                              value.length > 40) {
                                            return 'آدرس کلینیک باید بیشتر از 10 حرف و کمتر از 40 حرف باشد.';
                                          }
                                          return null;
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(GlobalUsage.allowedEPChar),
                                          ),
                                        ],
                                        minLines: 1,
                                        maxLines: 2,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: 'آدرس کلینیک',
                                          suffixIcon: Icon(
                                              Icons.edit_location_outlined),
                                          enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(50.0)),
                                              borderSide: BorderSide(
                                                  color: Colors.grey)),
                                          focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(50.0)),
                                              borderSide: BorderSide(
                                                  color: Colors.blue)),
                                          errorBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(50.0)),
                                              borderSide: BorderSide(
                                                  color: Colors.red)),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(
                                                              50.0)),
                                                  borderSide: BorderSide(
                                                      color: Colors.red,
                                                      width: 1.5)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.335,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 20.0),
                                  child: TextFormField(
                                    textDirection: TextDirection.ltr,
                                    autovalidateMode: AutovalidateMode.always,
                                    controller: clinicPhoneController1,
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return 'این نمبر الزامی میباشد.';
                                      } else if (value.startsWith('07') ||
                                          value.startsWith('۰۷')) {
                                        if (value.length < 10 ||
                                            value.length > 10) {
                                          return 'نمبر تماس باید 10 رقم باشد.';
                                        }
                                      } else if (value.startsWith('+93') ||
                                          value.startsWith('+۹۳')) {
                                        if (value.length < 12 ||
                                            value.length > 12) {
                                          return 'نمبر تماس همراه با کود کشور باید 12 رقم باشد.';
                                        }
                                      } else {
                                        return 'نمبر تماس نا معتبر است.';
                                      }
                                      return null;
                                    },
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(GlobalUsage.allowedDigits),
                                      ),
                                    ],
                                    minLines: 1,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'نمبر تماس 1',
                                      suffixIcon:
                                          Icon(Icons.phone_enabled_outlined),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50.0)),
                                          borderSide:
                                              BorderSide(color: Colors.grey)),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50.0)),
                                          borderSide:
                                              BorderSide(color: Colors.blue)),
                                      errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50.0)),
                                          borderSide:
                                              BorderSide(color: Colors.red)),
                                      focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50.0)),
                                          borderSide: BorderSide(
                                              color: Colors.red, width: 1.5)),
                                    ),
                                  ),
                                ),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.335,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 20.0),
                                  child: TextFormField(
                                    textDirection: TextDirection.ltr,
                                    autovalidateMode: AutovalidateMode.always,
                                    controller: clinicPhoneController2,
                                    validator: (value) {
                                      if (value!.isNotEmpty) {
                                        if (value.startsWith('07') ||
                                            value.startsWith('۰۷')) {
                                          if (value.length < 10 ||
                                              value.length > 10) {
                                            return 'نمبر تماس باید 10 رقم باشد.';
                                          }
                                        } else if (value.startsWith('+93') ||
                                            value.startsWith('+۹۳')) {
                                          if (value.length < 12 ||
                                              value.length > 12) {
                                            return 'نمبر تماس همراه با کود کشور باید 12 رقم باشد.';
                                          }
                                        } else if (value ==
                                            clinicPhoneController1.text) {
                                          return 'نمبر تماس های کلینیک باید متفاوت باشد.';
                                        } else {
                                          return 'نمبر تماس نا معتبر است.';
                                        }
                                      }
                                      return null;
                                    },
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(GlobalUsage.allowedDigits),
                                      ),
                                    ],
                                    minLines: 1,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'نمبر تماس 2',
                                      suffixIcon:
                                          Icon(Icons.phone_enabled_outlined),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50.0)),
                                          borderSide:
                                              BorderSide(color: Colors.grey)),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50.0)),
                                          borderSide:
                                              BorderSide(color: Colors.blue)),
                                      errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50.0)),
                                          borderSide:
                                              BorderSide(color: Colors.red)),
                                      focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50.0)),
                                          borderSide: BorderSide(
                                              color: Colors.red, width: 1.5)),
                                    ),
                                  ),
                                ),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.335,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 20.0),
                                  child: TextFormField(
                                    textDirection: TextDirection.ltr,
                                    autovalidateMode: AutovalidateMode.always,
                                    controller: clinicEmailController,
                                    validator: (value) {
                                      if (value!.isNotEmpty) {
                                        const pattern =
                                            r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$';
                                        final regex = RegExp(pattern);
                                        return !regex.hasMatch(value)
                                            ? 'ایمیل آدرس نا معتبر است.'
                                            : null;
                                      }
                                      return null;
                                    },
                                    minLines: 1,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'ایمیل آدرس',
                                      suffixIcon: Icon(Icons.email_outlined),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50.0)),
                                          borderSide:
                                              BorderSide(color: Colors.grey)),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50.0)),
                                          borderSide:
                                              BorderSide(color: Colors.blue)),
                                      errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50.0)),
                                          borderSide:
                                              BorderSide(color: Colors.red)),
                                      focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50.0)),
                                          borderSide: BorderSide(
                                              color: Colors.red, width: 1.5)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    Row(
                      mainAxisAlignment: isEnglish
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        TextButton(
                            onPressed: () =>
                                Navigator.of(context, rootNavigator: true)
                                    .pop(),
                            child: const Text('لغو')),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              if (clinicFormKey.currentState!.validate()) {
                                final conn = await onConnToSqliteDb();
                                if (_selectedLogo != null) {
                                  // It should not allow clinic logo size with size more than 1MB.
                                  var logoSizeBytes =
                                      await _selectedLogo!.readAsBytes();
                                  if (logoSizeBytes.length > 1024 * 1024) {
                                    clinicLogoMessage.value =
                                        'The logo size should not be more 1MB.';
                                  } else {
                                    var editResults = await conn.rawUpdate(
                                        'UPDATE clinics SET clinic_name = ?, clinic_address = ?, clinic_phone1 = ?, clinic_phone2 = ?, clinic_email = ?, clinic_logo = ? WHERE clinic_ID = ?',
                                        [
                                          clinicNameController.text,
                                          clinicAddrController.text.isNotEmpty
                                              ? clinicAddrController.text
                                              : '',
                                          clinicPhoneController1.text.isNotEmpty
                                              ? clinicPhoneController1.text
                                              : '',
                                          clinicPhoneController2.text.isNotEmpty
                                              ? clinicPhoneController2.text
                                              : '',
                                          clinicEmailController.text.isNotEmpty
                                              ? clinicEmailController.text
                                              : '',
                                          logoSizeBytes,
                                          int.parse(firstClinicID!)
                                        ]);
                                    if (editResults > 0) {
                                      // ignore: use_build_context_synchronously
                                      Navigator.of(context, rootNavigator: true)
                                          .pop();
                                    } else {
                                      print('Updating the clinic failed!');
                                    }
                                  }
                                } else {
                                  var editResults = await conn.rawUpdate(
                                      'UPDATE clinics SET clinic_name = ?, clinic_address = ?, clinic_phone1 = ?, clinic_phone2 = ?, clinic_email = ? WHERE clinic_ID = ?',
                                      [
                                        clinicNameController.text,
                                        clinicAddrController.text.isNotEmpty
                                            ? clinicAddrController.text
                                            : '',
                                        clinicPhoneController1.text.isNotEmpty
                                            ? clinicPhoneController1.text
                                            : '',
                                        clinicPhoneController2.text.isNotEmpty
                                            ? clinicPhoneController2.text
                                            : '',
                                        clinicEmailController.text.isNotEmpty
                                            ? clinicEmailController.text
                                            : '',
                                        int.parse(firstClinicID!)
                                      ]);
                                  if (editResults > 0) {
                                    // ignore: use_build_context_synchronously
                                    Navigator.of(context, rootNavigator: true)
                                        .pop();
                                  } else {
                                    print('Updating the clinic failed!');
                                  }
                                }
                              }
                            } catch (e) {
                              print('Editing clinic info failed: $e');
                            }
                          },
                          child: const Text('تغییر'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ));
  }
}

// This class only belongs to digital clock to be separated from other widgets like charts, cards, ... to not affect state management of them.
class _DigitalClock extends StatefulWidget {
  const _DigitalClock({Key? key}) : super(key: key);

  @override
  State<_DigitalClock> createState() => __DigitalClockState();
}

class __DigitalClockState extends State<_DigitalClock> {
  // Display timing in the dasboard appbar
  late String _timeString;
  void _getTime() {
    final DateTime now = DateTime.now();
    final String formattedDateTime = _formatDateTime(now);
    if (mounted) {
      setState(() {
        _timeString = formattedDateTime;
      });
    }
  }

// Format datetime to display hours, minutes and seconds
  String _formatDateTime(DateTime dateTime) {
    return intl.DateFormat('hh:mm:ss a').format(dateTime);
  }

  @override
  void initState() {
    super.initState();
    // Call to display date and time
    _timeString = _formatDateTime(DateTime.now());
    Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _timeString,
      style: Theme.of(context).textTheme.displaySmall!.copyWith(
          fontSize: 26.0,
          color: Colors.yellow[200],
          fontFamily: 'digital-7',
          fontWeight: FontWeight.bold),
    );
  }
}

class _PatientsData {
  _PatientsData(this.month, this.numberOfPatient);

  final String month;
  final double numberOfPatient;
}

class _PieDataIncome {
  _PieDataIncome(this.x, this.y, this.color);
  final String x;
  final num y;
  final Color color;
}
