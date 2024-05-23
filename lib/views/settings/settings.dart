import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dentistry/config/global_usage.dart';
import 'package:flutter_dentistry/config/language_provider.dart';
import 'package:flutter_dentistry/config/liscense_verification.dart';
import 'package:flutter_dentistry/config/private/private.dart';
import 'package:flutter_dentistry/config/translations.dart';
import 'package:flutter_dentistry/views/main/login.dart';
import 'package:provider/provider.dart';
import '/views/settings/settings_menu.dart';

void main() => runApp(const Settings());
// Create the global key at the top level of your Dart file
final GlobalKey<ScaffoldMessengerState> _globalKeyRenewLicense =
    GlobalKey<ScaffoldMessengerState>();
// This is shows snackbar when called
void _onShowSnack(Color backColor, String msg) {
  _globalKeyRenewLicense.currentState?.showSnackBar(
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

// ignore: prefer_typing_uninitialized_variables
var selectedLanguage;
// ignore: prefer_typing_uninitialized_variables
var isEnglish;

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  // form controllers
  final TextEditingController _machineCodeController = TextEditingController();
  final TextEditingController _liscenseController = TextEditingController();
  final _licenseRenewFK = GlobalKey<FormState>();
  bool _isCoppied = false;
  bool _notVerified = false;
  String _verifyMsg = '';

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

// This dialog is to renew the license key (product key) of Crown
  _renewLicenseKey(BuildContext context) {
    _isCoppied = false;
    _notVerified = false;
    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Renew Your License Key',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium!
                  .copyWith(color: Colors.blue)),
          content: SingleChildScrollView(
            child: Form(
              key: _licenseRenewFK,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
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
                        width: MediaQuery.of(context).size.width * 0.45,
                        child: Text(_globalUsage.productKeyRelatedMsg,
                            style: Theme.of(context).textTheme.labelLarge),
                      ),
                      const SizedBox(height: 50.0),
                      Container(
                        margin: const EdgeInsets.all(10.0),
                        width: MediaQuery.of(context).size.width * 0.43,
                        child: Builder(builder: (context) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Machine Code',
                                  style:
                                      Theme.of(context).textTheme.labelLarge),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.35,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      readOnly: true,
                                      textDirection: TextDirection.ltr,
                                      controller: _machineCodeController,
                                      decoration: InputDecoration(
                                        suffixIcon: IconButton(
                                          tooltip: 'Copy',
                                          splashRadius: 18.0,
                                          onPressed: _machineCodeController
                                                  .text.isEmpty
                                              ? null
                                              : () async {
                                                  await Clipboard.setData(
                                                    ClipboardData(
                                                        text:
                                                            _machineCodeController
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
                        width: MediaQuery.of(context).size.width * 0.43,
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
                                      MediaQuery.of(context).size.width * 0.35,
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
                                    if (_licenseRenewFK.currentState!
                                        .validate()) {
                                      try {
                                        // Decrypt the liscense key
                                        String decryptedValue =
                                            _globalUsage.decryptProductKey(
                                                _liscenseController.text,
                                                secretKey);

                                        // Expiry date is string
                                        String expiryDateString = decryptedValue
                                            .substring(_machineCodeController
                                                .text.length);
                                        // Convert this string to datetime
                                        DateTime expiryDate =
                                            DateTime.parse(expiryDateString);

                                        // Now re-encrypt the machine code with the fetched datetime (expiry datetime) to use for verification in below.
                                        String reEncryptedValue =
                                            _globalUsage.generateProductKey(
                                                expiryDate,
                                                _machineCodeController.text);
                                        await _globalUsage
                                            .storeExpiryDate(expiryDate);

                                        print(
                                            'Expiry Date: ${await _globalUsage.getExpiryDate()}');

                                        if (reEncryptedValue ==
                                            _liscenseController.text) {
                                          if (await _globalUsage
                                              .hasLicenseKeyExpired()) {
                                            setState(() {
                                              _notVerified = true;
                                              _verifyMsg =
                                                  'Sorry, this product key has expired. Please purchase the new one.';
                                            });
                                          } else {
                                            await _globalUsage
                                                .storeExpiryDate(expiryDate);
                                            await _globalUsage
                                                .storeLicenseKey4User(
                                                    _liscenseController.text);
                                            // ignore: use_build_context_synchronously
                                            Navigator.of(context,
                                                    rootNavigator: true)
                                                .pop();
                                            _onShowSnack(Colors.green,
                                                'Congratulations, your product key updated!');
                                          }
                                        } else {
                                          setState(() {
                                            _notVerified = true;
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

  @override
  void initState() {
    super.initState();
    _getRemainValidDays().then((_) {
      setState(() {});
    });
    _machineCodeController.text = _globalUsage.getMachineGuid();
  }

  @override
  Widget build(BuildContext context) {
    // Fetch translations keys based on the selected language.
    var languageProvider = Provider.of<LanguageProvider>(context);
    selectedLanguage = languageProvider.selectedLanguage;
    isEnglish = selectedLanguage == 'English';
    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: FutureBuilder(
        future: _getRemainValidDays(),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          } else {
            return Scaffold(
              appBar: AppBar(
                title: Text(translations[selectedLanguage]?['Settings'] ?? ''),
                actions: [
                  if (_validDays <= 365 && _validDays > 0)
                    Center(
                      child: Text(
                        '${translations[selectedLanguage]?['ValidDuration'] ?? ''} $_validDays ${translations[selectedLanguage]?['Days'] ?? ''}',
                        style: Theme.of(context)
                            .primaryTextTheme
                            .labelLarge!
                            .copyWith(
                                color:
                                    const Color.fromARGB(255, 223, 230, 135)),
                      ),
                    ),
                  Visibility(
                    visible: (_validDays <= 5) ? true : false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: IconButton(
                        splashRadius: 25.0,
                        tooltip: 'Renew Product Key',
                        onPressed: () => _renewLicenseKey(context),
                        icon: const Icon(Icons.key),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15.0)
                ],
              ),
              body: const SettingsMenu(),
            );
          }
        },
      ),
    );
  }
}
