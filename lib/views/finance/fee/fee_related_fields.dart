import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dentistry/config/global_usage.dart';
import 'package:flutter_dentistry/config/language_provider.dart';
import 'package:flutter_dentistry/config/private/private.dart';
import 'package:flutter_dentistry/config/translations.dart';
import 'package:flutter_dentistry/views/patients/patient_info.dart';
import 'package:flutter_dentistry/views/services/service_related_fields.dart';
import 'package:flutter_dentistry/views/staff/staff_detail.dart';
import 'package:flutter_dentistry/views/staff/staff_info.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart' as intl;

// Set global variables which are needed later.
var selectedLanguage;
var isEnglish;

class FeeForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const FeeForm({required this.formKey});

  @override
  State<FeeForm> createState() => _FeeFormState();
}

class _FeeFormState extends State<FeeForm> {
  // Declare controllers for textfields
  final _feeController = TextEditingController();
  final _recievableController = TextEditingController();
  final _discRateController = TextEditingController();
  bool _noDiscountSet = true;
  // This list to be assigned clinic info.
  List<Map<String, dynamic>> clinics = [];
  String? firstClinicID;
  String? firstClinicName;
  String? firstClinicAddr;
  String? firstClinicPhone1;
  String? firstClinicPhone2;
  String? firstClinicEmail;
  Uint8List? firstClinicLogo;

  // Declare for discount.
  bool _isVisibleForPayment = false;
  double _feeWithDiscount = 0;
  double _dueAmount = 0;
  // Create a function for setting discount
  void _setDiscount(String text) {
    double totalFee =
        _feeController.text.isEmpty ? 0 : double.parse(_feeController.text);

    setState(() {
      if (_discRateController.text.isEmpty) {
        _feeWithDiscount = totalFee;
      } else {
        double discountAmt =
            (double.parse(_discRateController.text) * totalFee) / 100;
        _feeWithDiscount = totalFee - discountAmt;
      }
    });
  }

  // Declare variables for installment rates.
  int _defaultInstallment = 0;
  final List<int> _installmentItems = [2, 3, 4, 5, 6, 7, 8, 9, 10];

  // This function deducts installments
  void _setInstallment(String text) {
    double receivable = _recievableController.text.isEmpty
        ? 0
        : double.parse(_recievableController.text);
    setState(() {
      _dueAmount = _feeWithDiscount - receivable;
    });
  }

// This function fetches clinic info by instantiation
  final GlobalUsage _globalUsage = GlobalUsage();
  void _retrieveClinics() async {
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
  }

  @override
  void initState() {
    super.initState();
    _recievableController.text = '0';
    _retrieveClinics();
  }

  @override
  void dispose() {
    _recievableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fetch translations keys based on the selected language.
    var languageProvider = Provider.of<LanguageProvider>(context);
    selectedLanguage = languageProvider.selectedLanguage;
    isEnglish = selectedLanguage == 'English';
// Assign the outputs into static class members for reusability.
    FeeInfo.fee = _feeWithDiscount;
    FeeInfo.dueAmount = _dueAmount;
    FeeInfo.discountRate = (_discRateController.text.isEmpty
        ? 0
        : double.parse(_discRateController.text));
    FeeInfo.installment = _defaultInstallment;
    // _defaultInstallment == 0 means whole fee is paid by a patient. So, no due amount is remaining.
    FeeInfo.receivedAmount = (_defaultInstallment == 0)
        ? _feeWithDiscount
        : _recievableController.text.isEmpty ||
                double.parse(_recievableController.text) == 0
            ? 0
            : double.parse(_recievableController.text);

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.width * 0.04,
        ),
        width: MediaQuery.of(context).size.width * 0.5,
        child: Form(
          key: widget.formKey,
          child: Column(
            children: [
              Text(translations[selectedLanguage]?['FeeMessage'] ?? ''),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '*',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.3,
                    margin: const EdgeInsets.only(
                        left: 20.0, right: 10.0, top: 10.0),
                    child: TextFormField(
                      autovalidateMode: AutovalidateMode.always,
                      controller: _feeController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return translations[selectedLanguage]
                                  ?['FeeRequired'] ??
                              '';
                        }
                        return null;
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(GlobalUsage.allowedDigPeriod),
                        ),
                      ],
                      onChanged: _setDiscount,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: translations[selectedLanguage]
                                ?['َServiceFee'] ??
                            '',
                        suffixIcon: const Icon(Icons.money_rounded),
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
                ],
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 10.0),
                width: MediaQuery.of(context).size.width * 0.3,
                child: Directionality(
                  textDirection:
                      isEnglish ? TextDirection.ltr : TextDirection.rtl,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Checkbox(
                            value: _noDiscountSet,
                            onChanged: (bool? newValue) {
                              setState(() {
                                _noDiscountSet = newValue!;
                                if (_noDiscountSet) {
                                  _discRateController.clear();
                                  _feeWithDiscount = _feeController.text.isEmpty
                                      ? 0
                                      : double.parse(_feeController.text);
                                  _dueAmount = _feeWithDiscount -
                                      ((_recievableController.text.isEmpty)
                                          ? 0
                                          : double.parse(
                                              _recievableController.text));
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      Text(translations[selectedLanguage]?['NoDiscount'] ?? ''),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: _noDiscountSet ? false : true,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  margin: const EdgeInsets.only(
                      left: 20.0, right: 10.0, top: 10.0, bottom: 10.0),
                  child: TextFormField(
                    controller: _discRateController,
                    autovalidateMode: AutovalidateMode.always,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return translations[selectedLanguage]
                                ?['DiscRateRequired'] ??
                            '';
                      } else if (double.parse(value) <= 0 ||
                          double.parse(value) >= 100) {
                        return translations[selectedLanguage]
                                ?['DiscRateRange'] ??
                            '';
                      }
                      return null;
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(GlobalUsage.allowedDigPeriod),
                      ),
                    ],
                    onChanged: _setDiscount,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText:
                          translations[selectedLanguage]?['DiscountRate'] ?? '',
                      suffixIcon: const Icon(Icons.money_rounded),
                      enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(50.0)),
                          borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(50.0)),
                          borderSide: BorderSide(color: Colors.blue)),
                      errorBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(50.0)),
                          borderSide: BorderSide(color: Colors.red)),
                      focusedErrorBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(50.0)),
                          borderSide:
                              BorderSide(color: Colors.red, width: 1.5)),
                    ),
                  ),
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.3,
                margin: const EdgeInsets.only(
                    left: 20.0, right: 15.0, top: 10.0, bottom: 10.0),
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText:
                        translations[selectedLanguage]?['PaymentType'] ?? '',
                    enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(50.0)),
                        borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(50.0)),
                        borderSide: BorderSide(color: Colors.blue)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: SizedBox(
                      height: 26.0,
                      child: DropdownButton<int>(
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        value: _defaultInstallment,
                        items: [
                          DropdownMenuItem(
                            value: 0,
                            child: Text(translations[selectedLanguage]
                                    ?['PayWhole'] ??
                                ''),
                          ),
                          ..._installmentItems.map((int item) {
                            return DropdownMenuItem(
                              alignment: Alignment.centerRight,
                              value: item,
                              child: Directionality(
                                textDirection: isEnglish
                                    ? TextDirection.ltr
                                    : TextDirection.rtl,
                                child: Text(
                                    '$item ${translations[selectedLanguage]?['Installment'] ?? ''}'),
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged: (int? newValue) {
                          setState(() {
                            _defaultInstallment = newValue!;
                            if (_defaultInstallment != 0) {
                              _isVisibleForPayment = true;
                              // If change the dropdown, it should display the due amount not zero
                              _dueAmount = _feeWithDiscount;
                            } else {
                              _isVisibleForPayment = false;
                              // Clear the form and assign zero to _dueAmount to reset them.
                              _recievableController.clear();
                              _dueAmount = 0;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: _isVisibleForPayment,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '*',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.3,
                      margin: const EdgeInsets.only(
                          left: 20.0, right: 10.0, top: 10.0, bottom: 10.0),
                      child: TextFormField(
                        controller: _recievableController,
                        autovalidateMode: AutovalidateMode.always,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(GlobalUsage.allowedDigPeriod),
                          ),
                        ],
                        validator: (value) {
                          if (value!.isEmpty) {
                            return translations[selectedLanguage]
                                    ?['PayAmountRequired'] ??
                                '';
                          } else if (double.parse(value) > _feeWithDiscount) {
                            return translations[selectedLanguage]
                                    ?['PayAmountValid'] ??
                                '';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            if (value.isEmpty) {
                              _dueAmount = _feeWithDiscount;
                            } else {
                              _setInstallment(value.toString());
                            }
                          });
                        },
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: translations[selectedLanguage]
                                  ?['PayAmount'] ??
                              '',
                          suffixIcon: const Icon(Icons.money_rounded),
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
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.14,
                        margin: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                            border: Border(
                          top: BorderSide(width: 1, color: Colors.grey),
                          bottom: BorderSide(width: 1, color: Colors.grey),
                        )),
                        child: InputDecorator(
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              labelText: translations[selectedLanguage]
                                      ?['TotalFee'] ??
                                  '',
                              floatingLabelAlignment:
                                  FloatingLabelAlignment.center),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Center(
                              child: Text(
                                '$_feeWithDiscount ${translations[selectedLanguage]?['Afn'] ?? ''}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(5),
                        width: MediaQuery.of(context).size.width * 0.14,
                        decoration: const BoxDecoration(
                            border: Border(
                          top: BorderSide(width: 1, color: Colors.grey),
                          bottom: BorderSide(width: 1, color: Colors.grey),
                        )),
                        child: InputDecorator(
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              labelText: translations[selectedLanguage]
                                      ?['ReceivableFee'] ??
                                  '',
                              floatingLabelAlignment:
                                  FloatingLabelAlignment.center),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Center(
                              child: _defaultInstallment == 0
                                  ? Text(
                                      '${0.0} ${translations[selectedLanguage]?['Afn'] ?? ''}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue),
                                    )
                                  : Text(
                                      '$_dueAmount ${translations[selectedLanguage]?['Afn'] ?? ''}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.06,
                    height: MediaQuery.of(context).size.height * 0.06,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: (_feeController.text.isEmpty)
                              ? Colors.grey
                              : Colors.green,
                          width: 1.5),
                    ),
                    child: IconButton(
                      tooltip: 'Create Bill',
                      splashRadius: 25.0,
                      onPressed: (_feeController.text.isEmpty)
                          ? null
                          : () => _globalUsage.onCreateReceipt(
                              firstClinicName!,
                              firstClinicAddr!,
                              firstClinicPhone1!,
                              '${StaffInfo.firstName} ${StaffInfo.lastName}',
                              ServiceInfo.selectedSerName!,
                              _feeWithDiscount,
                              (_defaultInstallment == 0)
                                  ? 1
                                  : _defaultInstallment,
                              1,
                              FeeInfo.discountRate!,
                              _feeWithDiscount,
                              (_defaultInstallment == 0)
                                  ? _feeWithDiscount
                                  : double.parse(_recievableController.text),
                              (_defaultInstallment == 0) ? 0 : _dueAmount,
                             DateTime.now().toString()),
                      icon: Icon(Icons.receipt_long_rounded,
                          color: (_feeController.text.isEmpty)
                              ? Colors.grey
                              : Colors.green,
                          size: MediaQuery.of(context).size.width * 0.015),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeeInfo {
  static double fee = 0;
  static int installment = 0;
  static double receivedAmount = 0;
  static double dueAmount = 0;
  static double? discountRate;
}
