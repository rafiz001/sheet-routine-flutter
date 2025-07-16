import 'dart:convert';

import 'package:flutter/material.dart';

class GoogleSheetConfig extends StatefulWidget {
  GoogleSheetConfig({Key? key}) : super(key: key);

  @override
  _GoogleSheetConfigState createState() => _GoogleSheetConfigState();
}

class _GoogleSheetConfigState extends State<GoogleSheetConfig> {
  final TextEditingController _config = TextEditingController(
    text: '''{
"routine_name": "Spring - 2025",
"sheet_ID": "1vJQVPX0-YypjwBAoiFcMNofKR91X8Zt57NAKlXrUre4",
"timeColumn": 3,
"timeRow": 1,
"sectionColumn": 2,
"semesterColumn": 1,
"sheetNames": ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday"],
"teacher_sheet": "Information",
"teacher_row": 15,
"teacher_short_code": 1,
"teacher_name": 2,
"teacher_contact": 6
}''',
  );
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
                    try{
                    var a = jsonDecode(_config.text);
                    print(a);
                    }
                    catch(e){
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
