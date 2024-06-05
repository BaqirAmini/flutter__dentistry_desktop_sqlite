import 'package:flutter/material.dart';

/* -------------------------- This stateful class is to retrieve the children's ( < 14 years old) selected teeth based on what is inserted into database i.e., it is read-only to indicate the the teeth which require procedure ---------------------- */
class ChildQuadrantGrid4SelectedTeeth extends StatefulWidget {
  final List<String> selectedTeethFromDB;
  final String chartLabel;
  const ChildQuadrantGrid4SelectedTeeth(
      {Key? key, required this.selectedTeethFromDB, required this.chartLabel})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  __ChildQuadrantGrid4SelectedTeeth createState() =>
      __ChildQuadrantGrid4SelectedTeeth();
}

class __ChildQuadrantGrid4SelectedTeeth
    extends State<ChildQuadrantGrid4SelectedTeeth> {
  Widget _buildQuadrant(String quadrantId, List<String> letters) {
    return Row(
      children: letters.map((toothLetter) {
        String id = '$quadrantId-$toothLetter';
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
                toothLetter.toString(),
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
            labelText:
                widget.chartLabel,
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
                              List<String>.generate(
                                      5, (i) => String.fromCharCode(65 + i))
                                  .reversed
                                  .toList()),
                          _buildQuadrantWithLabel(
                              'Q1',
                              List<String>.generate(
                                  5, (i) => String.fromCharCode(65 + i))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          _buildQuadrantWithLabel(
                              'Q3',
                              List<String>.generate(
                                      5, (i) => String.fromCharCode(65 + i))
                                  .reversed
                                  .toList()),
                          _buildQuadrantWithLabel(
                              'Q4',
                              List<String>.generate(
                                  5, (i) => String.fromCharCode(65 + i))),
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

  Widget _buildQuadrantWithLabel(String quadrantId, List<String> letters) {
    return Expanded(
        child: Column(
      children: [
        Text(
          quadrantId,
          style: const TextStyle(fontSize: 24),
        ),
        Expanded(
          child: _buildQuadrant(quadrantId, letters),
        ),
      ],
    ));
  }
}
