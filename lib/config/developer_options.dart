import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dentistry/config/global_usage.dart';
import 'package:flutter_dentistry/models/db_conn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:win32/win32.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() => runApp(const DeveloperOptions());

// Create instance of Flutter Secure Store
const storage = FlutterSecureStorage();

class DeveloperOptions extends StatefulWidget {
  const DeveloperOptions({Key? key}) : super(key: key);

  @override
  State<DeveloperOptions> createState() => _DeveloperOptionsState();
}

class _DeveloperOptionsState extends State<DeveloperOptions> {
  String _liscenseKey = '';

  // Instantiate 'Features' class
  Features features = Features();

  // form controllers
  final TextEditingController _machineCodeController = TextEditingController();
  final TextEditingController _liscenseController = TextEditingController();
  final _liscenseFormKey = GlobalKey<FormState>();
  int _validDurationGroupValue = 7;
  bool _isLiscenseCopied = false;
  final _customDurationController = TextEditingController();
  // Set a dropdown for durations
  String _selectedDurationFreq = 'Days';
  final _durationFreqItems = ['Days', 'Months', 'Years'];
  bool _customDurationSet = false;

  // Create instance to access its methods
  final GlobalUsage _globalUsage = GlobalUsage();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Key Management'),
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Form(
                key: _liscenseFormKey,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Generate Product Key',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall!
                            .copyWith(fontSize: 20),
                      ),
                      Container(
                        margin: const EdgeInsets.all(10.0),
                        width: MediaQuery.of(context).size.width * 0.6,
                        child: Builder(builder: (context) {
                          return TextFormField(
                            textDirection: TextDirection.ltr,
                            controller: _machineCodeController,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Machine code required';
                              }
                              return null;
                            },
                            /*  inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(_regExUName),
                              ),
                            ], */
                            onChanged: (value) {
                              setState(() {
                                _isLiscenseCopied = false;
                              });
                            },
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.all(23.0),
                              border: OutlineInputBorder(),
                              labelText: 'Machine GUID',
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey)),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue)),
                              errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.red)),
                              focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.red, width: 1.5)),
                            ),
                          );
                        }),
                      ),
                      Column(
                        children: [
                          if (!_customDurationSet)
                            Container(
                              width: MediaQuery.of(context).size.width * 0.6,
                              margin: const EdgeInsets.all(10.0),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 15.0),
                                  border: OutlineInputBorder(),
                                  labelText: 'License Key Duration',
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.blue),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          listTileTheme:
                                              const ListTileThemeData(
                                                  horizontalTitleGap: 1.0),
                                        ),
                                        child: RadioListTile<int>(
                                            title: const Text(
                                              '7 Days',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            value: 7,
                                            groupValue:
                                                _validDurationGroupValue,
                                            onChanged: (int? value) {
                                              setState(() {
                                                _validDurationGroupValue =
                                                    value!;
                                              });
                                            }),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          listTileTheme:
                                              const ListTileThemeData(
                                                  horizontalTitleGap: 1.0),
                                        ),
                                        child: RadioListTile<int>(
                                            title: const Text(
                                              '14 Days',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            value: 14,
                                            groupValue:
                                                _validDurationGroupValue,
                                            onChanged: (int? value) {
                                              setState(() {
                                                _validDurationGroupValue =
                                                    value!;
                                              });
                                            }),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          listTileTheme:
                                              const ListTileThemeData(
                                                  horizontalTitleGap: 1.0),
                                        ),
                                        child: RadioListTile<int>(
                                            title: const Text(
                                              '1 Month',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            value: 30,
                                            groupValue:
                                                _validDurationGroupValue,
                                            onChanged: (int? value) {
                                              setState(() {
                                                _validDurationGroupValue =
                                                    value!;
                                              });
                                            }),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          listTileTheme:
                                              const ListTileThemeData(
                                                  horizontalTitleGap: 1.0),
                                        ),
                                        child: RadioListTile<int>(
                                            title: const Text(
                                              '6 Month',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            value: 180,
                                            groupValue:
                                                _validDurationGroupValue,
                                            onChanged: (int? value) {
                                              setState(() {
                                                _validDurationGroupValue =
                                                    value!;
                                              });
                                            }),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          listTileTheme:
                                              const ListTileThemeData(
                                                  horizontalTitleGap: 1.0),
                                        ),
                                        child: RadioListTile<int>(
                                            title: const Text(
                                              '1 Year',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            value: 365,
                                            groupValue:
                                                _validDurationGroupValue,
                                            onChanged: (int? value) {
                                              setState(() {
                                                _validDurationGroupValue =
                                                    value!;
                                              });
                                            }),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          listTileTheme:
                                              const ListTileThemeData(
                                                  horizontalTitleGap: 1.0),
                                        ),
                                        child: RadioListTile<int>(
                                            title: const Text(
                                              'Forever',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            value: -1,
                                            groupValue:
                                                _validDurationGroupValue,
                                            onChanged: (int? value) {
                                              setState(() {
                                                _validDurationGroupValue =
                                                    value!;
                                              });
                                            }),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Checkbox(
                                    value: _customDurationSet,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _customDurationSet = value!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const Text('Custom'),
                            ],
                          ),
                          if (_customDurationSet)
                            Column(
                              children: [
                                const SizedBox(height: 5.0),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        margin: const EdgeInsets.all(10),
                                        child: TextFormField(
                                          controller: _customDurationController,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                                RegExp(r'[0-9]'))
                                          ],
                                          validator: (value) {
                                            if (value!.isEmpty) {
                                              return 'Number of $_selectedDurationFreq Required.';
                                            } else {
                                              if (_selectedDurationFreq ==
                                                  'Days') {
                                                if (int.parse(
                                                            _customDurationController
                                                                .text) <=
                                                        1 ||
                                                    int.parse(
                                                            _customDurationController
                                                                .text) >=
                                                        30) {
                                                  return 'Days must be between 1 and 30 days or select Months.';
                                                }
                                              } else if (_selectedDurationFreq ==
                                                  'Months') {
                                                if (int.parse(
                                                            _customDurationController
                                                                .text) <
                                                        1 ||
                                                    int.parse(
                                                            _customDurationController
                                                                .text) ==
                                                        12) {
                                                  return 'Months cannot be lower 1. Select Years instead of 12 months.';
                                                }
                                              } else {
                                                if (int.parse(
                                                        _customDurationController
                                                            .text) <
                                                    1) {
                                                  return 'Years cannot be lower than 1 or select Months.';
                                                }
                                              }
                                              return null;
                                            }
                                          },
                                          decoration: InputDecoration(
                                            border: const OutlineInputBorder(),
                                            labelText:
                                                'Number of $_selectedDurationFreq',
                                            suffixIcon: const Icon(
                                                Icons.access_time_rounded),
                                            enabledBorder:
                                                const OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Colors.grey)),
                                            focusedBorder:
                                                const OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Colors.blue)),
                                            errorBorder:
                                                const OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Colors.red)),
                                            focusedErrorBorder:
                                                const OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Colors.red,
                                                        width: 1.5)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        margin: const EdgeInsets.all(10.0),
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            labelText: 'Frequency',
                                            enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.grey)),
                                            focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.blue)),
                                            errorBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.red)),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Colors.red,
                                                        width: 1.5)),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: SizedBox(
                                              height: 26.0,
                                              child: DropdownButton(
                                                isExpanded: true,
                                                icon: const Icon(
                                                    Icons.arrow_drop_down),
                                                value: _selectedDurationFreq,
                                                items: _durationFreqItems.map(
                                                    (String positionItems) {
                                                  return DropdownMenuItem(
                                                    value: positionItems,
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(positionItems),
                                                  );
                                                }).toList(),
                                                onChanged: (String? newValue) {
                                                  setState(() {
                                                    _selectedDurationFreq =
                                                        newValue!;
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                        ],
                      ),
                      if (!_customDurationSet) SizedBox(height: 8.0),
                      Container(
                        margin: const EdgeInsets.all(10.0),
                        width: MediaQuery.of(context).size.width * 0.6,
                        child: Builder(
                          builder: (context) {
                            return TextFormField(
                              readOnly: true,
                              textDirection: TextDirection.ltr,
                              controller: _liscenseController,
                              /*  inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(_regExUName)),
                              ], */

                              decoration: InputDecoration(
                                suffixIcon: !_isLiscenseCopied
                                    ? IconButton(
                                        tooltip: 'Copy',
                                        splashRadius: 18.0,
                                        onPressed: _liscenseController
                                                .text.isEmpty
                                            ? null
                                            : () async {
                                                Clipboard.setData(
                                                  ClipboardData(
                                                      text: _liscenseController
                                                          .text),
                                                );

                                                setState(() {
                                                  _isLiscenseCopied = true;
                                                });
                                              },
                                        icon:
                                            const Icon(Icons.copy, size: 15.0),
                                      )
                                    : const Icon(Icons.done_rounded),
                                contentPadding: const EdgeInsets.all(23.0),
                                border: const OutlineInputBorder(),
                                labelText: 'Product Key',
                                enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey)),
                                focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.blue)),
                                errorBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.red)),
                                focusedErrorBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.red, width: 1.5)),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(10.0),
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: 40.0,
                        child: Builder(
                          builder: (context) {
                            return OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                side: const BorderSide(
                                  color: Colors.blue,
                                ),
                              ),
                              onPressed: () async {
                                DateTime expireAt;
                                if (_liscenseFormKey.currentState!.validate()) {
                                  try {
                                    // Textfield values are used here
                                    if (_customDurationSet) {
                                      if (_selectedDurationFreq == 'Days') {
                                        expireAt = DateTime.now().add(Duration(
                                            days: int.parse(
                                                _customDurationController
                                                    .text)));
                                      } else if (_selectedDurationFreq ==
                                          'Months') {
                                        expireAt = DateTime.now().add(Duration(
                                            days: int.parse(
                                                    _customDurationController
                                                        .text) *
                                                30));
                                      } else {
                                        expireAt = DateTime.now().add(Duration(
                                            days: int.parse(
                                                    _customDurationController
                                                        .text) *
                                                365));
                                      }
                                      // Radio Button values start here
                                    } else {
                                      if (_validDurationGroupValue == -1) {
                                        expireAt = DateTime(9999);
                                      } else {
                                        expireAt = DateTime.now().add(Duration(
                                            days: _validDurationGroupValue));
                                      }
                                    }
                                    // Generate liscense key and assign it to a variable
                                    _liscenseKey =
                                        _globalUsage.generateProductKey(
                                            expireAt,
                                            _machineCodeController.text);
                                    // Assign the generated liscense to its field
                                    _liscenseController.text = _liscenseKey;
                                    setState(() {
                                      _isLiscenseCopied = false;
                                    });
                                  } catch (e) {
                                    print('Generating liscense key faield: $e');
                                  }
                                }
                              },
                              label: const Text('Generate'),
                              icon: const Icon(Icons.vpn_key_outlined),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// This function saves switch state into a shared preference.
  void saveSwitchState(String key, bool value) async {
    // Create a shared preferences variable
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }

// Fetch switches values when called
  void loadSwitchState(String key, Function(bool) onLoaded) async {
    final prefs = await SharedPreferences.getInstance();
    bool value = prefs.getBool(key) ?? false;
    onLoaded(value);
  }

  Future<bool> getSwitchState(String key) async {
    final prefs = await SharedPreferences.getInstance();
    bool value = prefs.getBool(key) ?? false;
    return value;
  }

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
}

// This class contain all features flags - PRO & STANDARD features
class Features {
  static bool genPrescription = false;
  static bool upcomingAppointment = false;
  static bool XRayManage = false;
  static bool createBackup = false;
  static bool restoreBackup = false;
  static int allowedUsersLimit = 0;
  static int allowedPatientsLimit = -1;
  static int allowedStaffLimit = -1;
  static int allowedExpenseLimit = -1;

// This function gets number of user acounts and checks if limit has reached.
  static Future<bool> userLimitReached() async {
    try {
      final conn = await onConnToSqliteDb();
      var result =
          await conn.rawQuery('SELECT COUNT(*) AS num_of_user FROM staff_auth');
      int numOfUsers = result.first["num_of_user"] as int;
      if (numOfUsers >= allowedUsersLimit && allowedUsersLimit != 0) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Fetching number of users failed: $e');
      return false;
    }
  }

  // This function gets number of patients and checks if limit has reached.
  static Future<bool> patientLimitReached() async {
    try {
      final conn = await onConnToSqliteDb();
      var result =
          await conn.query('SELECT COUNT(*) AS num_of_patients FROM patients');
      int numOfPatients = result.first["num_of_patients"] as int;
      if (numOfPatients >= allowedPatientsLimit && allowedPatientsLimit != -1) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Fetching number of patients failed: $e');
      return false;
    }
  }

  // This function gets number of staff and checks if limit has reached.
  static Future<bool> staffLimitReached() async {
    try {
      final conn = await onConnToSqliteDb();
      var result =
          await conn.rawQuery('SELECT COUNT(*) AS num_of_staff FROM staff');
      int numOfStaff = result.first["num_of_staff"] as int;
      if (numOfStaff >= allowedStaffLimit && allowedStaffLimit != 0) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Fetching number of staff failed: $e');
      return false;
    }
  }

  // This function gets number of expenses and checks if limit has reached.
  static Future<bool> expenseLimitReached() async {
    try {
      final conn = await onConnToSqliteDb();
      var result = await conn
          .rawQuery('SELECT COUNT(*) AS num_of_exp_detail FROM expense_detail');
      int numOfExpenseDetail = result.first["num_of_exp_detail"] as int;
      if (numOfExpenseDetail >= allowedExpenseLimit &&
          allowedExpenseLimit != -1) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Fetching number of expense details failed: $e');
      return false;
    }
  }

// This function enables / disables the premium features based on the version type.
  static void setVersion(String version) {
    if (version == 'Premium') {
      genPrescription = true;
      upcomingAppointment = true;
      XRayManage = true;
      createBackup = true;
      restoreBackup = true;
      allowedUsersLimit = 3;
      allowedStaffLimit = 50;
    } else if (version == 'Standard') {
      genPrescription = false;
      upcomingAppointment = false;
      XRayManage = false;
      createBackup = false;
      restoreBackup = false;
      allowedUsersLimit = 2;
      allowedPatientsLimit = 200;
      allowedStaffLimit = 10;
      allowedExpenseLimit = 200;
    }
  }
}
