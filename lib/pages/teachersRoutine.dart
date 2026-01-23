import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sheet_routine/data/hive.dart';
import 'package:sheet_routine/fetcher/excel_fetcher.dart';
import 'package:sheet_routine/pages/google_sheet_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class TeachersRoutine extends StatefulWidget {
  const TeachersRoutine({Key? key}) : super(key: key);
  @override
  _TeachersRoutineState createState() => _TeachersRoutineState();
}

String subPreProcessor(String input) {
  var temp1 = input.split("\n");
  var sub = temp1[1];
  var teacher = temp1[0];
  var room = temp1[2];
  var text = teacher.split(",");
  if (text.length > 1) {
    teacher = "${text[0].trim()}\n${text[1].trim()}";
  }
  return "$sub\n$teacher\n$room";
}

class _TeachersRoutineState extends State<TeachersRoutine> {
  final List<String> days = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  String? selectedTeacher;
  Map<String, List<dynamic>>? teachersRoutine;
  List<String>? timingData;
  Future<Map<String, List<dynamic>>?> _getConfig() async {
    final teachersRoutine = await getValueFromHive(
      "routine",
      "teachersRoutine",
      null,
    );

    return Map<String, List<dynamic>>.from(teachersRoutine);
  }

  void _getTime() async {
    final time = await getValueFromHive("routine", "timeData", null);
    if (time != null) {
      timingData = List<String>.from(time);
    }
    else{
      if(mounted){
        Navigator.pop(context);
        ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Sync First!")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _getTime();
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder(
          future: _getConfig(),

          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (snapshot.data == null) {
              return Text('Sync Routine First');
            }

            var teachersList = snapshot.data!.keys.toList();
            teachersList.sort((a,b)=> a.compareTo(b));

            teachersRoutine = snapshot.data;
            return Autocomplete(
              optionsBuilder: (textEditingValue) {
                return teachersList.where(
                  (item) => item.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ),
                );
              },
              onSelected: (item) => setState(() {
                selectedTeacher = item;
              }),
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        //border: OutlineInputBorder(),
                        labelText: selectedTeacher ?? 'Select Teacher',
                        hintText: 'Select Teacher',
                        suffixIcon: Icon(Icons.search),
                      ),
                    );
                  },
            );
          },
        ),

        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        
      ),
      body: selectedTeacher != null && teachersRoutine != null
          ? ListView.builder(
              itemCount: days.length,
              itemBuilder: (cntx, index) {
                var routineSorted = teachersRoutine![selectedTeacher]!
                    .where((element) => element[0] == days[index])
                    .toList();
                routineSorted.sort((a, b) => (a[1] as int).compareTo(b[1]));
                  
                if (routineSorted.isEmpty) {
                  return SizedBox.shrink();
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        days[index],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: routineSorted.length,
                      itemBuilder: (BuildContext context, int ind) {
                        final int startingTimePlussed = routineSorted[ind][1];
                        return Card(
                          child: Padding(
                            padding: EdgeInsetsGeometry.all(7),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  children: [
                                    Text(timingData![startingTimePlussed - 1]),
                                    Text("|"),
                                    Text(
                                      timingData!.length > startingTimePlussed
                                          ? (timingData![startingTimePlussed])
                                          : "End",
                                    ),
                                  ],
                                ),
                                Divider(),
                                Text(
                                  subPreProcessor(routineSorted[ind][2]),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            )
          : Center(child: Text("Select a teacher name.")),
    );
  }
}
