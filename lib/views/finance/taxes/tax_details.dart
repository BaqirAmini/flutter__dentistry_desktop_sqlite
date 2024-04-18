import 'package:flutter/material.dart';
import 'package:flutter_dentistry/config/language_provider.dart';
import 'package:flutter_dentistry/config/translations.dart';
import 'package:flutter_dentistry/views/finance/taxes/tax_info.dart';
import 'package:provider/provider.dart';

// ignore: prefer_typing_uninitialized_variables
var selectedLanguage;
// ignore: prefer_typing_uninitialized_variables
var isEnglish;

class TaxDetails extends StatelessWidget {
  const TaxDetails({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Fetch translations keys based on the selected language.
    var languageProvider = Provider.of<LanguageProvider>(context);
    selectedLanguage = languageProvider.selectedLanguage;
    isEnglish = selectedLanguage == 'English';
    return SizedBox(
      width: 500.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            color: const Color.fromARGB(255, 240, 239, 239),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translations[selectedLanguage]?['TIN'] ?? '',
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Color.fromARGB(255, 118, 116, 116),
                  ),
                ),
                Text('${TaxInfo.TIN}'),
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
                width: 240.0,
                padding: const EdgeInsets.all(10.0),
                color: const Color.fromARGB(255, 240, 239, 239),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      translations[selectedLanguage]?['TaxOfYear'] ?? '',
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Color.fromARGB(255, 118, 116, 116),
                      ),
                    ),
                    Text('${TaxInfo.taxOfYear} ه.ش'),
                  ],
                ),
              ),
              Container(
                width: 240.0,
                padding: const EdgeInsets.all(10.0),
                color: const Color.fromARGB(255, 240, 239, 239),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      translations[selectedLanguage]?['TaxRate'] ?? '',
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Color.fromARGB(255, 118, 116, 116),
                      ),
                    ),
                    Text('${TaxInfo.taxRate} %'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 15.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 240.0,
                padding: const EdgeInsets.all(10.0),
                color: const Color.fromARGB(255, 240, 239, 239),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      translations[selectedLanguage]?['TaxPaidRate'] ?? '',
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Color.fromARGB(255, 118, 116, 116),
                      ),
                    ),
                    Text('${TaxInfo.paidDate}'),
                  ],
                ),
              ),
              Container(
                width: 240.0,
                padding: const EdgeInsets.all(10.0),
                color: const Color.fromARGB(255, 240, 239, 239),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      translations[selectedLanguage]?['AnnTotTax'] ?? '',
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Color.fromARGB(255, 118, 116, 116),
                      ),
                    ),
                    Text(
                        '${TaxInfo.annTotTaxes.toString()} ${translations[selectedLanguage]?['Afn'] ?? ''}'),
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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  translations[selectedLanguage]?['TaxDue'] ?? '',
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Color.fromARGB(255, 118, 116, 116),
                  ),
                ),
                Text(
                    '${TaxInfo.dueTaxes} ${translations[selectedLanguage]?['Afn'] ?? ''}'),
              ],
            ),
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
                  translations[selectedLanguage]?['TaxPaidBy'] ?? '',
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Color.fromARGB(255, 118, 116, 116),
                  ),
                ),
                Text('${TaxInfo.firstName} ${TaxInfo.lastName}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
