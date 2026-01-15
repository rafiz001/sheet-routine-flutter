import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sheet_routine/data/hive.dart';
import 'package:sheet_routine/fetcher/excel_fetcher.dart';
import 'package:sheet_routine/pages/google_sheet_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class TeachersContact extends StatefulWidget {
  const TeachersContact({Key? key}) : super(key: key);
  @override
  _TeachersContactState createState() => _TeachersContactState();
}

class _TeachersContactState extends State<TeachersContact> {
  bool _isLoading = false;
  String replaceCommasInQuotedPairs(String input) {
    final result = StringBuffer();
    bool insideQuotes = false;
    int quoteCount = 0;

    for (int i = 0; i < input.length; i++) {
      final char = input[i];

      if (char == '"') {
        quoteCount++;
        insideQuotes = !insideQuotes;
        //result.write(char);
      } else if (char == ',' && insideQuotes && quoteCount % 2 == 1) {
        // Replace comma with hyphen if we're inside quotes
        result.write('-');
      } else {
        result.write(char);
      }
    }

    return result.toString();
  }

  void getTeacherDetails() async {
    setState(() {
      _isLoading = !_isLoading;
    });
    var configFromDB = await getValueFromHive("settings", "config", null);

    String sheet_ID = checkAndGet(
      configFromDB,
      "sheet_ID",
      routineConfig["sheet_ID"],
    );
    String teacher_sheet = checkAndGet(
      configFromDB,
      "teacher_sheet",
      routineConfig["teacher_sheet"],
    );
    int teacher_row = checkAndGet(
      configFromDB,
      "teacher_row",
      routineConfig["teacher_row"],
    );

    int teacher_name = checkAndGet(
      configFromDB,
      "teacher_name",
      routineConfig["teacher_name"],
    );

    List<List<String>> contacts = [];

    final response = await http.get(
      Uri.parse(
        "https://docs.google.com/spreadsheets/d/$sheet_ID/export?format=csv&id=$sheet_ID&gid=$teacher_sheet",
      ),
    );
    if (response.statusCode == 200) {
      var row = response.body.split("\n");
      for (int i = teacher_row; i < row.length; i++) {
        ;
        var cols = replaceCommasInQuotedPairs(row[i]).split(",");
        if (cols[teacher_name] == "") continue;
        List<String> colsList = [];
        colsList.add(cols[teacher_name]); //name
        colsList.add(cols[teacher_name + 1]); //designation
        colsList.add(cols[teacher_name + 2]); //dept
        colsList.add(cols[teacher_name + 3]); //inst
        colsList.add(cols[teacher_name + 4]); //phone

        contacts.add(colsList);
      }
      await setValueToHive("routine", "teachers", contacts);
      setState(() {
        _isLoading = false;
      });
      //print(jsonValue["table"]["rows"][0]['c'][0]['v']);
    }
  }

  Future<List<List<String>>?>? _getConfig() async {
    final teachers =
        await getValueFromHive("routine", "teachers", null)
            as List<List<String>>?;
    return teachers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Teachers"),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: FutureBuilder(
        future: _getConfig(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.data == null) {
            return Center(child: Text('Sync Teachers First'));
          }
          final teachers = snapshot.data;
          return Padding(
            padding: EdgeInsetsGeometry.all(12),
            child: ListView.builder(
              itemCount: teachers!.length,
              itemBuilder: (context, index) => Card(
                child: Padding(
                  padding: EdgeInsetsGeometry.all(13),
                  child: Column(
                    spacing: 10,
                    children: [
                      Text(teachers[index][0], style: TextStyle(fontSize: 20)),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Designation"),
                          Text(teachers[index][1]),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text("Dept."), Text(teachers[index][2])],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text("Ins."), Text(teachers[index][3])],
                      ),
                      GestureDetector(
                        onLongPress: () async {
                          await Clipboard.setData(
                            ClipboardData(text: teachers[index][4]),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Copied to clipboard")),
                          );
                        },
                        onTap: () {
                          launchUrl(Uri.parse("tel:${teachers[index][4]}"));
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.phone),
                            Text(teachers[index][4]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: getTeacherDetails,
        child: _isLoading
            ? CircularProgressIndicator()
            : Icon(Icons.replay_rounded),
      ),
    );
  }
}
