import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sheet_routine/data/hive.dart';
import 'package:sheet_routine/main.dart';
import 'package:sheet_routine/widgets/refresh_dialog.dart';

const routineConfig = {
  "routine_name": "Spring 2026",
  "sheet_ID": "1Sdmr60rcZeBCa2ofswUr9mxIreIj71W9HYM1RRhvfMM",
  "timeColumn": 1,
  "timeRow": 0,
  "dayColumn": 0,
  "sheetNames": ["1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th"],
  "teacher_sheet": "Info.",
  "teacher_row": 2,
  "teacher_short_code": 1,
  "teacher_name": 2,
  "teacher_contact": 6,
};
const labInfo = {
  "CNL": "LAB-104",
  "SEL": "LAB-129",
  "BCL": "LAB-128",
  "DMSL": "LAB-103",
  "DSAL": "LAB-106",
  "SDL": "Lab-105/A",
  "MIL": "LAB-131",
  "EEL": "LAB-127",
  "DSCAL": "LAB-130",
};

class GoogleSheetConfig extends StatefulWidget {
  GoogleSheetConfig({Key? key}) : super(key: key);

  @override
  _GoogleSheetConfigState createState() => _GoogleSheetConfigState();
}

class _GoogleSheetConfigState extends State<GoogleSheetConfig> {
  @override
  void initState() {
    super.initState();
    _loadDefaultValue();
  }

  final TextEditingController _config = TextEditingController(
    text: jsonEncode(routineConfig),
  );
  Future<void> _loadDefaultValue() async {
    final savedValue = await getValueFromHive("settings", "config", null);
    if (savedValue != null) {
      setState(() {
        _config.text = jsonEncode(savedValue);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Google Sheet Config"),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: Text("Are you sure want to delete the database?"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Hive.deleteFromDisk();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Database deleted. Restart the app.")),
                          );
                          
                          Navigator.pop(context);
                        },
                        child: Text("Yes"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text("No"),
                      ),
                    ],
                  );
                },
              );
            },
            icon: Icon(Icons.delete),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              keyboardType: TextInputType.multiline,
              maxLines: null,
              controller: _config,
            ),
            Padding(padding: EdgeInsetsGeometry.only(bottom: 10)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    try {
                      var a = jsonDecode(_config.text);
                      setValueToHive("settings", "config", a);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Data saved! Make a sync now.")),
                      );
                      if (kDebugMode) {
                        debugPrintAllBoxes();
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.save),
                      Padding(padding: EdgeInsetsGeometry.only(right: 7)),
                      Text("Save"),
                    ],
                  ),
                ),
                Padding(padding: EdgeInsetsGeometry.only(right: 7)),
                OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => RefreshDialog(),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      Padding(padding: EdgeInsetsGeometry.only(right: 7)),
                      Text("Sync"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
