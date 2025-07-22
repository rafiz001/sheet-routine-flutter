import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sheet_routine/data/hive.dart';
import 'package:sheet_routine/widgets/refresh_dialog.dart';

const routineConfig = {
  "routine_name": "Summer - 2025",
  "sheet_ID": "1ZenZW0eYq4Na2sgDYQDjn9eRIX8r6S-cxPEtM97yAj4",
  "timeColumn": 3,
  "timeRow": 1,
  "sectionColumn": 2,
  "semesterColumn": 1,
  "sheetNames": [
    "Saturday",
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
  ],
  "teacher_sheet": "Information",
  "teacher_row": 15,
  "teacher_short_code": 1,
  "teacher_name": 2,
  "teacher_contact": 6,
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
