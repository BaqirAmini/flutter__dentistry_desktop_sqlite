import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dentistry/config/global_usage.dart';
import 'package:flutter_dentistry/config/private/private.dart';
import 'package:flutter_dentistry/views/main/login.dart';
import 'package:flutter_dentistry/views/settings/contact_us.dart';

void main() => runApp(const LicenseVerification());

// Create the global key at the top level of your Dart file
final GlobalKey<ScaffoldMessengerState> _globalKeyLiscenseVerify =
    GlobalKey<ScaffoldMessengerState>();
// This is shows snackbar when called
void _onShowSnack(Color backColor, String msg) {
  _globalKeyLiscenseVerify.currentState?.showSnackBar(
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

class LicenseVerification extends StatefulWidget {
  const LicenseVerification({Key? key}) : super(key: key);

  @override
  State<LicenseVerification> createState() => _LiscenseVerificationState();
}

class _LiscenseVerificationState extends State<LicenseVerification> {
  // form controllers
  final TextEditingController _machineCodeController = TextEditingController();
  final TextEditingController _liscenseController = TextEditingController();
  final _liscenseVerifyFK = GlobalKey<FormState>();
  bool _isCoppied = false;

  // Create an instance of this class
  final GlobalUsage _globalUsage = GlobalUsage();

  @override
  void initState() {
    super.initState();
    _machineCodeController.text = _globalUsage.getMachineGuid();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _globalKeyLiscenseVerify,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          body: Center(
            child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  shape: BoxShape.rectangle,
                  border: Border.all(color: Colors.grey, width: 1.5),
                ),
                width: MediaQuery.of(context).size.width * 0.7,
                child: SingleChildScrollView(
                  child: Form(
                    key: _liscenseVerifyFK,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.vpn_key_outlined,
                              size: MediaQuery.of(context).size.width * 0.05,
                              color: Colors.blue),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.01),
                          Text(
                            'License Key Verification',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge!
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
                            width: MediaQuery.of(context).size.width * 0.43,
                            child: Builder(builder: (context) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Machine Code',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.35,
                                    child: TextFormField(
                                      readOnly: true,
                                      textDirection: TextDirection.ltr,
                                      controller: _machineCodeController,
                                      decoration: InputDecoration(
                                        suffixIcon: !_isCoppied
                                            ? IconButton(
                                                tooltip: 'Copy',
                                                splashRadius: 18.0,
                                                onPressed:
                                                    _machineCodeController
                                                            .text.isEmpty
                                                        ? null
                                                        : () async {
                                                            Clipboard.setData(
                                                              ClipboardData(
                                                                  text:
                                                                      _machineCodeController
                                                                          .text),
                                                            );
                                                            _onShowSnack(
                                                                Colors.green,
                                                                'Machine code copied.');
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
                                              )
                                            : const Icon(Icons.done_rounded),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Product Key',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.35,
                                      child: TextFormField(
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
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.43,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Builder(
                                  builder: (context) {
                                    return ElevatedButton.icon(
                                        onPressed: () async {
                                          if (_liscenseVerifyFK.currentState!
                                              .validate()) {
                                            try {
                                              // Decrypt the liscense key
                                              String decryptedValue =
                                                  _globalUsage
                                                      .decryptProductKey(
                                                          _liscenseController
                                                              .text,
                                                          secretKey);

                                              // Expiry date is string
                                              String expiryDateString =
                                                  decryptedValue.substring(
                                                      _machineCodeController
                                                          .text.length);
                                              // Convert this string to datetime
                                              DateTime expiryDate =
                                                  DateTime.parse(
                                                      expiryDateString);

                                              // Now re-encrypt the machine code with the fetched datetime (expiry datetime) to use for verification in below.
                                              String reEncryptedValue =
                                                  _globalUsage
                                                      .generateProductKey(
                                                          expiryDate,
                                                          _machineCodeController
                                                              .text);
                                              await _globalUsage
                                                  .storeExpiryDate(expiryDate);

                                              print(
                                                  'Expiry Date: ${await _globalUsage.getExpiryDate()}');

                                              if (reEncryptedValue ==
                                                  _liscenseController.text) {
                                                if (await _globalUsage
                                                    .hasLicenseKeyExpired()) {
                                                  _onShowSnack(Colors.red,
                                                      'Sorry, this product key has expired. Please purchase the new one.');
                                                  await _globalUsage
                                                      .deleteValue4User(
                                                          'UserlicenseKey');
                                                } else {
                                                  await _globalUsage
                                                      .storeExpiryDate(
                                                          expiryDate);
                                                  await _globalUsage
                                                      .storeLicenseKey4User(
                                                          _liscenseController
                                                              .text);
                                                  // ignore: use_build_context_synchronously
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              const Login()));
                                                }
                                              } else {
                                                _onShowSnack(Colors.red,
                                                    'Sorry, this product key is not valid!');
                                                await _globalUsage
                                                    .deleteValue4User(
                                                        'UserlicenseKey');
                                              }
                                            } catch (e) {
                                              _onShowSnack(Colors.red,
                                                  'Sorry, this product key is not valid!');
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
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Exit the System',
                                                style: TextStyle(
                                                    color: Colors.blue)),
                                            content: const Text(
                                                'Are you sure you want to exit the system?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => exit(0),
                                                child: const Text('Exit'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: const Text('Cancel'),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.13),
                          const ContactUs()
                        ],
                      ),
                    ),
                  ),
                )),
          ),
        ),
      ),
    );
  }
}
