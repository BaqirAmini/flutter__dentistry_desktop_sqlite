// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dentistry/config/developer_options.dart';
import 'package:flutter_dentistry/config/global_usage.dart';
import 'package:flutter_dentistry/config/private/private.dart';
import 'package:flutter_dentistry/config/settings_provider.dart';
import 'package:flutter_dentistry/views/settings/settings.dart';
import 'dart:io';
import 'package:flutter_dentistry/views/staff/staff_info.dart';
import 'package:flutter_dentistry/models/db_conn.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart' as INTL;
import 'package:flutter_dentistry/config/translations.dart';
import 'package:flutter_dentistry/config/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

FilePickerResult? filePickerResult;
File? pickedFile;

// ignore: prefer_typing_uninitialized_variables
var selectedLanguage;
// ignore: prefer_typing_uninitialized_variables
var isEnglish;

var selectedDateType;
var isGregorian;
bool isProVersionActivated = false;

bool _isLoadingPhoto = false;
// Create the global key at the top level of your Dart file
final GlobalKey<ScaffoldMessengerState> _globalKeyForProfile =
    GlobalKey<ScaffoldMessengerState>();

// This is shows snackbar when called
void _onShowSnack(Color backColor, String msg) {
  _globalKeyForProfile.currentState?.showSnackBar(
    SnackBar(
      backgroundColor: backColor,
      content: SizedBox(
        height: 20.0,
        child: Center(
          child: Text(msg),
        ),
      ),
    ),
  );
}

class SettingsMenu extends StatefulWidget {
  const SettingsMenu({Key? key}) : super(key: key);

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  // form controllers
  final TextEditingController _machineCodeCtrl = TextEditingController();
  final TextEditingController _liscenseController = TextEditingController();
  final _licenseKey4CrownPro = GlobalKey<FormState>();
  bool _isCoppied = false;
  bool _notVerified = false;
  String _verifyMsg = '';
  final GlobalUsage _globalUsage = GlobalUsage();
  // Declare this method for refreshing UI of staff info
  void _onUpdate() {
    setState(() {});
  }

// This dialog is to renew the license key (product key) of Crown
  _onVerifyLicenseKey(
      BuildContext context, bool? selectedVersion, Function refresh) {
    _machineCodeCtrl.text = _globalUsage.getMachineGuid();
    _isCoppied = false;
    _notVerified = false;
    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Purchase Your License Key',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium!
                  .copyWith(color: Colors.blue)),
          content: Form(
            key: _licenseKey4CrownPro,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.vpn_key_outlined,
                          size: MediaQuery.of(context).size.width * 0.03,
                          color: Colors.blue),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01),
                      Text(
                        'License Key Verification',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(color: Colors.blue),
                      ),
                      const SizedBox(height: 10.0),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: Text(_globalUsage.productKeyRelatedMsg,
                            style: Theme.of(context).textTheme.labelLarge),
                      ),
                      const SizedBox(height: 50.0),
                      Container(
                        margin: const EdgeInsets.all(10.0),
                        width: MediaQuery.of(context).size.width * 0.50,
                        child: Builder(builder: (context) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Machine Code',
                                  style:
                                      Theme.of(context).textTheme.labelLarge),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.42,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      readOnly: true,
                                      textDirection: TextDirection.ltr,
                                      controller: _machineCodeCtrl,
                                      decoration: InputDecoration(
                                        suffixIcon: IconButton(
                                          tooltip: 'Copy',
                                          splashRadius: 18.0,
                                          onPressed: _machineCodeCtrl
                                                  .text.isEmpty
                                              ? null
                                              : () async {
                                                  await Clipboard.setData(
                                                    ClipboardData(
                                                        text: _machineCodeCtrl
                                                            .text),
                                                  );

                                                  setState(() {
                                                    _isCoppied = true;
                                                  });

                                                  /*   ClipboardData?
                                                                      clipboardData =
                                                                      await Clipboard
                                                                          .getData(
                                                                              Clipboard
                                                                                  .kTextPlain);
                                                                  String?
                                                                      copiedText =
                                                                      clipboardData
                                                                          ?.text;
                                                                  print(
                                                                      'The copy value: $copiedText'); */
                                                },
                                          icon: const Icon(Icons.copy,
                                              size: 15.0),
                                        ),
                                        enabledBorder: const OutlineInputBorder(
                                          borderSide:
                                              BorderSide(color: Colors.grey),
                                        ),
                                        focusedBorder: const OutlineInputBorder(
                                          borderSide:
                                              BorderSide(color: Colors.blue),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.all(15.0),
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                    if (_isCoppied)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 5.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Icon(
                                                Icons
                                                    .check_circle_outline_outlined,
                                                color: Colors.green,
                                                size: 16.0),
                                            SizedBox(width: 5.0),
                                            Text(
                                              'Copied',
                                              style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.0),
                                            ),
                                          ],
                                        ),
                                      )
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                      Container(
                        margin: const EdgeInsets.all(10.0),
                        width: MediaQuery.of(context).size.width * 0.50,
                        child: Builder(
                          builder: (context) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Product Key',
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.42,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        textDirection: TextDirection.ltr,
                                        controller: _liscenseController,
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return 'Enter the product key.';
                                          }
                                          return null;
                                        },

                                        /*  inputFormatters: [
                                                                          FilteringTextInputFormatter.allow(
                                                                            RegExp(_regExUName),
                                                                          ),
                                                                        ], */
                                        decoration: const InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                            borderSide:
                                                BorderSide(color: Colors.grey),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide:
                                                BorderSide(color: Colors.blue),
                                          ),
                                          contentPadding: EdgeInsets.all(15.0),
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      if (_notVerified)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5.0),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.info_outline,
                                                  color: Colors.red,
                                                  size: 17.0),
                                              const SizedBox(width: 5.0),
                                              Text(
                                                _verifyMsg,
                                                style: const TextStyle(
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12.0),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Builder(
                            builder: (context) {
                              return ElevatedButton.icon(
                                  onPressed: () async {
                                    if (_licenseKey4CrownPro.currentState!
                                        .validate()) {
                                      try {
                                        // Decrypt the liscense key
                                        String decryptedValue =
                                            _globalUsage.decryptProductKey(
                                                _liscenseController.text,
                                                secretKey);

                                        // Expiry date is string
                                        String expiryDateString =
                                            decryptedValue.substring(
                                                _machineCodeCtrl.text.length);
                                        // Convert this string to datetime
                                        DateTime expiryDate =
                                            DateTime.parse(expiryDateString);

                                        // Now re-encrypt the machine code with the fetched datetime (expiry datetime) to use for verification in below.
                                        String reEncryptedValue =
                                            _globalUsage.generateProductKey(
                                                expiryDate,
                                                _machineCodeCtrl.text);

                                        // Store the expiry date temporarely which will be required later
                                        await _globalUsage
                                            .storeExpiryDate(expiryDate);
                                        if (reEncryptedValue ==
                                            _liscenseController.text) {
                                          if (await _globalUsage
                                              .hasLicenseKeyExpired()) {
                                            setState(() {
                                              _notVerified = true;
                                              _verifyMsg =
                                                  'Sorry, this product key has expired. Please purchase the new one.';
                                            });
                                            Provider.of<SettingsProvider>(
                                                    context,
                                                    listen: false)
                                                .setSelectedVersion = false;
                                            final prefs =
                                                await SharedPreferences
                                                    .getInstance();
                                            prefs.setString(
                                                'crownType', 'Standard');
                                            GlobalUsage.onReload!();
                                            refresh();
                                          } else {
                                            await _globalUsage
                                                .storeExpiryDate(expiryDate);
                                            await _globalUsage
                                                .storeLicenseKey4User(
                                                    _liscenseController.text);

                                            Provider.of<SettingsProvider>(
                                                    context,
                                                    listen: false)
                                                .setSelectedVersion = true;
                                            isProVersionActivated = true;

                                            final prefs =
                                                await SharedPreferences
                                                    .getInstance();
                                            prefs.setString(
                                                'crownType', 'Premium');
                                            Navigator.pop(context);

                                            _onShowSnack(Colors.green,
                                                'Congratulations, your product key updated!');
                                          }
                                        } else {
                                          setState(() {
                                            _notVerified = false;
                                            _verifyMsg =
                                                'Sorry, this product key is not valid!';
                                          });
                                        }
                                      } catch (e) {
                                        setState(() {
                                          _notVerified = true;
                                          _verifyMsg =
                                              'Sorry, invalid product key inserted.';
                                        });
                                        print('Exception: $e');
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.verified),
                                  label: const Text('Verify'));
                            },
                          ),
                          Builder(
                            builder: (context) {
                              return TextButton(
                                  onPressed: () =>
                                      Navigator.of(context, rootNavigator: true)
                                          .pop(),
                                  child: const Text('لغو'));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

// This function is to switch Freemium to PRO version of Crown
  Widget _onSwitch2ProVersion() {
    return FutureBuilder(
      future: getSelectedCrownVersion(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            bool? selectedCrownVersion = snapshot.data;
            return StatefulBuilder(
              builder: (context, setState) {
                return StatefulBuilder(
                  builder: (context, setState) {
                    return Card(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'خریداری نسخه ممتاز',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [Colors.purple, Colors.blueAccent],
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'چرا نسخه ممتاز؟',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'نسخه ممتاز کرون دارای قابلیت های مهم دیگر است که شما را قادر میسازد تا: ',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      '1 - تعداد مریض های نا محدود را ثبت کنید.',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      '2 - تعداد مصارف نا محدود را ثبت کنید.',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.3,
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        '3 - جلسات آینده برای مریض های تان ترتیب دهید که سیستم به شما پیش از جلسه ترتیب شده هشدار میدهد.',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      '4 - برای اینکه اطلاعات کلینک تان از بین نرود، پشتیبان گیری کنید.',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      '5 - نسخه ای کمپیوتری برای مریض های تان تجویز کنید.',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      '6 - اکسری  مریض های تانرا مدیریت کنید (X-Ray).',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      '7 - ده کارمند برای کلینیک تا ثبت کنید.',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      '8 - پنج یوزر (کابر) ایجاد کنید که هر کاربر از حساب یا اکونت خودش وارد سیستم شود.',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  // Add more Text widgets here for each con
                                ],
                              ),
                            ),
                            const SizedBox(height: 15.0),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.3,
                              height:
                                  MediaQuery.of(context).size.height * 0.035,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                  side: const BorderSide(
                                    color: Colors.green,
                                  ),
                                ),
                                onPressed: () => _onVerifyLicenseKey(
                                    context, selectedCrownVersion, () {
                                  setState(
                                    () {},
                                  );
                                }),
                                child: Text('خریداری نسخه ممتاز',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge!
                                        .copyWith(color: Colors.green)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
        }
      },
    );
  }

  int _selectedIndex = 1;
  @override
  Widget build(BuildContext context) {
    _fetchPath();
    // Assign the method declared above to static function for later use
    StaffInfo.onUpdateProfile = _onUpdate;
    GlobalUsage.onReload = _onUpdate;
    // Fetch translations keys based on the selected language.
    var languageProvider = Provider.of<LanguageProvider>(context);
    selectedLanguage = languageProvider.selectedLanguage;
    isEnglish = selectedLanguage == 'English';

    // Fetching date type (Hijri or Gregorian) from provider
    var datetypeProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    selectedDateType = datetypeProvider.selectedDateType;
    isGregorian = selectedDateType == 'میلادی';

    // Fetching date type (Hijri or Gregorian) from provider
    var crownVerProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    isProVersionActivated = crownVerProvider.getSelectedVersion;

    return ScaffoldMessenger(
      key: _globalKeyForProfile,
      child: Scaffold(
        body: Row(
          children: [
            Directionality(
              textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
              child: Flexible(
                flex: 1,
                child: Card(
                  margin: const EdgeInsets.only(left: 0.0),
                  child: ListView(
                    children: [
                      ListTile(
                        title: Text(
                          translations[selectedLanguage]?['PersonalInfo'] ?? '',
                          style: const TextStyle(
                              color: Color.fromARGB(255, 119, 118, 118),
                              fontSize: 14),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(
                            translations[selectedLanguage]?['MyProfile'] ?? ''),
                        onTap: () {
                          setState(() {
                            _selectedIndex = 1;
                          });
                        },
                      ),
                      const Divider(),
                      ListTile(
                        title: Text(
                          translations[selectedLanguage]?['Security'] ?? '',
                          style: const TextStyle(
                              color: Color.fromARGB(255, 119, 118, 118),
                              fontSize: 14),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.key_outlined),
                        title: Text(
                            translations[selectedLanguage]?['ChangePwd'] ?? ''),
                        onTap: () {
                          setState(() {
                            _selectedIndex = 2;
                          });
                        },
                      ),
                      const Divider(),
                      ListTile(
                        title: Text(
                          translations[selectedLanguage]?['Sync'] ?? '',
                          style: const TextStyle(
                              color: Color.fromARGB(255, 119, 118, 118),
                              fontSize: 14),
                        ),
                      ),
                      if (Features.createBackup)
                        ListTile(
                          leading: const Icon(Icons.backup_outlined),
                          title: Text(
                              translations[selectedLanguage]?['Backup'] ?? ''),
                          onTap: () {
                            setState(() {
                              _selectedIndex = 3;
                            });
                          },
                        )
                      else
                        ListTile(
                          leading: const Icon(Icons.backup_outlined),
                          trailing: const Icon(Icons.workspace_premium_outlined,
                              color: Colors.red),
                          title: Text(
                              translations[selectedLanguage]?['Backup'] ?? ''),
                          onTap: () => _onShowSnack(
                              Colors.red,
                              translations[selectedLanguage]
                                      ?['PremAppPurchase'] ??
                                  ''),
                        ),
                      if (Features.restoreBackup)
                        ListTile(
                          leading: const Icon(Icons.restore_outlined),
                          title: Text(
                              translations[selectedLanguage]?['Restore'] ?? ''),
                          onTap: () {
                            setState(() {
                              _selectedIndex = 4;
                            });
                          },
                        )
                      else
                        ListTile(
                          leading: const Icon(Icons.backup_outlined),
                          trailing: const Icon(Icons.workspace_premium_outlined,
                              color: Colors.red),
                          title: Text(
                              translations[selectedLanguage]?['Backup'] ?? ''),
                          onTap: () => _onShowSnack(
                              Colors.red,
                              translations[selectedLanguage]
                                      ?['PremAppPurchase'] ??
                                  ''),
                        ),
                      const Divider(),
                      ListTile(
                        title: Text(
                          translations[selectedLanguage]?['SysRelated'] ?? '',
                          style: const TextStyle(
                              color: Color.fromARGB(255, 119, 118, 118),
                              fontSize: 14),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: Text(translations[selectedLanguage]
                                ?['ChangeCalendar'] ??
                            ''),
                        onTap: () {
                          setState(() {
                            _selectedIndex = 7;
                          });
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.color_lens_outlined),
                        title: Text(
                            translations[selectedLanguage]?['Theme'] ?? ''),
                        onTap: () {
                          setState(() {
                            _selectedIndex = 5;
                          });
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.language_rounded),
                        title: Text(
                            translations[selectedLanguage]?['Languages'] ?? ''),
                        onTap: () {
                          setState(() {
                            _selectedIndex = 6;
                          });
                        },
                      ),
                      isProVersionActivated
                          ? Card(
                              elevation: 1.5,
                              child: ListTile(
                                  leading: const Icon(
                                      Icons.workspace_premium_outlined,
                                      color: Colors.green),
                                  title: const Row(
                                    children: [
                                      Text(
                                        'PRO Activated',
                                        style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(width: 10.0),
                                      Icon(Icons.verified, color: Colors.green)
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedIndex = 8;
                                    });
                                  }),
                            )
                          : Card(
                              elevation: 1.5,
                              child: ListTile(
                                leading: const Icon(
                                    Icons.workspace_premium_outlined,
                                    color: Colors.green),
                                title: const Text('Switch to PRO Version',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold)),
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = 8;
                                  });
                                },
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
            Flexible(
              flex: 3,
              child: onShowSettingsItem(context, _selectedIndex, onUpdatePhoto),
            ),
          ],
        ),
      ),
    );
  }

// This method is to update profile picture of the user
  void onUpdatePhoto() async {
    setState(() {
      _isLoadingPhoto = true;
    });

    final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png']);
    if (result != null) {
      final conn = await onConnToSqliteDb();
      pickedFile = File(result.files.single.path.toString());
      final bytes = await pickedFile!.readAsBytes();
      // Check if the file size is larger than 1MB
      if (bytes.length > 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Center(
              child: Text('عکس حداکثر باید 1MB باشد.'),
            ),
          ),
        );
        setState(() {
          _isLoadingPhoto = false;
        });
        return;
      }
      // final photo = MySQL.escapeBuffer(bytes);
      var results = await conn.rawUpdate(
          'UPDATE staff SET photo = ? WHERE staff_ID = ?',
          [bytes, StaffInfo.staffID]);
      setState(() {
        if (results > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Center(
                child: Text('عکس پروفایل تان موفقانه تغییر کرد.'),
              ),
            ),
          );
          StaffInfo.userPhoto = bytes;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Center(
                child: Text('متاسفم، تغییر عکس پروفایل ناکام شد..'),
              ),
            ),
          );
        }
        setState(() {
          _isLoadingPhoto = false;
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Center(child: Text('هیچ عکسی را انتخاب نکردید.')),
        ),
      );
      setState(() {
        _isLoadingPhoto = false;
      });
    }
  }
}

// Switch between settings menu items
onShowSettingsItem(BuildContext context, int index,
    [void Function()? onUpdatePhoto, void Function()? onRefreshCrownVersion]) {
  if (index == 1) {
    return onShowProfile(context, onUpdatePhoto);
  } else if (index == 2) {
    return onChangePwd();
  } else if (index == 3) {
    return onBackUpData();
  } else if (index == 4) {
    return onRestoreData();
  } else if (index == 6) {
    return onChangeLang();
  } else if (index == 7) {
    return _onChangeDateType();
  } else if (index == 8) {
    return _SettingsMenuState()._onSwitch2ProVersion();
  } else {
    return const SizedBox.shrink();
  }
}

// Change/update password using this function
onChangePwd() {
// The global for the form
  final formKeyChangePwd = GlobalKey<FormState>();
// The text editing controllers for the TextFormFields
  final currentPwdController = TextEditingController();
  final newPwdController = TextEditingController();
  final unConfirmController = TextEditingController();
  bool isHiddenCurrentPwd = true;
  bool isHiddenNewPwd = true;
  bool isHiddenRetypePwd = true;
  return StatefulBuilder(
    builder: (context, setState) {
      // 1) Toggle to show/hide current password only using eye icons

      void toggleCurrentPassword() {
        setState(() {
          isHiddenCurrentPwd = !isHiddenCurrentPwd;
        });
      }

      // 2) Toggle to show/hide new password only using eye icons
      void toggleNewPassword() {
        setState(() {
          isHiddenNewPwd = !isHiddenNewPwd;
        });
      }

      // 3) Toggle to show/hide re-type password only using eye icons
      void toggleConfirmPassword() {
        setState(() {
          isHiddenRetypePwd = !isHiddenRetypePwd;
        });
      }

      return Card(
        child: Center(
          child: Form(
            key: formKeyChangePwd,
            child: SizedBox(
              width: 500.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      translations[selectedLanguage]?['LblCurrNewPwd'] ?? '',
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 8.0),
                    child: TextFormField(
                      textDirection:
                          isEnglish ? TextDirection.rtl : TextDirection.ltr,
                      controller: currentPwdController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return translations[selectedLanguage]
                                  ?['CurrPwdRequired'] ??
                              '';
                        }
                        return null;
                      },
                      obscureText: isHiddenCurrentPwd,
                      decoration: InputDecoration(
                        prefix: InkWell(
                          onTap: toggleCurrentPassword,
                          child: Icon(
                            isHiddenCurrentPwd
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.blue,
                          ),
                        ),
                        border: const OutlineInputBorder(),
                        labelText:
                            translations[selectedLanguage]?['CurrPwd'] ?? '',
                        suffixIcon: const Icon(Icons.password_rounded),
                        enabledBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(50.0)),
                            borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(50.0)),
                            borderSide: BorderSide(color: Colors.blue)),
                        errorBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(50.0)),
                            borderSide: BorderSide(color: Colors.red)),
                        focusedErrorBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(50.0)),
                            borderSide:
                                BorderSide(color: Colors.red, width: 1.5)),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 8.0),
                    child: TextFormField(
                      textDirection:
                          isEnglish ? TextDirection.rtl : TextDirection.ltr,
                      controller: newPwdController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return translations[selectedLanguage]
                                  ?['NewPwdRequired'] ??
                              '';
                        } else if (value.length < 6) {
                          return translations[selectedLanguage]?['Pwd6'] ?? '';
                        }
                      },
                      obscureText: isHiddenNewPwd,
                      decoration: InputDecoration(
                        prefix: InkWell(
                          onTap: toggleNewPassword,
                          child: Icon(
                            isHiddenNewPwd
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.blue,
                          ),
                        ),
                        border: const OutlineInputBorder(),
                        labelText:
                            translations[selectedLanguage]?['NewPwd'] ?? '',
                        suffixIcon: const Icon(Icons.password_rounded),
                        enabledBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(50.0)),
                            borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(50.0)),
                            borderSide: BorderSide(color: Colors.blue)),
                        errorBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(50.0)),
                            borderSide: BorderSide(color: Colors.red)),
                        focusedErrorBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(50.0)),
                            borderSide:
                                BorderSide(color: Colors.red, width: 1.5)),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 8.0),
                    child: TextFormField(
                      textDirection:
                          isEnglish ? TextDirection.rtl : TextDirection.ltr,
                      controller: unConfirmController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return translations[selectedLanguage]
                                  ?['NewPwdConfirm'] ??
                              '';
                        } else if (unConfirmController.text !=
                            newPwdController.text) {
                          return translations[selectedLanguage]
                                  ?['NewPwdNotMatch'] ??
                              '';
                        }
                      },
                      obscureText: isHiddenRetypePwd,
                      decoration: InputDecoration(
                        prefix: InkWell(
                          onTap: toggleConfirmPassword,
                          child: Icon(
                            isHiddenRetypePwd
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.blue,
                          ),
                        ),
                        border: const OutlineInputBorder(),
                        labelText: translations[selectedLanguage]
                                ?['ConfirmNewPwd'] ??
                            '',
                        hintStyle:
                            const TextStyle(color: Colors.grey, fontSize: 12.0),
                        hintText:
                            translations[selectedLanguage]?['PwdHint'] ?? '',
                        suffixIcon: const Icon(Icons.password_rounded),
                        enabledBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(50.0)),
                            borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(50.0)),
                            borderSide: BorderSide(color: Colors.blue)),
                        errorBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(50.0)),
                            borderSide: BorderSide(color: Colors.red)),
                        focusedErrorBorder: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(50.0)),
                            borderSide:
                                BorderSide(color: Colors.red, width: 1.5)),
                      ),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.23,
                    height: 35.0,
                    margin: const EdgeInsets.only(
                        left: 20.0, right: 20.0, top: 15.0, bottom: 15.0),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        side: const BorderSide(
                          color: Colors.blue,
                        ),
                      ),
                      onPressed: () async {
                        if (formKeyChangePwd.currentState!.validate()) {
                          try {
                            String currentPwd = currentPwdController.text;
                            String newPwd = newPwdController.text;
                            final conn = await onConnToSqliteDb();
                            // First make sure the current password matches.
                            var bytesForCurPwd = utf8.encode(currentPwd);
                            var digestForCurPwd =
                                sha256.convert(bytesForCurPwd);
                            String hashedCurPwd = digestForCurPwd.toString();
                            // Hash the newly inserted password
                            var bytesforNewPwd = utf8.encode(newPwd);
                            var digestForNewPwd =
                                sha256.convert(bytesforNewPwd);
                            String hashedNewPwd = digestForNewPwd.toString();
                            var results = await conn.rawQuery(
                                'SELECT * FROM staff_auth WHERE password = ?',
                                [hashedCurPwd]);

                            if (results.isNotEmpty) {
                              var updatedResult = await conn.rawUpdate(
                                  'UPDATE staff_auth SET password = ? WHERE staff_ID = ?',
                                  [hashedNewPwd, StaffInfo.staffID]);
                              if (updatedResult > 0) {
                                _onShowSnack(
                                    Colors.green,
                                    translations[selectedLanguage]
                                            ?['PwdSuccessMsg'] ??
                                        '');
                                currentPwdController.clear();
                                newPwdController.clear();
                                unConfirmController.clear();
                              } else {
                                _onShowSnack(
                                    Colors.red,
                                    translations[selectedLanguage]
                                            ?['StaffEditErrMsg'] ??
                                        '');
                              }
                            } else {
                              _onShowSnack(
                                  Colors.red,
                                  translations[selectedLanguage]
                                          ?['InvalidCurrPwd'] ??
                                      '');
                            }
                          } catch (e) {
                            print(
                                'Something went wrong with updating password: $e');
                          }
                        }
                      },
                      child: Text(
                          translations[selectedLanguage]?['ChangeBtn'] ?? ''),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

onShowProfile(BuildContext context, [void Function()? onUpdatePhoto]) {
  return Card(
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ignore: sized_box_for_whitespace
          Flexible(
            flex: 1,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50.0,
                    backgroundImage:
                        pickedFile != null ? FileImage(pickedFile!) : null,
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: SizedBox(
                      height: 38,
                      width: 38,
                      child: Card(
                        shape: const CircleBorder(),
                        child: Center(
                          child: Tooltip(
                            message: translations[selectedLanguage]
                                    ?['ChangeProfilePhoto'] ??
                                '',
                            child: IconButton(
                              onPressed: onUpdatePhoto,
                              icon: _isLoadingPhoto
                                  ? const SizedBox(
                                      height: 18.0,
                                      width: 18.0,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3.0,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.edit,
                                      size: 14.0,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 15.0,
          ),
          Column(
            children: [
              Text(
                '${StaffInfo.firstName} ${StaffInfo.lastName ?? ""}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.only(
                    top: 3.0, bottom: 3.5, right: 10.0, left: 10.0),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 240, 239, 239),
                  borderRadius: BorderRadius.all(
                    Radius.circular(12.0),
                  ),
                ),
                child: Text(
                  '${StaffInfo.position}',
                  style: const TextStyle(color: Colors.blue, fontSize: 12.0),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 20.0,
          ),
          Flexible(
            flex: 3,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        color: const Color.fromARGB(255, 240, 239, 239),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              translations[selectedLanguage]?['FName'] ?? '',
                              style: const TextStyle(
                                fontSize: 14.0,
                                color: Color.fromARGB(255, 118, 116, 116),
                              ),
                            ),
                            Text('${StaffInfo.firstName}'),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 15.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.195,
                            padding: const EdgeInsets.all(10.0),
                            color: const Color.fromARGB(255, 240, 239, 239),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  translations[selectedLanguage]?['LName'] ??
                                      '',
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    color: Color.fromARGB(255, 118, 116, 116),
                                  ),
                                ),
                                Text(
                                    '${StaffInfo.lastName ?? StaffInfo.lastName}'),
                              ],
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.195,
                            padding: const EdgeInsets.all(10.0),
                            color: const Color.fromARGB(255, 240, 239, 239),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  translations[selectedLanguage]?['Position'] ??
                                      '',
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    color: Color.fromARGB(255, 118, 116, 116),
                                  ),
                                ),
                                Text('${StaffInfo.position}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 15.0,
                      ),
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        color: const Color.fromARGB(255, 240, 239, 239),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              translations[selectedLanguage]?['Tazkira'] ?? '',
                              style: const TextStyle(
                                fontSize: 14.0,
                                color: Color.fromARGB(255, 118, 116, 116),
                              ),
                            ),
                            Text(StaffInfo.tazkira ?? '--'),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 15.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.195,
                            padding: const EdgeInsets.all(10.0),
                            color: const Color.fromARGB(255, 240, 239, 239),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  translations[selectedLanguage]?['Salary'] ??
                                      '',
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    color: Color.fromARGB(255, 118, 116, 116),
                                  ),
                                ),
                                Text('${StaffInfo.salary ?? '0'} افغانی'),
                              ],
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.195,
                            padding: const EdgeInsets.all(10.0),
                            color: const Color.fromARGB(255, 240, 239, 239),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  translations[selectedLanguage]?['Phone'] ??
                                      '',
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    color: Color.fromARGB(255, 118, 116, 116),
                                  ),
                                ),
                                Text('${StaffInfo.phone}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15.0),
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        color: const Color.fromARGB(255, 240, 239, 239),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              translations[selectedLanguage]?['Address'] ?? '',
                              style: const TextStyle(
                                fontSize: 14.0,
                                color: Color.fromARGB(255, 118, 116, 116),
                              ),
                            ),
                            Text(StaffInfo.address ?? '--'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  isEnglish
                      ? Positioned(
                          top: 0,
                          right: 0,
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Card(
                              shape: const CircleBorder(),
                              child: Tooltip(
                                message: translations[selectedLanguage]
                                        ?['ChgMyPInfo'] ??
                                    '',
                                child: Builder(builder: (BuildContext context) {
                                  return IconButton(
                                    onPressed: () {
                                      onEditProfileInfo(context);
                                    },
                                    icon: const Icon(Icons.edit, size: 16.0),
                                  );
                                }),
                              ),
                            ),
                          ),
                        )
                      : Positioned(
                          top: 0,
                          left: 0,
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Card(
                              shape: const CircleBorder(),
                              child: Tooltip(
                                message: translations[selectedLanguage]
                                        ?['ChgMyPInfo'] ??
                                    '',
                                child: Builder(builder: (BuildContext context) {
                                  return IconButton(
                                    onPressed: () {
                                      onEditProfileInfo(context);
                                    },
                                    icon: const Icon(Icons.edit, size: 16.0),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// This function is to create a backup of the system
onBackUpData() {
  bool isWholeBackupInProg = false;
  bool isXrayBackupInProg = false;
  return StatefulBuilder(
    builder: (context, setState) {
      return Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ListTile(
              title: Card(
                color: const Color.fromARGB(255, 240, 239, 239),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    translations[selectedLanguage]?['BackupCautMsg'] ?? '',
                    style: const TextStyle(fontSize: 14.0, color: Colors.red),
                  ),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 270.0),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1 - ${translations[selectedLanguage]?['Storage1'] ?? ''}',
                    style: const TextStyle(fontSize: 12.0)),
                const SizedBox(height: 5.0),
                Text('2 - ${translations[selectedLanguage]?['Storage2'] ?? ''}',
                    style: const TextStyle(fontSize: 12.0)),
              ],
            ),
            const SizedBox(
              height: 20.0,
            ),
            SizedBox(
              height: 35.0,
              width: MediaQuery.of(context).size.height * 0.6,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40.0),
                  ),
                  side: const BorderSide(color: Colors.blue),
                ),
                onPressed: () async {
                  try {
                    setState(() {
                      isWholeBackupInProg = true;
                    });

                    // There directory where backup file created.
                    String? outputDirectory =
                        await FilePicker.platform.getDirectoryPath();
                    if (outputDirectory == null) {
                      print(
                          'No output directory selected for database backup.');
                      setState(() {
                        isWholeBackupInProg = false;
                      });
                      return;
                    }

                    // Database required variable
                    const String dbName = 'dentistry_db.db';

                    // SQLite database path
                    String dbPath =
                        p.join(Platform.environment['LOCALAPPDATA']!, 'crown');
                    String path = p.join(dbPath, dbName);
                    print('Backup FROM: $path');

                    // User date & time for naming backup file
                    var now = DateTime.now();
                    var formatter = INTL.DateFormat('yyyy-MM-dd HH-mm-ss a');
                    var formattedDate = formatter.format(now);
                    String backupPath =
                        '$outputDirectory/backup at $formattedDate.db';

                    // Copy the database file to a new path
                    final File originalFile = File(path);
                    final File backupFile = await originalFile.copy(backupPath);

                    if (await backupFile.exists()) {
                      _onShowSnack(Colors.green,
                          '${translations[selectedLanguage]?['BackupCreatMsg'] ?? ''}$outputDirectory');
                    } else {
                      print('Backup not created');
                    }

                    setState(() {
                      isWholeBackupInProg = false;
                    });
                  } catch (e) {
                    print('Backing up the database failed. $e');
                  }
                },
                icon: isWholeBackupInProg
                    ? const Center(
                        child: SizedBox(
                          height: 18.0,
                          width: 18.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.0,
                          ),
                        ),
                      )
                    : const Icon(Icons.backup_outlined),
                label: isWholeBackupInProg
                    ? Text(translations[selectedLanguage]?['WaitMsg'] ?? '')
                    : Text(
                        translations[selectedLanguage]?['CreateBackup'] ?? ''),
              ),
            ),
            const SizedBox(height: 15.0),
            SizedBox(
              height: 35.0,
              width: MediaQuery.of(context).size.height * 0.6,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40.0),
                  ),
                  side: const BorderSide(color: Colors.brown),
                ),
                onPressed: () async {
                  try {
                    setState(
                      () {
                        isXrayBackupInProg = true;
                      },
                    );

                    // If the directory exists and contains files, continue with the backup
                    String? outputDirectory =
                        await FilePicker.platform.getDirectoryPath();
                    if (outputDirectory == null) {
                      print('No output directory selected for x-ray backup.');
                      setState(
                        () {
                          isXrayBackupInProg = false;
                        },
                      );
                      return;
                    }
                    // Get local storage directory
                    var directory = await getApplicationDocumentsDirectory();
                    var path = directory.path;
                    // Directory to be backed up
                    Directory dir = Directory('$path\\CROWN');
                    // Check if the directory exists
                    if (!dir.existsSync()) {
                      _onShowSnack(
                          Colors.red,
                          translations[selectedLanguage]?['XDirNotFound'] ??
                              '');
                      setState(
                        () {
                          isXrayBackupInProg = false;
                        },
                      );
                      return;
                    }

                    // Check if the directory contains any files
                    List<FileSystemEntity> files =
                        dir.listSync(recursive: true);
                    if (files.isEmpty) {
                      _onShowSnack(Colors.red,
                          translations[selectedLanguage]?['XDirEmpty'] ?? '');
                      setState(
                        () {
                          isXrayBackupInProg = false;
                        },
                      );
                      return;
                    }

                    // Output directory where zip file created.
                    String zipPath = '$outputDirectory\\CROWN.zip';

                    // Create the Archive object
                    Archive archive = Archive();

                    // Add files to the archive
                    for (FileSystemEntity file in files) {
                      if (file is File) {
                        // Read the file
                        List<int> data = await file.readAsBytes();

                        // Add an archive file
                        archive.addFile(ArchiveFile(
                            p.relative(file.path, from: dir.path),
                            data.length,
                            data));
                      }
                    }

                    // Encode the archive as a zip file
                    List<int>? encoded = ZipEncoder().encode(archive);

                    // Write the zip file
                    File(zipPath)
                      ..createSync(recursive: true)
                      ..writeAsBytesSync(encoded!);
                    // Check if the zip file was created
                    if (zipPath.isNotEmpty) {
                      _onShowSnack(Colors.green,
                          '${translations[selectedLanguage]?['XSuccessMsg'] ?? ''}$outputDirectory');
                      setState(
                        () {
                          isXrayBackupInProg = false;
                        },
                      );
                    } else {
                      _onShowSnack(Colors.green,
                          translations[selectedLanguage]?['XFailMsg'] ?? '');
                      setState(
                        () {
                          isXrayBackupInProg = false;
                        },
                      );
                    }
                  } catch (e) {
                    print('X-Ray backup failed: $e');
                  }
                },
                icon: isXrayBackupInProg
                    ? const Center(
                        child: SizedBox(
                          height: 18.0,
                          width: 18.0,
                          child: CircularProgressIndicator(
                            color: Colors.brown,
                            strokeWidth: 3.0,
                          ),
                        ),
                      )
                    : const Icon(Icons.photo_library_outlined,
                        color: Colors.brown),
                label: isXrayBackupInProg
                    ? Text(translations[selectedLanguage]?['WaitMsg'] ?? '',
                        style: const TextStyle(color: Colors.brown))
                    : Text(translations[selectedLanguage]?['CreateXBtn'] ?? '',
                        style: const TextStyle(color: Colors.brown)),
              ),
            ),
          ],
        ),
      );
    },
  );
}

// Fetch the selected language from shared preference.
Future<String> getSelectedLanguage() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('selectedLanguage') ?? 'دری';
}

// Fetch the selected date type from shared preference.
Future<String> getSelectedDateType() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('selectedDateType') ?? 'میلادی';
}

// Fetch the selected crown version from shared preference.
Future<bool> getSelectedCrownVersion() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('selectedCrownVersion') ?? false;
}

Future<void> _saveCrownType(String value) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('crownType', value);
}

// This function is to change system languages
Widget onChangeLang() {
  // Set the language into a
  // String? selectedLanguage = await getSelectedLanguage();

  return FutureBuilder(
    future: getSelectedLanguage(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator();
      } else {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          String? selectedLanguage = snapshot.data;
          return StatefulBuilder(
            builder: (context, setState) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return Card(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            translations[selectedLanguage]?['chooseLanguage'] ??
                                'Choose Language',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(
                            height: 50.0,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              InkWell(
                                onTap: () {
                                  Provider.of<LanguageProvider>(context,
                                          listen: false)
                                      .selectedLanguage = 'English';
                                  setState(() {
                                    selectedLanguage = 'English';
                                  });
                                },
                                child: Card(
                                  elevation: 1.0,
                                  color: selectedLanguage == 'English'
                                      ? Colors.grey[300]
                                      : Colors
                                          .white, // change color when selected
                                  child: SizedBox(
                                    height: 60.0, // adjust as needed
                                    width: 120.0, // adjust as needed
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        SizedBox(
                                          width: 80.0, // adjust as needed
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: <Widget>[
                                              Image.asset(
                                                'assets/flags/English.png',
                                                width: 30.0,
                                                height: 30.0,
                                              ),
                                              const Text('Enlish'),
                                            ],
                                          ),
                                        ),
                                        if (selectedLanguage == 'English')
                                          const Icon(Icons.check_circle,
                                              color: Colors.blue),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              InkWell(
                                onTap: () {
                                  Provider.of<LanguageProvider>(context,
                                          listen: false)
                                      .selectedLanguage = 'دری';
                                  setState(() {
                                    selectedLanguage = 'دری';
                                  });
                                },
                                child: Card(
                                  elevation: 1.0,
                                  color: selectedLanguage == 'دری'
                                      ? Colors.grey[300]
                                      : Colors
                                          .white, // change color when selected
                                  child: SizedBox(
                                    height: 60.0, // adjust as needed
                                    width: 120.0, // adjust as needed
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        SizedBox(
                                          width: 80.0, // adjust as needed
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: <Widget>[
                                              Image.asset(
                                                'assets/flags/Dari.png',
                                                width: 30.0,
                                                height: 30.0,
                                              ),
                                              const Text('دری'),
                                            ],
                                          ),
                                        ),
                                        if (selectedLanguage == 'دری')
                                          const Icon(Icons.check_circle,
                                              color: Colors.blue),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              InkWell(
                                onTap: () {
                                  Provider.of<LanguageProvider>(context,
                                          listen: false)
                                      .selectedLanguage = 'پښتو';
                                  setState(() {
                                    selectedLanguage = 'پښتو';
                                  });
                                },
                                child: Card(
                                  elevation: 1.0,
                                  color: selectedLanguage == 'پښتو'
                                      ? Colors.grey[300]
                                      : Colors
                                          .white, // change color when selected
                                  child: SizedBox(
                                    height: 60.0, // adjust as needed
                                    width: 120.0, // adjust as needed
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        SizedBox(
                                          width: 80.0, // adjust as needed
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: <Widget>[
                                              Image.asset(
                                                'assets/flags/Pashto.png',
                                                width: 30.0,
                                                height: 30.0,
                                              ),
                                              const Text('پښتو'),
                                            ],
                                          ),
                                        ),
                                        if (selectedLanguage == 'پښتو')
                                          const Icon(Icons.check_circle,
                                              color: Colors.blue),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Add more languages here
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        }
      }
    },
  );
}

// This function is to switch between Hijri and Gregorian Date
Widget _onChangeDateType() {
  return FutureBuilder(
    future: getSelectedDateType(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator();
      } else {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          String? selectedDateType = snapshot.data;
          return StatefulBuilder(
            builder: (context, setState) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return Card(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            translations[selectedLanguage]?['ChangeCalendar'] ??
                                '',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(
                            height: 50.0,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              InkWell(
                                onTap: () {
                                  Provider.of<SettingsProvider>(context,
                                          listen: false)
                                      .selectedDateType = 'هجری شمسی';
                                  setState(() {
                                    selectedDateType = 'هجری شمسی';
                                  });
                                },
                                child: Card(
                                  elevation: 1.0,
                                  color: selectedDateType == 'هجری شمسی'
                                      ? Colors.grey[300]
                                      : Colors
                                          .white, // change color when selected
                                  child: SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.08, // adjust as needed
                                    width: MediaQuery.of(context).size.width *
                                        0.11, // adjust as needed
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.08, // adjust as needed
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: <Widget>[
                                              const Icon(
                                                Icons.calendar_month_outlined,
                                                color: Colors.blue,
                                              ),
                                              Text(
                                                  translations[selectedLanguage]
                                                          ?['Hijri'] ??
                                                      ''),
                                            ],
                                          ),
                                        ),
                                        if (selectedDateType == 'هجری شمسی')
                                          Icon(Icons.check_circle,
                                              color: Colors.green,
                                              size: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.015),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              InkWell(
                                onTap: () {
                                  Provider.of<SettingsProvider>(context,
                                          listen: false)
                                      .selectedDateType = 'میلادی';
                                  setState(() {
                                    selectedDateType = 'میلادی';
                                  });
                                },
                                child: Card(
                                  elevation: 1.0,
                                  color: selectedDateType == 'میلادی'
                                      ? Colors.grey[300]
                                      : Colors
                                          .white, // change color when selected
                                  child: SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.08, // adjust as needed
                                    width: MediaQuery.of(context).size.width *
                                        0.11,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.07, // adjust as needed
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: <Widget>[
                                              const Icon(
                                                Icons.calendar_month_outlined,
                                                color: Colors.blue,
                                              ),
                                              Text(
                                                  translations[selectedLanguage]
                                                          ?['Gregorian'] ??
                                                      ''),
                                            ],
                                          ),
                                        ),
                                        if (selectedDateType == 'میلادی')
                                          Icon(Icons.check_circle,
                                              color: Colors.green,
                                              size: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.015),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Add more languages here
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        }
      }
    },
  );
}

String? xrayFilePath;
Future<void> _fetchPath() async {
  Directory? userDir = await getApplicationDocumentsDirectory();
  var path = '${userDir.path}\\CROWN';
  xrayFilePath = path;
}

// This function is to restore the backedup file
onRestoreData() {
  bool isRestoreInProg = false;
  return StatefulBuilder(
    builder: (context, setState) {
      return Card(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                translations[selectedLanguage]?['RestoreMsg'] ?? '',
                style: const TextStyle(fontSize: 12.0),
              ),
              const SizedBox(
                height: 20.0,
              ),
              SizedBox(
                height: 35.0,
                width: 400.0,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40.0),
                    ),
                    side: const BorderSide(color: Colors.blue),
                  ),
                  onPressed: () async {
                    try {
                      setState(() {
                        isRestoreInProg = true;
                      });

                      // Database required variable
                      const String dbName =
                          'dentistry_db.db'; // Include the '.db' extension

                      // SQLite database path
                      String dbPath = p.join(
                          Platform.environment['LOCALAPPDATA']!, 'crown');
                      String path = p.join(dbPath, dbName);

                      // Show file picker
                      filePickerResult = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['db'],
                      );

                      if (filePickerResult != null) {
                        String backupPath =
                            filePickerResult!.files.single.path!;

                        // Close the current database
                        var database = await openDatabase(path);
                        await database.close();

                        // Overwrite the current database with the backup file
                        final File originalDbFile = File(path);
                        final File backupFile = File(backupPath);
                        await originalDbFile
                            .writeAsBytes(await backupFile.readAsBytes());

                        // Reopen the database
                        database = await openDatabase(path);

                        _onShowSnack(
                            Colors.green,
                            translations[selectedLanguage]
                                    ?['RestoreSuccessMsg'] ??
                                '');
                      }

                      setState(() {
                        isRestoreInProg = false;
                      });
                    } catch (e) {
                      print('Restoration failed: $e');
                      _onShowSnack(
                        Colors.red,
                        'Restoration failed: $e',
                      );
                    }
                  },
                  icon: isRestoreInProg
                      ? const Center(
                          child: SizedBox(
                            height: 18.0,
                            width: 18.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.0,
                            ),
                          ),
                        )
                      : const Icon(Icons.restore_outlined),
                  label: isRestoreInProg
                      ? Text(translations[selectedLanguage]?['WaitMsg'] ?? '')
                      : Text(translations[selectedLanguage]?['RestoreBackup'] ??
                          ''),
                ),
              ),
              const SizedBox(
                height: 50.0,
              ),
              Text(
                '${translations[selectedLanguage]?['XrayExtMsg'] ?? ''}$xrayFilePath',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    },
  );
}

// This dialog edits a staff
onEditProfileInfo(BuildContext context) {
  // position types dropdown variables
  String positionDropDown = 'داکتر دندان';
  var positionItems = [
    'داکتر دندان',
    'نرس',
    'مدیر سیستم',
  ];
// The global for the form
  final formKeyEditStaff = GlobalKey<FormState>();
// The text editing controllers for the TextFormFields
  final nameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final salaryController = TextEditingController();
  final tazkiraController = TextEditingController();
  final addressController = TextEditingController();

  const regExOnlyAbc = "[a-zA-Z,، \u0600-\u06FFF]";
  const regExOnlydigits = "[0-9+]";
  final tazkiraPattern = RegExp(r'^\d{4}-\d{4}-\d{5}$');

  // Assign values from static class members
  nameController.text = StaffInfo.firstName ?? '';
  lastNameController.text = StaffInfo.lastName ?? '';
  phoneController.text = StaffInfo.phone ?? '';
  salaryController.text =
      StaffInfo.salary == null ? '0' : StaffInfo.salary.toString();
  tazkiraController.text = StaffInfo.tazkira ?? '';
  addressController.text = StaffInfo.address ?? '';

  return showDialog(
    context: context,
    builder: ((context) {
      return StatefulBuilder(
        builder: ((context, setState) {
          return AlertDialog(
            title: Directionality(
              textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
              child: Text(
                translations[selectedLanguage]?['MyProfileHeading'] ?? '',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
            content: Directionality(
              textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
              child: Form(
                key: formKeyEditStaff,
                child: SizedBox(
                  width: 500.0,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(
                              left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
                          child: TextFormField(
                            controller: nameController,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return translations[selectedLanguage]
                                        ?['FNRequired'] ??
                                    '';
                              }
                            },
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: translations[selectedLanguage]
                                      ?['FName'] ??
                                  '',
                              suffixIcon: const Icon(Icons.person),
                              enabledBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(color: Colors.grey)),
                              focusedBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(color: Colors.blue)),
                              errorBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(color: Colors.red)),
                              focusedErrorBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(
                                      color: Colors.red, width: 1.5)),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                              left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
                          child: TextFormField(
                            controller: lastNameController,
                            validator: (value) {
                              if (value!.isNotEmpty) {
                                if (value.length < 3 || value.length > 10) {
                                  return translations[selectedLanguage]
                                          ?['FNLength'] ??
                                      '';
                                }
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: translations[selectedLanguage]
                                      ?['LName'] ??
                                  '',
                              suffixIcon: const Icon(Icons.person),
                              enabledBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(color: Colors.grey)),
                              focusedBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(color: Colors.blue)),
                              errorBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(color: Colors.red)),
                              focusedErrorBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(
                                      color: Colors.red, width: 1.5)),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                              left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
                          child: TextFormField(
                            controller: phoneController,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(regExOnlydigits),
                              ),
                            ],
                            validator: (value) {
                              if (value!.isEmpty) {
                                return translations[selectedLanguage]
                                        ?['PhoneRequired'] ??
                                    '';
                              } else if (value.startsWith('07')) {
                                if (value.length < 10 || value.length > 10) {
                                  return translations[selectedLanguage]
                                          ?['Phone10'] ??
                                      '';
                                }
                              } else if (value.startsWith('+93')) {
                                if (value.length < 12 || value.length > 12) {
                                  return translations[selectedLanguage]
                                          ?['Phone12'] ??
                                      '';
                                }
                              } else {
                                return translations[selectedLanguage]
                                        ?['ValidPhone'] ??
                                    '';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: translations[selectedLanguage]
                                      ?['Phone'] ??
                                  '',
                              suffixIcon: const Icon(Icons.phone),
                              enabledBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(color: Colors.grey)),
                              focusedBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(color: Colors.blue)),
                              errorBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(color: Colors.red)),
                              focusedErrorBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(
                                      color: Colors.red, width: 1.5)),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                              left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
                          child: TextFormField(
                            controller: salaryController,
                            validator: (value) {
                              if (value!.isNotEmpty) {
                                final salary = double.tryParse(value);
                                if (salary! < 1000 || salary > 100000) {
                                  return translations[selectedLanguage]
                                          ?['ValidSalary'] ??
                                      '';
                                }
                              }
                              return null;
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'))
                            ],
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText:
                                  '${translations[selectedLanguage]?['Salary'] ?? ''} (${translations[selectedLanguage]?['Afn'] ?? ''})',
                              suffixIcon: const Icon(Icons.money),
                              enabledBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(color: Colors.grey)),
                              focusedBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(color: Colors.blue)),
                              errorBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(color: Colors.red)),
                              focusedErrorBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(
                                      color: Colors.red, width: 1.5)),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                              left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
                          child: TextFormField(
                            controller: tazkiraController,
                            validator: (value) {
                              if (value!.isNotEmpty) {
                                if (!tazkiraPattern.hasMatch(value)) {
                                  return translations[selectedLanguage]
                                          ?['ValidTazkira'] ??
                                      '';
                                }
                              }
                              return null;
                            },
                            // keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9-]'),
                              ),
                            ],
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: translations[selectedLanguage]
                                      ?['Tazkira'] ??
                                  '',
                              suffixIcon: const Icon(Icons.perm_identity),
                              enabledBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(color: Colors.grey)),
                              focusedBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(color: Colors.blue)),
                              errorBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(color: Colors.red)),
                              focusedErrorBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(
                                      color: Colors.red, width: 1.5)),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                              left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
                          child: TextFormField(
                            controller: addressController,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(regExOnlyAbc),
                              ),
                            ],
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: translations[selectedLanguage]
                                      ?['Address'] ??
                                  '',
                              suffixIcon:
                                  const Icon(Icons.location_on_outlined),
                              enabledBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(color: Colors.grey)),
                              focusedBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(color: Colors.blue)),
                              errorBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
                                  borderSide: BorderSide(color: Colors.red)),
                              focusedErrorBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50.0)),
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
            actions: [
              Directionality(
                  textDirection:
                      isEnglish ? TextDirection.ltr : TextDirection.rtl,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(translations[selectedLanguage]
                                  ?['CancelBtn'] ??
                              '')),
                      ElevatedButton(
                        onPressed: () async {
                          if (formKeyEditStaff.currentState!.validate()) {
                            // Fetch staff info from forms and assign them into variables.
                            String firstName = nameController.text;
                            String lastName = lastNameController.text.isEmpty
                                ? ''
                                : lastNameController.text;
                            String phone = phoneController.text;
                            double salary = salaryController.text.isEmpty
                                ? 0
                                : double.parse(salaryController.text);
                            String tazkiraID = tazkiraController.text.isEmpty
                                ? ''
                                : tazkiraController.text;
                            String address = addressController.text.isEmpty
                                ? ''
                                : addressController.text;

                            final conn = await onConnToSqliteDb();
                            var updateResult = await conn.rawUpdate(
                                'UPDATE staff SET firstname = ?, lastname = ?, salary = ?, phone = ?, tazkira_ID = ?, address = ? WHERE staff_ID = ?',
                                [
                                  firstName,
                                  lastName,
                                  salary,
                                  phone,
                                  tazkiraID,
                                  address,
                                  StaffInfo.staffID
                                ]);
                            if (updateResult > 0) {
                              _onShowSnack(
                                  Colors.green,
                                  translations[selectedLanguage]
                                          ?['StaffEditMsg'] ??
                                      '');
                              setState(() {
                                StaffInfo.firstName = firstName;
                                StaffInfo.lastName = lastName;
                                StaffInfo.phone = phone;
                                StaffInfo.salary = salary;
                                StaffInfo.tazkira = tazkiraID;
                                StaffInfo.address = address;

                                // Call this function to refresh staff info UI
                                StaffInfo.onUpdateProfile!();
                              });
                            }
                            Navigator.pop(context);
                          }
                        },
                        child:
                            Text(translations[selectedLanguage]?['Edit'] ?? ''),
                      ),
                    ],
                  ))
            ],
          );
        }),
      );
    }),
  );
}
