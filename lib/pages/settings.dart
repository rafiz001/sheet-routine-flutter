import 'package:flutter/material.dart';
import 'package:sheet_routine/data/hive.dart';
import 'package:sheet_routine/main.dart';
import 'package:sheet_routine/pages/google_sheet_config.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

Map<String, FlexScheme> themes = {
  "Black": FlexScheme.blackWhite,
  "Green": FlexScheme.greenM3,
  "Blue": FlexScheme.blueM3,
  "Teal": FlexScheme.tealM3,
  "Cayan": FlexScheme.cyanM3,
  "Red": FlexScheme.redM3,
  "Orange": FlexScheme.orangeM3,
  "Deep Orange": FlexScheme.deepOrangeM3,
  "Pink": FlexScheme.pinkM3,
};
FlexScheme getTheme(String name) {
  return themes[name] ?? FlexScheme.greenM3;
}

class Settings extends StatefulWidget {
  Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

String selectedTheme = "Red";
Map<String, String?> selectedSemSec = {
  "sem0": null,
  "sec0": null,
  "sem1": null,
  "sec1": null,
  "sem2": null,
  "sec2": null,
};
bool loading = true;
List<dynamic> semesters = [];
List<List<dynamic>> sections = [[], [], []];
List<bool> enabled = [true, false, false];

class _SettingsState extends State<Settings> {
  @override
  void initState() {
    super.initState();
    _loadDefaultValue();
  }

  void _generateSections(String semester, int routineNumber) {
    getValueFromHive("routine", "days", null).then((value) {
      if (value != null && value is Map && value.containsKey("Monday")) {
        final temp = value["Monday"];
        if (temp is Map && temp.containsKey(semester)) {
          final temp2 = temp[semester];
          if (temp2 is Map) {
            sections[routineNumber] = temp2.keys.toList();
            // print(sections);
          }
        }
      }
    });
  }

  Future<void> _loadDefaultValue() async {
    final savedThemeValue = await getValueFromHive(
      "settings",
      "theme",
      "Teal",
    );
    final tempDays = await getValueFromHive("routine", "days", null);
    final savedSelectedSemSec = await getValueFromHive(
      "settings",
      "selectedSemSec",
      null,
    );
    final savedEnabled = await getValueFromHive("settings", "enabled", null);
    setState(() {
      selectedTheme = savedThemeValue;
      //getting semesters

      if (tempDays != null &&
          tempDays is Map &&
          tempDays.containsKey("Monday")) {
        final temp1 = tempDays["Monday"];
        if (temp1 is Map) {
          semesters = temp1.keys.toList();
        }
      }
      //getting saved semsec & enabled
      if (savedSelectedSemSec != null) {
        selectedSemSec = Map<String, String?>.from(savedSelectedSemSec);
      }
      if (savedEnabled != null) {
        enabled = savedEnabled;
      }
      //getting defauld saved section list
      if (selectedSemSec["sem0"] != null) {
        _generateSections(selectedSemSec["sem0"]!, 0);
      }
      if (selectedSemSec["sem1"] != null) {
        _generateSections(selectedSemSec["sem1"]!, 1);
      }
      if (selectedSemSec["sem2"] != null) {
        _generateSections(selectedSemSec["sem2"]!, 2);
      }

      loading = false;
    });
  }

  List<DropdownMenuItem> generateThemeList() {
    List<DropdownMenuItem> temp = [];
    themes.forEach((k, v) {
      temp.add(DropdownMenuItem(value: k, child: Text(k)));
    });
    return temp;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return CircularProgressIndicator();
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer
      ),
      body: SingleChildScrollView(
        child: Column(
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
                  value: selectedSemSec["sem0"],
                  items: [
                    DropdownMenuItem(value: null, child: Text("Semester")),
                    ...(semesters
                        .where((item) => item != "null" && item != null)
                        .map(
                          (dynamic value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList()),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                    setState(() {
                      selectedSemSec["sem0"] = value.toString();
                      selectedSemSec["sec0"] = null;
                      _generateSections(value.toString(), 0);
                    });}
                  },
                  icon: Icon(Icons.arrow_downward),
                  underline: Container(),
                  padding: EdgeInsets.all(8),
                ),
                DropdownButton(
                  value: selectedSemSec["sec0"],
                  items: [
                    DropdownMenuItem(value: null, child: Text("Section")),
                    ...(sections[0]
                        .where((item) => item != "null" && item != null)
                        .map(
                          (dynamic value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList()),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                    setState(() {
                      selectedSemSec["sec0"] = value.toString();
                    });}
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
              trailing: Switch(
                value: enabled[1],
                onChanged: (value) {
                  setState(() {
                    enabled[1] = value;
                  });
                },
              ),
            ),
            enabled[1]
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DropdownButton(
                        value: selectedSemSec["sem1"],
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text("Semester"),
                          ),
                          ...(semesters
                              .where((item) => item != "null" && item != null)
                              .map(
                                (dynamic value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList()),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                          setState(() {
                            selectedSemSec["sem1"] = value.toString();
                            selectedSemSec["sec1"] = null;
                            _generateSections(value.toString(), 1);
                          });}
                        },
                        icon: Icon(Icons.arrow_downward),
                        underline: Container(),
                        padding: EdgeInsets.all(8),
                      ),
                      DropdownButton(
                        value: selectedSemSec["sec1"],
                        items: [
                          DropdownMenuItem(value: null, child: Text("Section")),
                          ...(sections[1]
                              .where((item) => item != "null" && item != null)
                              .map(
                                (dynamic value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList()),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                          setState(() {
                            selectedSemSec["sec1"] = value.toString();
                          });}
                        },
                        icon: Icon(Icons.arrow_downward),
                        underline: Container(),
                        padding: EdgeInsets.all(8),
                      ),
                    ],
                  )
                : Padding(padding: EdgeInsetsGeometry.all(0)),
            ListTile(
              leading: Text("3"),
              title: Text("Tertiary Routine"),
              trailing: Switch(
                value: enabled[2],
                onChanged: (value) {
                  setState(() {
                    enabled[2] = value;
                  });
                },
              ),
            ),
            enabled[2]
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DropdownButton(
                        value: selectedSemSec["sem2"],
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text("Semester"),
                          ),
                          ...(semesters
                              .where((item) => item != "null" && item != null)
                              .map(
                                (dynamic value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList()),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                          setState(() {
                            selectedSemSec["sem2"] = value.toString();
                            selectedSemSec["sec2"] = null;
                            _generateSections(value.toString(), 2);
                          });}
                        },
                        icon: Icon(Icons.arrow_downward),
                        underline: Container(),
                        padding: EdgeInsets.all(8),
                      ),
                      DropdownButton(
                        value: selectedSemSec["sec2"],
                        items: [
                          DropdownMenuItem(value: null, child: Text("Section")),
                          ...(sections[2]
                              .where((item) => item != "null" && item != null)
                              .map(
                                (dynamic value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList()),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedSemSec["sec2"] = value.toString();
                            });
                          }
                        },
                        icon: Icon(Icons.arrow_downward),
                        underline: Container(),
                        padding: EdgeInsets.all(8),
                      ),
                    ],
                  )
                : Padding(padding: EdgeInsetsGeometry.all(0)),
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
                // icon: Icon(Icons.arrow_downward, color: themes[selectedTheme]),
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
                    setValueToHive("settings", "theme", selectedTheme).then((
                      _,
                    ) {
                      setValueToHive(
                        "settings",
                        "selectedSemSec",
                        selectedSemSec,
                      ).then((_) {
                        setValueToHive("settings", "enabled", enabled).then((
                          _,
                        ) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Data saved!")),
                          );
                          MyApp.restartApp(context);
                        });
                      });
                    });
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
