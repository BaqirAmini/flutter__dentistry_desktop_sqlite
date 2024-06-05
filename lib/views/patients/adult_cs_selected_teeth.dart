import 'package:flutter/material.dart';
// ignore: prefer_typing_uninitialized_variables
var selectedLanguage;
// ignore: prefer_typing_uninitialized_variables
var isEnglish;

/* -------------------------- This stateful class is to retrieve the Adults' (> 14 years old) selected teeth based on what is inserted into database i.e., it is read-only to indicate the the teeth which require procedure ---------------------- */
class AdultQuadrantGrid4SelectedTeeth extends StatefulWidget {
  final List<String> selectedTeethFromDB;
  final String chartLabel;
  const AdultQuadrantGrid4SelectedTeeth(
      {Key? key, required this.selectedTeethFromDB, required this.chartLabel})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _AdultQuadrantGrid4SelectedTeeth createState() =>
      _AdultQuadrantGrid4SelectedTeeth();
}

class _AdultQuadrantGrid4SelectedTeeth
    extends State<AdultQuadrantGrid4SelectedTeeth> {
  Widget _buildQuadrant(String quadrantId, List<int> toothNumbers) {
    return Row(
      children: toothNumbers.map((toothNum) {
        String id = '$quadrantId-$toothNum';
        bool isSelected = widget.selectedTeethFromDB.contains(id);
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                toothNum.toString(),
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InputDecorator(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: widget.chartLabel,
            contentPadding: const EdgeInsets.all(20),
            floatingLabelAlignment: FloatingLabelAlignment.center,
            labelStyle: const TextStyle(color: Colors.blue, fontSize: 18),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0)),
              borderSide: BorderSide(color: Colors.blue),
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
}
