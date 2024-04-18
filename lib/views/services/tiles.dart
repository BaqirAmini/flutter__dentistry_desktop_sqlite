import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dentistry/config/language_provider.dart';
import 'package:flutter_dentistry/config/translations.dart';
import 'package:flutter_dentistry/models/db_conn.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

// Create the global key at the top level of your Dart file
final GlobalKey<ScaffoldMessengerState> _globalKeyForService =
    GlobalKey<ScaffoldMessengerState>();

// ignore: prefer_typing_uninitialized_variables
var selectedLanguage;
// ignore: prefer_typing_uninitialized_variables
var isEnglish;

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

class ServicesTile extends StatefulWidget {
  const ServicesTile({Key? key}) : super(key: key);

  @override
  State<ServicesTile> createState() => _ServicesTileState();
}

class _ServicesTileState extends State<ServicesTile> {
  // Fetch services from services table
  Future<List<Service>> getServices() async {
    final conn = await onConnToSqliteDb();
    final results =
        await conn.rawQuery('SELECT ser_ID, ser_name, ser_fee FROM services');
    final services = results
        .map((row) => Service(
              serviceID: row["ser_ID"] as int,
              serviceName: row["ser_name"].toString(),
              serviceFee: row["ser_fee"] == null ? 0 : row["ser_fee"] as double,
            ))
        .toList();

    return services;
  }

  @override
  Widget build(BuildContext context) {
    // Fetch translations keys based on the selected language.
    var languageProvider = Provider.of<LanguageProvider>(context);
    selectedLanguage = languageProvider.selectedLanguage;
    isEnglish = selectedLanguage == 'English';
    return ScaffoldMessenger(
      key: _globalKeyForService,
      child: Scaffold(
        body: CustomScrollView(
          primary: false,
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: FutureBuilder(
                future: getServices(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final services = snapshot.data;
                    return SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisSpacing: 1,
                        mainAxisSpacing: 1,
                        crossAxisCount: 5,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          final service = services![index];
                          return SizedBox(
                            height: 80.0,
                            width: 80.0,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              elevation: 0.4,
                              child: Stack(
                                children: [
                                  Center(
                                    child: onSetTileContent(service.serviceName,
                                        service.serviceFee),
                                  ),
                                  isEnglish
                                      ? Positioned(
                                          top: 8.0,
                                          right: 8.0,
                                          child: PopupMenuButton(
                                              iconColor: Colors.grey,
                                              splashRadius: 25.0,
                                              itemBuilder: (BuildContext
                                                      context) =>
                                                  <PopupMenuEntry>[
                                                    PopupMenuItem(
                                                      child: Builder(builder:
                                                          (BuildContext
                                                              context) {
                                                        return ListTile(
                                                          leading: const Icon(
                                                              Icons.edit),
                                                          title: Text(translations[
                                                                      selectedLanguage]
                                                                  ?['Edit'] ??
                                                              ''),
                                                          onTap: () {
                                                            onEditDentalService(
                                                                context,
                                                                service
                                                                    .serviceID,
                                                                service
                                                                    .serviceName,
                                                                service
                                                                    .serviceFee);
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                        );
                                                      }),
                                                    ),
                                                    /*   PopupMenuItem(
                                                child: Directionality(
                                                  textDirection:
                                                      TextDirection.rtl,
                                                  child: ListTile(
                                                      leading: const Icon(
                                                          Icons.delete),
                                                      title: const Text(
                                                          'حذف کردن'),
                                                      onTap: () {
                                                        onDeleteDentalService(
                                                            context);
                                                        Navigator.pop(context);
                                                      }),
                                                ),
                                              ), */
                                                  ]),
                                        )
                                      : Positioned(
                                          top: 8.0,
                                          left: 8.0,
                                          child: PopupMenuButton(
                                              iconColor: Colors.grey,
                                              splashRadius: 25.0,
                                              itemBuilder: (BuildContext
                                                      context) =>
                                                  <PopupMenuEntry>[
                                                    PopupMenuItem(
                                                      child: Builder(builder:
                                                          (BuildContext
                                                              context) {
                                                        return ListTile(
                                                          leading: const Icon(
                                                              Icons.edit),
                                                          title: Text(translations[
                                                                      selectedLanguage]
                                                                  ?['Edit'] ??
                                                              ''),
                                                          onTap: () {
                                                            onEditDentalService(
                                                                context,
                                                                service
                                                                    .serviceID,
                                                                service
                                                                    .serviceName,
                                                                service
                                                                    .serviceFee);
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                        );
                                                      }),
                                                    ),
                                                    /*   PopupMenuItem(
                                                child: Directionality(
                                                  textDirection:
                                                      TextDirection.rtl,
                                                  child: ListTile(
                                                      leading: const Icon(
                                                          Icons.delete),
                                                      title: const Text(
                                                          'حذف کردن'),
                                                      onTap: () {
                                                        onDeleteDentalService(
                                                            context);
                                                        Navigator.pop(context);
                                                      }),
                                                ),
                                              ), */
                                                  ]),
                                        ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: services!.length,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else {
                    return const SliverToBoxAdapter(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

// Set icon and text as contents of any tile.
  onSetTileContent(String serviceName, double price) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircleAvatar(
          radius: 30.0,
          backgroundColor: Colors.green,
          child: Icon(FontAwesomeIcons.tooth, color: Colors.white),
        ),
        const SizedBox(
          height: 10.0,
        ),
        Text(
          textAlign: TextAlign.center,
          serviceName,
          style:
              Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 16.0),
        ),
        const SizedBox(
          height: 10.0,
        ),
        Text(
          '$price ${translations[selectedLanguage]?['Afn'] ?? ''}',
          style: const TextStyle(
              fontSize: 14.0, color: Color.fromARGB(255, 105, 101, 101)),
        ),
      ],
    );
  }

  // This dialog edits a Service
  onEditDentalService(BuildContext context, int serviceId, String serviceName,
      double serviceFee) {
// The global for the form
    final formKey = GlobalKey<FormState>();
// The text editing controllers for the TextFormFields
    final nameController = TextEditingController();
    final feeController = TextEditingController();

    nameController.text = serviceName;
    feeController.text = serviceFee.toString();
    const regExOnlyAbc = "[a-zA-Z,().، \u0600-\u06FFF]";

    return showDialog(
      context: context,
      builder: ((context) {
        return AlertDialog(
          title: Directionality(
            textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
            child: Text(
              translations[selectedLanguage]?['EditSer'] ?? '',
              style: const TextStyle(color: Colors.blue),
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
                      margin: const EdgeInsets.all(15.0),
                      child: TextFormField(
                        controller: nameController,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return translations[selectedLanguage]
                                    ?['SerNameRequired'] ??
                                '';
                          } else if (value.length < 5 || value.length > 30) {
                            return translations[selectedLanguage]
                                    ?['SerNameLength'] ??
                                '';
                          }
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(regExOnlyAbc),
                          ),
                        ],
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText:
                              translations[selectedLanguage]?['SerName'] ?? '',
                          suffixIcon: const Icon(Icons.medical_services_sharp),
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
                      margin: const EdgeInsets.all(15.0),
                      child: TextFormField(
                        controller: feeController,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                        ],
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText:
                              translations[selectedLanguage]?['SerFee'] ?? '',
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
                              borderSide:
                                  BorderSide(color: Colors.red, width: 1.5)),
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
              textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
              child: Row(
                mainAxisAlignment:
                    isEnglish ? MainAxisAlignment.start : MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                          translations[selectedLanguage]?['CancelBtn'] ?? '')),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        String serName = nameController.text;
                        double serFee = feeController.text.isNotEmpty
                            ? double.parse(feeController.text)
                            : 0;
                        final conn = await onConnToSqliteDb();
                        final results = await conn.rawUpdate(
                            'UPDATE services SET ser_name = ?, ser_fee = ? WHERE ser_ID = ?',
                            [serName, serFee, serviceId]);
                        if (results > 0) {
                          _onShowSnack(
                              Colors.green,
                              translations[selectedLanguage]?['StaffEditMsg'] ??
                                  '');
                          setState(() {});
                        } else {
                          _onShowSnack(
                              Colors.red,
                              translations[selectedLanguage]
                                      ?['StaffEditErrMsg'] ??
                                  '');
                        }
                        // ignore: use_build_context_synchronously
                        Navigator.of(context, rootNavigator: true).pop();
                      }
                    },
                    child: Text(translations[selectedLanguage]?['Edit'] ?? ''),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

// This dialog is to delete a dental service
  /* onDeleteDentalService(BuildContext context) {
    return showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Directionality(
                textDirection: TextDirection.rtl,
                child: Text('حذف سرویس'),
              ),
              content: const Directionality(
                textDirection: TextDirection.rtl,
                child: Text('آیا میخواهید این سرویس را حذف کنید؟'),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                    child: const Text('لغو')),
                TextButton(onPressed: () {}, child: const Text('حذف')),
              ],
            ));
  }
 */
}

// Data Model of services
class Service {
  final int serviceID;
  final String serviceName;
  final double serviceFee;

  // Calling the constructor
  Service(
      {required this.serviceID,
      required this.serviceName,
      required this.serviceFee});
}
