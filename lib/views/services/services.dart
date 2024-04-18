import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dentistry/config/language_provider.dart';
import 'package:flutter_dentistry/config/translations.dart';
import 'package:flutter_dentistry/models/db_conn.dart';
import 'package:flutter_dentistry/views/services/tiles.dart';
import 'package:provider/provider.dart';

void main() => runApp(const Service());

// ignore: prefer_typing_uninitialized_variables
var selectedLanguage;
// ignore: prefer_typing_uninitialized_variables
var isEnglish;

// Create the global key at the top level of your Dart file
final GlobalKey<ScaffoldMessengerState> _globalKeyForService =
    GlobalKey<ScaffoldMessengerState>();

// This is shows snackbar when called
void _onShowSnack(Color backColor, String msg) {
  _globalKeyForService.currentState?.showSnackBar(
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

class Service extends StatefulWidget {
  const Service({Key? key}) : super(key: key);

  @override
  State<Service> createState() => _ServiceState();
}

class _ServiceState extends State<Service> {
  final TextEditingController _searchQuery = TextEditingController();
  bool _isSearching = false;
  String _searchText = "";
  late List<String> _list;
  List<String> _searchList = [];

  @override
  void initState() {
    super.initState();
    _list = [];
    _searchQuery.addListener(() {
      if (_searchQuery.text.isEmpty) {
        setState(() {
          _isSearching = false;
          _searchText = "";
          _buildSearchList();
        });
      } else {
        setState(() {
          _isSearching = true;
          _searchText = _searchQuery.text;
          _buildSearchList();
        });
      }
    });
  }

  List<String> _buildSearchList() {
    if (_searchText.isEmpty) {
      return _searchList = _list;
    } else {
      _searchList = _list
          .where((element) =>
              element.toLowerCase().contains(_searchText.toLowerCase()))
          .toList();
      return _searchList;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fetch translations keys based on the selected language.
    var languageProvider = Provider.of<LanguageProvider>(context);
    selectedLanguage = languageProvider.selectedLanguage;
    isEnglish = selectedLanguage == 'English';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ScaffoldMessenger(
        key: _globalKeyForService,
        child: Scaffold(
          backgroundColor: const Color.fromARGB(255, 234, 231, 231),
          appBar: AppBar(
            /*  actions: [
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  onPressed: () {
                    setState(() {
                      if (_isSearching) {
                        _isSearching = false;
                        _searchQuery.clear();
                      } else {
                        _isSearching = true;
                      }
                    });
                  },
                ),
                const SizedBox(width: 20),
                Builder(builder: (context) {
                  return Tooltip(
                    message: 'افزودن خدمات',
                    child: IconButton(
                      onPressed: () {
                        onCreateDentalService(context);
                      },
                      icon: const Icon(Icons.medical_services_outlined),
                    ),
                  );
                }),
                const SizedBox(width: 20),
              ], */
            title: _isSearching
                ? TextField(
                    controller: _searchQuery,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        hintText: translations[selectedLanguage]?['Search'] ?? '',
                        hintStyle: TextStyle(color: Colors.white)),
                  )
                :  Text(translations[selectedLanguage]?['Services'] ?? ''),
          ),
          body: const ServicesTile(),
        ),
      ),
    );
  }

  // This dialog creates a new Service
  onCreateDentalService(BuildContext context) {
// The global for the form
    final formKey = GlobalKey<FormState>();
// The text editing controllers for the TextFormFields
    final nameController = TextEditingController();
    final feeController = TextEditingController();

    return showDialog(
      context: context,
      builder: ((context) {
        return AlertDialog(
          title: const Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'ایجاد سرویس جدید',
              style: TextStyle(color: Colors.blue),
            ),
          ),
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Form(
              key: formKey,
              child: SizedBox(
                width: 500.0,
                height: 190.0,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(20.0),
                      child: TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'نام سرویس (خدمات)',
                          suffixIcon: Icon(Icons.medical_services_sharp),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(50.0)),
                              borderSide: BorderSide(color: Colors.grey)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(50.0)),
                              borderSide: BorderSide(color: Colors.blue)),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(20.0),
                      child: TextFormField(
                        controller: feeController,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                        ],
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'فیس تعیین شده',
                          suffixIcon: Icon(Icons.money),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(50.0)),
                              borderSide: BorderSide(color: Colors.grey)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(50.0)),
                              borderSide: BorderSide(color: Colors.blue)),
                        ),
                      ),
                    ),
                  ],
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
                    child: const Text('لغو'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      String serviceName = nameController.text;
                      double serviceFee = feeController.text.isEmpty
                          ? 0
                          : double.parse(feeController.text);
                      final conn = await onConnToSqliteDb();
                      final results = await conn.rawInsert(
                        'INSERT INTO services (ser_name, ser_fee) VALUES(?, ?)',
                        [serviceName, serviceFee],
                      );
                      if (results > 0) {
                        _onShowSnack(Colors.green, 'سرویس موفقانه ثبت شد.');
                      } else {
                        _onShowSnack(Colors.red, 'متأسفم، ثبت سرویس ناکام شد.');
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('ایجاد کردن'),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
