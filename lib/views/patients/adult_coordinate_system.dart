import 'package:flutter/material.dart';
import 'package:flutter_dentistry/config/language_provider.dart';
import 'package:flutter_dentistry/config/translations.dart';
import 'package:flutter_dentistry/views/patients/tooth_selection_info.dart';
import 'package:provider/provider.dart';

// ignore: prefer_typing_uninitialized_variables
var selectedLanguage;
// ignore: prefer_typing_uninitialized_variables
var isEnglish;

class AdultQuadrantGrid extends StatefulWidget {
  const AdultQuadrantGrid({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _AdultQuadrantGrid createState() => _AdultQuadrantGrid();
}

class _AdultQuadrantGrid extends State<AdultQuadrantGrid> {
  final List<String> _selectedTeethNum = [];
  final Map<String, bool> _isHovering = {};
  bool _allTeethSelected = false;

  Widget _buildQuadrant(String quadrantId, List<int> toothNumbers) {
    return Row(
      children: toothNumbers.map((toothNum) {
        String id = '$quadrantId-$toothNum';
        return Expanded(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovering[id] = true),
            onExit: (_) => setState(() => _isHovering[id] = false),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_selectedTeethNum.contains(id)) {
                    _selectedTeethNum.remove(id);
                  } else {
                    _selectedTeethNum.add(id);
                  }
                  _onArrangeAdultSelectedTeeth(_selectedTeethNum);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: _selectedTeethNum.contains(id)
                      ? Colors.blue
                      : (_isHovering[id] ?? false
                          ? const Color.fromARGB(255, 71, 190, 245)
                          : Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    toothNum.toString(),
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fetch translations keys based on the selected language.
    var languageProvider = Provider.of<LanguageProvider>(context);
    selectedLanguage = languageProvider.selectedLanguage;
    isEnglish = selectedLanguage == 'English';
    Tooth.adultToothSelected = _selectedTeethNum.isEmpty ? false : true;
    return Column(
      children: [
        InputDecorator(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _selectedTeethNum.isEmpty
                // ignore: unnecessary_string_interpolations
                ? '${translations[selectedLanguage]?['SelectTeeth'] ?? ''}'
                // ignore: unnecessary_string_interpolations
                : '${translations[selectedLanguage]?['AdultTeethSelection'] ?? ''}',
            contentPadding: const EdgeInsets.all(20),
            floatingLabelAlignment: FloatingLabelAlignment.center,
            labelStyle: TextStyle(
                color: _selectedTeethNum.isEmpty ? Colors.red : Colors.blue,
                fontSize: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(30.0)),
              borderSide: BorderSide(
                  color: _selectedTeethNum.isEmpty ? Colors.red : Colors.blue),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(50.0),
              ),
            ),
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _buildQuadrantWithLabel(
                            'Q2',
                            List<int>.generate(
                              8,
                              (i) => (i + 1),
                            ).reversed.toList(),
                          ),
                          _buildQuadrantWithLabel(
                            'Q1',
                            List<int>.generate(
                              8,
                              (i) => (i + 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          _buildQuadrantWithLabel(
                            'Q3',
                            List<int>.generate(
                              8,
                              (i) => (i + 1),
                            ).reversed.toList(),
                          ),
                          _buildQuadrantWithLabel(
                            'Q4',
                            List<int>.generate(
                              8,
                              (i) => (i + 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Center(
                  child: Container(
                    width: 1,
                    height: double.infinity,
                    color: Colors.blue,
                  ),
                ),
                Center(
                  child: Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
        Directionality(
          textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Checkbox(
                    value: _allTeethSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        _allTeethSelected = value!;
                        if (_allTeethSelected) {
                          _selectedTeethNum.clear();
                          _selectedTeethNum.addAll([
                            'Q1-1',
                            'Q1-2',
                            'Q1-3',
                            'Q1-4',
                            'Q1-5',
                            'Q1-6',
                            'Q1-7',
                            'Q1-8',
                            'Q2-1',
                            'Q2-2',
                            'Q2-3',
                            'Q2-4',
                            'Q2-5',
                            'Q2-6',
                            'Q2-7',
                            'Q2-8',
                            'Q3-1',
                            'Q3-2',
                            'Q3-3',
                            'Q3-4',
                            'Q3-5',
                            'Q3-6',
                            'Q3-7',
                            'Q3-8',
                            'Q4-1',
                            'Q4-2',
                            'Q4-3',
                            'Q4-4',
                            'Q4-5',
                            'Q4-6',
                            'Q4-7',
                            'Q4-8',
                          ]);
                          _onArrangeAdultSelectedTeeth(_selectedTeethNum);
                        } else {
                          _selectedTeethNum.clear();
                        }
                      });
                    },
                  ),
                ),
              ),
              Text(translations[selectedLanguage]?['AllTeeth'] ?? ''),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildQuadrantWithLabel(String quadrantId, List<int> toothNumbers) {
    return Expanded(
        child: Column(
      children: [
        Text(
          quadrantId,
          style: const TextStyle(fontSize: 24),
        ),
        Expanded(
          child: _buildQuadrant(quadrantId, toothNumbers),
        ),
      ],
    ));
  }

  void _onArrangeAdultSelectedTeeth(List<String> toothNumSelected) {
    var letterDelimiter = toothNumSelected.join(',');
    Tooth.selectedAdultTeeth = letterDelimiter;
  }
}
