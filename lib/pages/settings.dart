import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sheet_routine/main.dart';
import 'package:sheet_routine/pages/google_sheet_config.dart';

Map<String, Color> themes = {
  "Green": Colors.green,
  "Blue": Colors.blue,
  "Teal": Colors.teal,
  "Cayan": Colors.cyan,
  "Red": Colors.red,
  "Orange": Colors.orange,
  "Deep Orange": Colors.deepOrange,
  "Pink": Colors.pink,
};
Color getTheme(String name) {
  return themes[name] ?? Colors.green;
}

class Settings extends StatefulWidget {
  Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

final settingsBox = Hive.box(name: 'settings');
String selectedTheme = settingsBox.get("theme", defaultValue: "Green");

class _SettingsState extends State<Settings> {
  List<DropdownMenuItem> generateThemeList() {
    List<DropdownMenuItem> temp = [];
    themes.forEach((k, v) {
      temp.add(DropdownMenuItem(value: k, child: Text(k)));
    });
    return temp;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Settings"),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Column(
          children: [
            ListTile(
              leading: Icon(Icons.table_chart_rounded),
              title: Text("Google Sheet Config"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GoogleSheetConfig()),
                );
              },
            ),
            Divider(indent: 15, endIndent: 15),
            ListTile(
              leading: Text("1"),
              title: Text("Primary Routine"),
              // trailing: Switch(value: true, onChanged: (value) {}),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton(
                  value: null,
                  items: [
                    DropdownMenuItem(value: null, child: Text("Semester")),
                    DropdownMenuItem(value: "4th", child: Text("4th")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      // selectedTheme = value??selectedTheme;
                    });
                  },
                  icon: Icon(Icons.arrow_downward),
                  underline: Container(),
                  padding: EdgeInsets.all(8),
                ),
                DropdownButton(
                  value: null,
                  items: [
                    DropdownMenuItem(value: null, child: Text("Section")),
                    DropdownMenuItem(value: "A", child: Text("A")),
                    DropdownMenuItem(value: "B", child: Text("B")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      // selectedTheme = value??selectedTheme;
                    });
                  },
                  icon: Icon(Icons.arrow_downward),
                  underline: Container(),
                  padding: EdgeInsets.all(8),
                ),
              ],
            ),
            ListTile(
              leading: Text("2"),
              title: Text("Secondary Routine"),
              trailing: Switch(value: false, onChanged: (value) {}),
            ),
            ListTile(
              leading: Text("3"),
              title: Text("Tertiary Routine"),
              trailing: Switch(value: false, onChanged: (value) {}),
            ),
            Divider(indent: 15, endIndent: 15),
            ListTile(
              title: Text("Theme"),
              leading: Icon(Icons.color_lens_outlined),
              trailing: DropdownButton(
                value: selectedTheme,
                items: generateThemeList(),
                onChanged: (value) {
                  setState(() {
                    selectedTheme = value;
                  });
                },
                icon: Icon(Icons.arrow_downward, color: themes[selectedTheme]),
                underline: Container(),
                padding: EdgeInsets.all(8),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dark_mode_outlined),
              title: Text("Dark/Light"),
              trailing: Text("As System"),
            ),
            Divider(indent: 15, endIndent: 15),
            Padding(padding: EdgeInsetsGeometry.only(bottom: 10)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    settingsBox.put("theme", selectedTheme);
                    MyApp.restartApp(context);
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
