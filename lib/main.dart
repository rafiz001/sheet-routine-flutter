import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sheet_routine/data/hive.dart';
import 'package:sheet_routine/data/courses.dart';
import 'package:sheet_routine/pages/google_sheet_config.dart';
import 'package:sheet_routine/pages/settings.dart';
import 'package:sheet_routine/widgets/refresh_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

const appVersion = "v2.0.0";

extension IndexedIterable<E> on Iterable<E> {
  /// Maps each element and its index to a new value
  Iterable<T> mapIndexed<T>(T Function(int index, E element) f) {
    var index = 0;
    return map((element) => f(index++, element));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('routine');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_MyAppState>()?.restartApp();
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

bool _loading = true;
String? _seedColor;
String _title = routineConfig["routine_name"].toString();
DateTime? _syncAt;
String? _sheetId = routineConfig["sheet_ID"].toString();
Map<String, String?> _selectedSemSec = {
  "sem0": null,
  "sec0": null,
  "sem1": null,
  "sec1": null,
  "sem2": null,
  "sec2": null,
};
List<bool> _enabled = [false, false, false];
List<String> _sheetList = routineConfig["sheetNames"] as List<String>;
Map<String, dynamic> _days = {};
List<String> _timeData = [];
Map<String, dynamic> _teacher = {};

class _MyAppState extends State<MyApp> {
  Future<void> _restartSequence() async {
    // Close Hive boxes
    await Hive.close();

    // Reinitialize Hive
    await Hive.initFlutter();
    await Hive.openBox('settings');
    await Hive.openBox('routine');
    // Reload data
    await _loadDefaultValue();
  }

  Key key = UniqueKey();
  void restartApp() {
    _restartSequence().then((value) {
      setState(() {
        key = UniqueKey();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDefaultValue();
  }

  Future<void> _loadDefaultValue() async {
    final seedC = await getValueFromHive("settings", "theme", "Green");
    final config = await getValueFromHive("settings", "config", null);
    final enabled = await getValueFromHive("settings", "enabled", null);
    final syncAt = await getValueFromHive("routine", "syncAt", null);
    final savedSelectedSemSec = await getValueFromHive(
      "settings",
      "selectedSemSec",
      null,
    );
    final days = await getValueFromHive("routine", "days", null);
    final timeData = await getValueFromHive("routine", "timeData", null);
    final tchr = await getValueFromHive("routine", "teacher", null);
    setState(() {
      _seedColor = seedC;
      if (config != null) {
        _title = config["routine_name"];
        _sheetId = config["sheet_ID"];
        _sheetList = List<String>.from(config["sheetNames"]);
      }
      if (syncAt != null) {
        _syncAt = syncAt;
      }
      if (savedSelectedSemSec != null) {
        _selectedSemSec = Map<String, String?>.from(savedSelectedSemSec);
      }
      if (enabled != null) {
        _enabled = enabled;
      }
      if (days != null) {
        _days = Map<String, dynamic>.from(days);
      }
      if (timeData != null) {
        _timeData = List<String>.from(timeData);
      }
      if (tchr != null) {
        _teacher = Map<String, dynamic>.from(tchr);
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return CircularProgressIndicator();
    return MaterialApp(
      title: 'Sheet Routine',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: getTheme(_seedColor ?? "Green"),
          brightness: Brightness.light,
        ),
        //textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 20.0)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: getTheme(_seedColor ?? "Green"),
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          //bodyMedium: TextStyle(fontSize: 20.0),
          //labelLarge: TextStyle(fontSize: 20),
          //labelMedium: TextStyle(fontSize: 20),
          //labelSmall: TextStyle(fontSize: 20),
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: MyHomePage(title: _title, syncAt: _syncAt, sheetID: _sheetId),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, this.syncAt, this.sheetID});

  final String? title;
  final String? sheetID;
  final DateTime? syncAt;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _refresher() {
    showDialog(context: context, builder: (context) => RefreshDialog());

    setState(() {
      _counter++;
    });
  }

  int getTabCout() {
    int i = 0;
    if (_selectedSemSec["sec0"] != null &&
        _selectedSemSec["sec0"] != "null" &&
        _enabled[0]) {
      i++;
    }
    if (_selectedSemSec["sec1"] != null &&
        _selectedSemSec["sec1"] != "null" &&
        _enabled[1]) {
      i++;
    }
    if (_selectedSemSec["sec2"] != null &&
        _selectedSemSec["sec2"] != "null" &&
        _enabled[2]) {
      i++;
    }
    return i;
  }

  List<Widget> getTabList() {
    List<Widget> list = [];
    if (_selectedSemSec["sec0"] != null &&
        _selectedSemSec["sec0"] != "null" &&
        _enabled[0]) {
      list.add(Text("${_selectedSemSec["sem0"]}(${_selectedSemSec["sec0"]})"));
    }
    if (_selectedSemSec["sec1"] != null &&
        _selectedSemSec["sec1"] != "null" &&
        _enabled[1]) {
      list.add(Text("${_selectedSemSec["sem1"]}(${_selectedSemSec["sec1"]})"));
    }
    if (_selectedSemSec["sec2"] != null &&
        _selectedSemSec["sec2"] != "null" &&
        _enabled[2]) {
      list.add(Text("${_selectedSemSec["sem2"]}(${_selectedSemSec["sec2"]})"));
    }
    return list;
  }

  Widget aTab(String sem, sec) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...(_sheetList
              .map(
                (value) => Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  margin: EdgeInsets.all(10),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: Theme.of(context).colorScheme.inversePrimary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    children: [
                      Text(value),
                      ...((List<dynamic>.of(_days[value]![sem]![sec]!))
                          .asMap()
                          .entries
                          .where((element) {
                            return (element.value[0] != "null" &&
                                element.value[0] != null);
                          })
                          .map(
                            (entry) => Column(
                              children: [
                                Divider(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.inverseSurface,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    entry.value[1] == 1
                                        ? Text(_timeData[entry.key])
                                        : Column(
                                            children: [
                                              Text(_timeData[entry.key]),
                                              Text(_timeData[entry.key + 1]),
                                            ],
                                          ),
                                    InkWell(
                                      onTap: () {
                                        final raw = entry.value[0] as String;
                                        final courseCode = raw
                                            .split("[")[0]
                                            .trim()
                                            .replaceAll(RegExp(r'-'), " ");
                                        final courseTitle =
                                            courses[courseCode] ?? courseCode;
                                        final teacherCode = RegExp(r'\[(.*?)\]')
                                            .allMatches(raw)
                                            .map((match) => match.group(1)!)
                                            .toList();

                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text(courseTitle),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Raw: ${entry.value[0]}",
                                                  ),
                                                  Divider(),
                                                  Text("Teachers:"),
                                                  ...(teacherCode
                                                      .map(
                                                        (elem) => Text(
                                                          _teacher[elem] != null
                                                              ? _teacher[elem][0]
                                                              : elem,
                                                        ),
                                                      )
                                                      .toList()),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      child: Text(entry.value[0] ?? " "),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                          .toList()),
                    ],
                  ),
                ),
              )
              .toList()),
          Padding(padding: EdgeInsetsGeometry.only(bottom: 500)),
        ],
      ),
    );
  }

  List<Widget> getTabs() {
    List<Widget> list = [];
    if (_selectedSemSec["sec0"] != null &&
        _selectedSemSec["sec0"] != "null" &&
        _enabled[0]) {
      list.add(aTab(_selectedSemSec["sem0"]!, _selectedSemSec["sec0"]));
    }
    if (_selectedSemSec["sec1"] != null &&
        _selectedSemSec["sec1"] != "null" &&
        _enabled[1]) {
      list.add(aTab(_selectedSemSec["sem1"]!, _selectedSemSec["sec1"]));
    }
    if (_selectedSemSec["sec2"] != null &&
        _selectedSemSec["sec2"] != "null" &&
        _enabled[2]) {
      list.add(aTab(_selectedSemSec["sem2"]!, _selectedSemSec["sec2"]));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
   
    return DefaultTabController(
      length: getTabCout(),
      child: Scaffold(
        drawer: Drawer(
          child: Column(
            children: [
              DrawerHeader(
                child: Flex(
                  direction: Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ClipOval(
                      child: Image.asset(
                        "assets/images/SheetRoutine.png",
                        height: 70,
                        width: 70,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text("Sheet Routine"), Text(appVersion)],
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Text("Settings"),
                leading: Icon(Icons.settings),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return Settings();
                      },
                    ),
                  );
                },
              ),
              ListTile(
                title: Text("Telegram"),
                leading: Icon(Icons.telegram_outlined),
                onTap: () {launchUrl(
                  Uri.parse(
                    "https://t.me/sheet_routine",
                  ),
                );},
              ),
              ListTile(
                title: Text("Source Code"),
                leading: Icon(Icons.code),
                onTap: () {launchUrl(
                  Uri.parse(
                    "https://github.com/rafiz001/sheet-routine-flutter",
                  ),
                );},
              ),/*
              ListTile(
                title: Text("Delete Databases"),
                leading: Icon(Icons.code),
                onTap: () {Hive.deleteFromDisk();},
              ),*/
            ],
          ),
        ),
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title ?? ""),
              Text(
                widget.syncAt != null
                    ? "Sync At: ${widget.syncAt!.hour}:${widget.syncAt!.minute} ${widget.syncAt!.day}/${widget.syncAt!.month}"
                    : "[Sync Please]",
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.public),
              onPressed: () {
                launchUrl(
                  Uri.parse(
                    "https://docs.google.com/spreadsheets/d/${widget.sheetID}",
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            tabs: getTabList(),
            labelPadding: EdgeInsets.only(bottom: 10),
          ),
        ),
        body: TabBarView(children: getTabs()),

        floatingActionButton: FloatingActionButton(
          onPressed: _refresher,
          tooltip: 'Sync',
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}
