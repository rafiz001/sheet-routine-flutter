import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sheet_routine/data/hive.dart';
import 'package:sheet_routine/fetcher/excel_fetcher.dart';
import 'package:sheet_routine/pages/google_sheet_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sheet_routine/pages/teachersRoutine.dart';

import 'package:http/http.dart' as http;

class Roomcheacker extends StatefulWidget {
  const Roomcheacker({Key? key}) : super(key: key);
  @override
  _RoomcheackerState createState() => _RoomcheackerState();
}



class _RoomcheackerState extends State<Roomcheacker> {
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
  Map<String, List<dynamic>>? roomFilter;
  List<String>? timingData;
  Future<Map<String, List<dynamic>>?> _getConfig() async {
    final roomFilter = await getValueFromHive(
      "routine",
      "roomFilter",
      null,
    );

    return Map<String, List<dynamic>>.from(roomFilter);
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

            var roomList = snapshot.data!.keys.toList();
            roomList.sort((a,b)=> a.compareTo(b));
            roomFilter = snapshot.data;
            return Autocomplete(
              optionsBuilder: (textEditingValue) {
                return roomList.where(
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
                        labelText: selectedTeacher ?? 'Select Room',
                        hintText: 'Select Room',
                        suffixIcon: Icon(Icons.search),
                      ),
                    );
                  },
            );
          },
        ),

        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        
      ),
      body: selectedTeacher != null && roomFilter != null
          ? ListView.builder(
              itemCount: days.length,
              itemBuilder: (cntx, index) {
                var routineSorted = roomFilter![selectedTeacher]!
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
          : Center(child: Text("Select a room name.")),
    );
  }
}
