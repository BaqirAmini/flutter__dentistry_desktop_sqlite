import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dentistry/config/developer_options.dart';
import 'package:flutter_dentistry/config/global_usage.dart';
import 'package:flutter_dentistry/config/language_provider.dart';
import 'package:flutter_dentistry/config/settings_provider.dart';
import 'package:flutter_dentistry/config/translations.dart';
import 'package:flutter_dentistry/models/db_conn.dart';
import 'package:flutter_dentistry/models/expense_data_model.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
// import 'package:shamsi_date/shamsi_date.dart';
import '/views/finance/expenses/expense_info.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

// Create the global key at the top level of your Dart file
final GlobalKey<ScaffoldMessengerState> _globalKey1 =
    GlobalKey<ScaffoldMessengerState>();

// This is shows snackbar when called
void _onShowSnack(Color backColor, String msg) {
  _globalKey1.currentState?.showSnackBar(
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

void main() => runApp(const ExpenseList());

// ignore: prefer_typing_uninitialized_variables
var selectedLanguage;
// ignore: prefer_typing_uninitialized_variables
var isEnglish;
var selectedCalType;
var isGregorian;

class ExpenseList extends StatefulWidget {
  const ExpenseList({Key? key}) : super(key: key);

  @override
  State<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  @override
  Widget build(BuildContext context) {
    // Fetch translations keys based on the selected language.
    var languageProvider = Provider.of<LanguageProvider>(context);
    selectedLanguage = languageProvider.selectedLanguage;
    isEnglish = selectedLanguage == 'English';

    // Choose calendar type from its provider
    var calTypeProvider = Provider.of<SettingsProvider>(context);
    selectedCalType = calTypeProvider.selectedDateType;
    isGregorian = selectedCalType == 'میلادی';

    return ScaffoldMessenger(
      key: _globalKey1,
      child: Directionality(
        textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            actions: [
              Builder(builder: (context) {
                return Tooltip(
                  message: translations[selectedLanguage]?['AddExpItem'] ?? '',
                  child: IconButton(
                    splashRadius: 27.0,
                    onPressed: () async {
                      if (await Features.expenseLimitReached()) {
                        // ignore: use_build_context_synchronously
                        GlobalUsage.showFlushbarMsg(
                            translations[selectedLanguage]?['RecordLimitMsg'] ??
                                '',
                            context,
                            isEnglish);
                      } else {
                        await fetchExpenseTypes();
                        await fetchStaff();
                        // ignore: use_build_context_synchronously
                        await onCreateExpenseItem(context);
                      }
                    },
                    icon: const Icon(Icons.monetization_on_outlined),
                  ),
                );
              }),
              const SizedBox(width: 10.0),
            ],
            title: Text(translations[selectedLanguage]?['InterExpense'] ?? ''),
          ),
          body: const ExpenseData(),
        ),
      ),
    );
  }

  String? selectedExpType;
  List<Map<String, dynamic>> expenseTypes = [];
  Future<void> fetchExpenseTypes() async {
    var conn = await onConnToSqliteDb();
    var results = await conn.rawQuery('SELECT exp_ID, exp_name FROM expenses');
    setState(() {
      expenseTypes = results
          .map((result) => {
                'exp_ID': result["exp_ID"].toString(),
                'exp_name': result["exp_name"].toString()
              })
          .toList();
    });
    selectedExpType =
        expenseTypes.isNotEmpty ? expenseTypes[0]['exp_ID'] : null;
  }

  // This dialog creates a new expense type
  onCreateExpenseType(BuildContext context, Function onRefresh) {
    // This flag is to show / hide expense types duplicate message
    bool expenseDuplicated = false;
// The global for the form
    final formKey1 = GlobalKey<FormState>();
// The text editing controllers for the TextFormFields
    final itemNameController = TextEditingController();

    return showDialog(
      context: context,
      builder: ((context) {
        return StatefulBuilder(
          builder: ((context, setState) {
            return AlertDialog(
              title: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  translations[selectedLanguage]?['AddExpType'] ?? '',
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
              content: Directionality(
                textDirection:
                    isEnglish ? TextDirection.ltr : TextDirection.rtl,
                child: Form(
                  key: formKey1,
                  child: SizedBox(
                    width: 500.0,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextFormField(
                              controller: itemNameController,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return translations[selectedLanguage]
                                          ?['ETRequired'] ??
                                      '';
                                } else if (value.length < 2 ||
                                    value.length > 20) {
                                  return translations[selectedLanguage]
                                          ?['ETLength'] ??
                                      '';
                                }
                              },
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: translations[selectedLanguage]
                                        ?['ExpenseType'] ??
                                    '',
                                suffixIcon: const Icon(Icons.category),
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
                          Visibility(
                            visible: expenseDuplicated ? true : false,
                            child: Padding(
                              padding: isEnglish
                                  ? const EdgeInsets.only(left: 25.0)
                                  : const EdgeInsets.only(right: 25.0),
                              child: Text(
                                translations[selectedLanguage]?['ETDupError'] ??
                                    '',
                                style: const TextStyle(
                                    fontSize: 14.0,
                                    color: Color.fromARGB(255, 247, 45, 45)),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                Directionality(
                    textDirection: TextDirection.rtl,
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
                            if (formKey1.currentState!.validate()) {
                              String expName = itemNameController.text;
                              var conn = await onConnToSqliteDb();
                              // Avoid duplicate entry of expenses category
                              var results1 = await conn.rawQuery(
                                  'SELECT * FROM expenses WHERE exp_name = ?',
                                  [expName]);
                              if (results1.isNotEmpty) {
                                setState(
                                  () {
                                    expenseDuplicated = true;
                                  },
                                );
                              } else {
                                // Insert into expenses
                                var result2 = await conn.rawInsert(
                                    'INSERT INTO expenses (exp_name) VALUES (?)',
                                    [expName]);
                                if (result2 > 0) {
                                  onRefresh();
                                  // ignore: use_build_context_synchronously
                                  Navigator.pop(context);
                                } else {
                                  _onShowSnack(
                                      Colors.red,
                                      translations[selectedLanguage]
                                              ?['ETError'] ??
                                          '');
                                  // ignore: use_build_context_synchronously
                                  Navigator.pop(context);
                                }
                              }
                            }
                          },
                          child: Text(
                              translations[selectedLanguage]?['AddBtn'] ?? ''),
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

  // Fetch staff for purchased by fields
  String? selectedStaffId;
  List<Map<String, dynamic>> staffList = [];
  Future<void> fetchStaff() async {
    var conn = await onConnToSqliteDb();
    var results =
        await conn.rawQuery('SELECT staff_ID, firstname, lastname FROM staff');
    setState(() {
      staffList = results
          .map((result) => {
                'staff_ID': result["staff_ID"].toString(),
                'firstname': result["firstname"],
                'lastname': result["lastname"]
              })
          .toList();
    });
    selectedStaffId = staffList.isNotEmpty ? staffList[0]['staff_ID'] : null;
  }

// The text editing controllers for the TextFormFields
  final itemNameController = TextEditingController();
  final quantityController = TextEditingController();
  final unitPriceController = TextEditingController();
  final purchaseDateController = TextEditingController();
  final totalPriceController = TextEditingController();
  final descriptionController = TextEditingController();
// This is just a sample date avoid potential exeception
  String hijriSelectedDate = '1400-1-2';

  double? totalPrice;
// Sets the total price into its related field
  void _onSetTotalPrice(String text) {
    double qty = quantityController.text.isEmpty
        ? 0
        : double.parse(quantityController.text);
    double unitPrice = unitPriceController.text.isEmpty
        ? 0
        : double.parse(unitPriceController.text);
    totalPrice = qty * unitPrice;
    totalPriceController.text =
        '$totalPrice ${translations[selectedLanguage]?['Afn'] ?? ''}';
  }

// This dialog creates a new Expense
  onCreateExpenseItem(BuildContext context) {
// The global for the form
    final formKey2 = GlobalKey<FormState>();

    // Set a dropdown for units
    String selectedUnit = 'گرام';
    var unitsItems = [
      'گرام',
      'کیلوگرام',
      'عدد',
      'قرص',
      'متر',
      'سانتی متر',
      'cc',
      'خوراک',
      'ست',
    ];

    return showDialog(
      context: context,
      builder: ((context) {
        return StatefulBuilder(
          builder: ((context, setState) {
            return AlertDialog(
              title: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  translations[selectedLanguage]?['AddExpItem'] ?? '',
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
              content: Directionality(
                textDirection:
                    isEnglish ? TextDirection.ltr : TextDirection.rtl,
                child: Form(
                  key: formKey2,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.35,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: isEnglish
                                ? const EdgeInsets.only(
                                    left: 20.0, bottom: 10.0, top: 10.0)
                                : const EdgeInsets.only(
                                    right: 20.0, bottom: 10.0, top: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.3,
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      labelText: translations[selectedLanguage]
                                              ?['ExpenseType'] ??
                                          '',
                                      enabledBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50.0)),
                                          borderSide:
                                              BorderSide(color: Colors.grey)),
                                      focusedBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50.0)),
                                          borderSide:
                                              BorderSide(color: Colors.blue)),
                                      errorBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50.0)),
                                          borderSide:
                                              BorderSide(color: Colors.red)),
                                      focusedErrorBorder:
                                          const OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(50.0)),
                                              borderSide: BorderSide(
                                                  color: Colors.red,
                                                  width: 1.5)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: Container(
                                        height: 26.0,
                                        child: DropdownButton(
                                          isExpanded: true,
                                          icon:
                                              const Icon(Icons.arrow_drop_down),
                                          value: selectedExpType,
                                          items: expenseTypes.map((expense) {
                                            return DropdownMenuItem<String>(
                                              value: expense['exp_ID'],
                                              alignment: Alignment.centerRight,
                                              child: Text(expense['exp_name']),
                                            );
                                          }).toList(),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              selectedExpType = newValue;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                    splashRadius: 25.0,
                                    tooltip: translations[selectedLanguage]
                                            ?['AddExpType'] ??
                                        '',
                                    onPressed: () =>
                                        onCreateExpenseType(context, () {
                                          setState(
                                            () {
                                              fetchExpenseTypes();
                                            },
                                          );
                                        }),
                                    icon: Icon(Icons.add, color: Colors.green)),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 10.0),
                            child: TextFormField(
                              controller: itemNameController,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return translations[selectedLanguage]
                                          ?['ItemRequired'] ??
                                      '';
                                } else if (value.length < 3 ||
                                    value.length > 10) {
                                  return translations[selectedLanguage]
                                          ?['ItemLength'] ??
                                      '';
                                }
                              },
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: translations[selectedLanguage]
                                        ?['Item'] ??
                                    '',
                                suffixIcon:
                                    const Icon(Icons.bakery_dining_outlined),
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
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 10.0),
                                  child: TextFormField(
                                    controller: quantityController,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'[0-9.]'))
                                    ],
                                    validator: (value) {
                                      if (value!.isNotEmpty) {
                                        final qty = double.tryParse(value!);
                                        if (qty! < 1 || qty > 100) {
                                          return translations[selectedLanguage]
                                                  ?['ItemQtyMsg'] ??
                                              '';
                                        }
                                      } else if (value.isEmpty) {
                                        return translations[selectedLanguage]
                                                ?['ItemQtyRequired'] ??
                                            '';
                                      }
                                    },
                                    onChanged: _onSetTotalPrice,
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      labelText: translations[selectedLanguage]
                                              ?['QtyAmount'] ??
                                          '',
                                      suffixIcon: const Icon(Icons
                                          .production_quantity_limits_outlined),
                                      enabledBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50.0)),
                                          borderSide:
                                              BorderSide(color: Colors.grey)),
                                      focusedBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50.0)),
                                          borderSide:
                                              BorderSide(color: Colors.blue)),
                                      errorBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50.0)),
                                          borderSide:
                                              BorderSide(color: Colors.red)),
                                      focusedErrorBorder:
                                          const OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(50.0)),
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
                                  margin: const EdgeInsets.all(20.0),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      labelText: translations[selectedLanguage]
                                              ?['Units'] ??
                                          '',
                                      enabledBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50.0)),
                                          borderSide:
                                              BorderSide(color: Colors.grey)),
                                      focusedBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50.0)),
                                          borderSide:
                                              BorderSide(color: Colors.blue)),
                                      errorBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(50.0)),
                                          borderSide:
                                              BorderSide(color: Colors.red)),
                                      focusedErrorBorder:
                                          const OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(50.0)),
                                              borderSide: BorderSide(
                                                  color: Colors.red,
                                                  width: 1.5)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: Container(
                                        height: 26.0,
                                        child: DropdownButton(
                                          isExpanded: true,
                                          icon:
                                              const Icon(Icons.arrow_drop_down),
                                          value: selectedUnit,
                                          items: unitsItems
                                              .map((String positionItems) {
                                            return DropdownMenuItem(
                                              value: positionItems,
                                              alignment: Alignment.centerRight,
                                              child: Text(positionItems),
                                            );
                                          }).toList(),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              selectedUnit = newValue!;
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
                          Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 10.0),
                            child: TextFormField(
                              controller: unitPriceController,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return translations[selectedLanguage]
                                          ?['UPRequired'] ??
                                      '';
                                }
                              },
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              onChanged: _onSetTotalPrice,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: translations[selectedLanguage]
                                        ?['UnitPrice'] ??
                                    '',
                                suffixIcon:
                                    const Icon(Icons.price_change_outlined),
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
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 10.0),
                            child: TextFormField(
                              readOnly: true,
                              controller: totalPriceController,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]'))
                              ],
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: translations[selectedLanguage]
                                        ?['TotalPrice'] ??
                                    '',
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
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 10.0),
                            child: TextFormField(
                              controller: descriptionController,
                              validator: (value) {
                                if (value!.isNotEmpty) {
                                  if (value.length < 5 || value.length > 40) {
                                    return translations[selectedLanguage]
                                            ?['OtherDDLDetail'] ??
                                        '';
                                  }
                                }
                              },
                              maxLines: 3,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: translations[selectedLanguage]
                                        ?['RetDetails'] ??
                                    '',
                                suffixIcon:
                                    const Icon(Icons.description_outlined),
                                enabledBorder: const OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(30.0)),
                                    borderSide: BorderSide(color: Colors.grey)),
                                focusedBorder: const OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(30.0)),
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
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 10.0),
                            child: TextFormField(
                              controller: purchaseDateController,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return translations[selectedLanguage]
                                          ?['PurDateRequired'] ??
                                      '';
                                }
                              },
                              onTap: () async {
                                FocusScope.of(context)
                                    .requestFocus(new FocusNode());
                                if (isGregorian) {
                                  final DateTime? gregDate =
                                      await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime(1900),
                                          lastDate: DateTime(2100));
                                  if (gregDate != null) {
                                    final intl.DateFormat formatter =
                                        intl.DateFormat('yyyy-MM-dd');
                                    final String formattedDate =
                                        formatter.format(gregDate);
                                    purchaseDateController.text = formattedDate;
                                  }
                                } else {
                                  // Set Hijry/Jalali calendar
                                  // ignore: use_build_context_synchronously
                                  Jalali? hijriDate =
                                      await showPersianDatePicker(
                                          context: context,
                                          initialDate: Jalali.now(),
                                          firstDate: Jalali(1395, 8),
                                          lastDate: Jalali(1450, 9));
                                  if (hijriDate != null) {
                                    final String formattedDate =
                                        hijriDate.formatFullDate();
                                    purchaseDateController.text = formattedDate;
                                    hijriSelectedDate =
                                        '${hijriDate.year}-${hijriDate.month}-${hijriDate.day}';
                                  }
                                }
                              },
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]'))
                              ],
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: translations[selectedLanguage]
                                        ?['PurDate'] ??
                                    '',
                                suffixIcon:
                                    const Icon(Icons.calendar_month_outlined),
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
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 10.0),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: translations[selectedLanguage]
                                        ?['PurchasedBy'] ??
                                    '',
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
                              child: DropdownButtonHideUnderline(
                                child: Container(
                                  height: 26.0,
                                  child: DropdownButton(
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down),
                                    value: selectedStaffId,
                                    items: staffList.map((staff) {
                                      return DropdownMenuItem<String>(
                                        value: staff['staff_ID'],
                                        alignment: Alignment.centerRight,
                                        child: Text(staff['firstname'] +
                                            ' ' +
                                            staff['lastname']),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedStaffId = newValue;
                                      });
                                    },
                                  ),
                                ),
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
                    textDirection: TextDirection.rtl,
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
                            if (formKey2.currentState!.validate()) {
                              int expID = int.parse(selectedExpType!);
                              int staffID = int.parse(selectedStaffId!);
                              String itemName = itemNameController.text;
                              double itemQty =
                                  double.parse(quantityController.text);
                              double unitPrice =
                                  double.parse(unitPriceController.text);
                              String notes = descriptionController.text;
                              // Since hijri has - separator like '1403-3-18', it should separated into parts using the dash
                              List<String>? dateParts =
                                  hijriSelectedDate.split('-');
                              // Now any part is passed to into this function to be converted to gregorian calendar
                              Jalali jalali = Jalali(
                                  int.parse(dateParts[0]),
                                  int.parse(dateParts[1]),
                                  int.parse(dateParts[2]));

                              // Convert Hijri to Gregorian calendar
                              Date gregorianDate = jalali.toGregorian();
                              // Since .toGregorian() returns Gregorian(year, month, day), i want to format like this: yyyy-MM-dd
                              intl.DateFormat formatter =
                                  intl.DateFormat('yyyy-MM-dd');
                              DateTime dateTimeGreg = DateTime(
                                  gregorianDate.year,
                                  gregorianDate.month,
                                  gregorianDate.day);
                              // It has this format '2024-06-06'
                              String formattedGreg =
                                  formatter.format(dateTimeGreg);
                              String datePurchased = isGregorian
                                  ? purchaseDateController.text
                                  : formattedGreg;
                              // Do connection with the database
                              var conn = await onConnToSqliteDb();
                              // Insert the item into expense_detail table
                              var result = await conn.rawInsert(
                                  'INSERT INTO expense_detail (exp_ID, purchased_by, item_name, quantity, qty_unit, unit_price, total, purchase_date, note) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
                                  [
                                    expID,
                                    staffID,
                                    itemName,
                                    itemQty,
                                    selectedUnit,
                                    unitPrice,
                                    totalPrice,
                                    datePurchased,
                                    notes
                                  ]);
                              if (result > 0) {
                                _onShowSnack(
                                    Colors.green,
                                    translations[selectedLanguage]
                                            ?['ExpAddSuccess'] ??
                                        '');
                                ExpenseInfo.onAddExpense!();

                                itemNameController.clear();
                                quantityController.clear();
                                unitPriceController.clear();
                                purchaseDateController.clear();
                                totalPriceController.clear();
                                descriptionController.clear();
                              } else {
                                _onShowSnack(
                                    Colors.red,
                                    translations[selectedLanguage]
                                            ?['ExpAddError'] ??
                                        '');
                              }
                              // ignore: use_build_context_synchronously
                              Navigator.pop(context);
                            }
                          },
                          child: Text(
                              translations[selectedLanguage]?['AddBtn'] ?? ''),
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
}
