import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sheet_routine/data/hive.dart';
import 'package:sheet_routine/data/courses.dart';
import 'package:sheet_routine/pages/google_sheet_config.dart';
import 'package:sheet_routine/pages/roomCheacker.dart';
import 'package:sheet_routine/pages/settings.dart';
import 'package:sheet_routine/pages/teachersRoutine.dart';
import 'package:sheet_routine/pages/teachers_contact.dart';
import 'package:sheet_routine/widgets/refresh_dialog.dart';
import 'package:timeago_flutter/timeago_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

const appVersion = "v2.1.6";

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
  runApp(MyApp());
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
var isSyncLoading = false;
bool _autoTeacher = false;

class _MyAppState extends State<MyApp> {
  Future<void> _restartSequence() async {
    // Close Hive boxes

    //await Hive.close();
    // Reinitialize Hive
    await Hive.initFlutter();
    await Hive.openBox('settings');
    await Hive.openBox('routine');
    // Reload data
    await _loadDefaultValue();
    isSyncLoading = false;
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
    final seedC = await getValueFromHive("settings", "theme", "Teal");
    final config = await getValueFromHive("settings", "config", null);
    final enabled = await getValueFromHive("settings", "enabled", null);
    final syncAt = await getValueFromHive("routine", "syncAt", null);
    final savedSelectedSemSec = await getValueFromHive(
      "settings",
      "selectedSemSec",
      null,
    );
    final days = await getValueFromHive("routine", "days", null);
    final autoTeacherDb = await getValueFromHive(
      "settings",
      "autoTeacher",
      false,
    );
    
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
      if(autoTeacherDb!=null){
        _autoTeacher = autoTeacherDb;
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return CircularProgressIndicator();
    return MaterialApp(
      title: 'Sheet Routine',
      theme: FlexThemeData.light(
        scheme: getTheme(_seedColor ?? "Green"),

        //textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 20.0)),
        useMaterial3: true,
      ),
      darkTheme: FlexThemeData.dark(
        // scheme: FlexScheme.blackWhite,
        scheme: getTheme(_seedColor ?? "Green"),

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
  void _refresher() async {
    // showDialog(context: context, builder: (context) => RefreshDialog());
    setState(() {
      isSyncLoading = true;
    });

    await executer(context).then((value) {
      if (value == true) {
        setState(() {
          isSyncLoading = false;
        });
        if (mounted) {
          MyApp.restartApp(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Something went wrong...")));
        }
      }
    });
  }

  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );
  void _onRefresh() async {
    final bool isConnected =
        await InternetConnectionChecker.instance.hasConnection;
    if (isConnected && mounted) {
      //await showDialog(context: context, builder: (context) => RefreshDialog());
      await executer(context).then((value) {
        if (value == true) {
          _refreshController.refreshCompleted();
          if (mounted) {
            MyApp.restartApp(context);
          }
        } else {
          _refreshController.refreshFailed();
        }
      });
    } else {
      _refreshController.refreshFailed();
    }
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

  List<Widget> dayWidgets(String value, sem, sec) {
    try {
      var classList = List<dynamic>.of(_days[value]![sem]![sec]!);
      classList.sort((a, b) => (a[1] as int).compareTo(b[1]));
      return (classList)
          .asMap()
          .entries
          .where((element) {
            return (element.value[0] != "null" && element.value[0] != null);
          })
          .map((entry) {
            final int startingTimePlussed = entry.value[1];
            return Column(
              children: [
                Divider(color: Theme.of(context).colorScheme.inverseSurface),
                Padding(padding: EdgeInsetsGeometry.only(bottom: 10)),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Column(
                      children: [
                        Text(_timeData[startingTimePlussed - 1]),
                        Text("|"),
                        Text(
                          _timeData.length > startingTimePlussed
                              ? (_timeData[startingTimePlussed])
                              : "End",
                        ),
                      ],
                    ),

                    InkWell(
                      onTap: () {
                        final raw = entry.value[0] as String;
                        var cellPortions = raw.split("\n");
                        var temp1 = cellPortions[1].split("(");

                        final courseCode = temp1[0].trim();
                        final teachers = cellPortions[0].trim().split(",");
                        final courseTitle = courses[courseCode] ?? courseCode;
                        /*final teacherCode = RegExp(r'\[(.*?)\]')
                            .allMatches(raw)
                            .map((match) => match.group(1)!)
                            .toList();
                        final labs = RegExp(r'\((.*?)\)')
                            .allMatches(raw)
                            .map((match) => match.group(1)!.trim())
                            .toList();
                        String? lab;
                        labs.forEach((element) {
                          if (labInfo.containsKey(element)) {
                            lab = "$element: ${labInfo[element]}";
                          }
                        });*/

                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(courseTitle),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.value[0]),
                                  Divider(),
                                  /*Text("Teachers:"),
                                  ...(teacherCode
                                      .map(
                                        (elem) => SelectableText(
                                          _teacher[elem] != null
                                              ? "${_teacher[elem][0]} ${_teacher[elem][1] == "null" ? "" : "(${_teacher[elem][1]})"}"
                                              : elem,
                                        ),
                                      )
                                      .toList()),
                                  (lab != null)
                                      ? Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Divider(),
                                            Text("Lab → ${lab!}"),
                                          ],
                                        )
                                      : Padding(
                                          padding: EdgeInsetsGeometry.zero,
                                        ),*/
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (context) => Container(
                                        height:
                                            MediaQuery.of(context).size.height *
                                            0.3, // 30% of screen height
                                        decoration: BoxDecoration(
                                          //color: Colors.white,
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(16),
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            ListTile(
                                              title: Text(
                                                "Assignment",
                                                textAlign: TextAlign.center,
                                              ),
                                              onTap: () {
                                                launchUrl(
                                                  Uri.parse(
                                                    "https://rafiz001.github.io/cover/#/assignment?ccode=${courseCode}&ctitle=${courseTitle}&tname1=${teachers[0]}${teachers.length > 1 ? "&tname2=${teachers[1]}" : ""}",
                                                  ),
                                                );
                                              },
                                            ),
                                            ListTile(
                                              title: Text(
                                                "Lab Report",
                                                textAlign: TextAlign.center,
                                              ),
                                              onTap: () {
                                                launchUrl(
                                                  Uri.parse(
                                                    "https://rafiz001.github.io/cover/#/labreport?ccode=${courseCode}&ctitle=${courseTitle}&tname1=${teachers[0]}${teachers.length > 1 ? "&tname2=${teachers[1]}" : ""}",
                                                  ),
                                                );
                                              },
                                            ),
                                            ListTile(
                                              title: Text(
                                                "Index Page",
                                                textAlign: TextAlign.center,
                                              ),
                                              onTap: () {
                                                launchUrl(
                                                  Uri.parse(
                                                    "https://rafiz001.github.io/cover/#/indexPage?ccode=${courseCode}&ctitle=${courseTitle}",
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text("Cover Page"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text(
                        subPreProcessor(entry.value[0]),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                Padding(padding: EdgeInsetsGeometry.only(bottom: 10)),
              ],
            );
          })
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return [
        Padding(padding: EdgeInsetsGeometry.only(bottom: 5)),
        Text("There is error!"),
        Padding(padding: EdgeInsetsGeometry.only(bottom: 5)),
      ];
    }
  }

  Widget aTab(String sem, sec) {
    final DateTime now = DateTime.now();
    final List<String> days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    String dayName = days[now.weekday % 7];

    return SmartRefresher(
      enablePullUp: false,
      enablePullDown: true,
      controller: _refreshController,
      onRefresh: _onRefresh,
      header: WaterDropHeader(),
      child: ListView(
        children: [
          ...(days
              .map(
                (value) => _days.containsKey(value)
                    ? Container(
                        alignment: Alignment.center,
                        width: double.infinity,
                        margin: EdgeInsets.all(10),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                dayName == value
                                    ? Icon(Icons.check)
                                    : Padding(
                                        padding: EdgeInsetsGeometry.only(
                                          right: 0,
                                        ),
                                      ),
                                Padding(
                                  padding: EdgeInsetsGeometry.only(right: 10),
                                ),
                                Text(value, style: TextStyle(fontSize: 20)),
                              ],
                            ),

                            ...(dayWidgets(value, sem, sec)),
                          ],
                        ),
                      )
                    : Padding(padding: EdgeInsetsGeometry.all(1)),
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
    final isBlank =
        ((_selectedSemSec["sec0"] == null ||
            _selectedSemSec["sec0"] == "null") &&
        (_selectedSemSec["sec1"] == null ||
            _selectedSemSec["sec1"] == "null") &&
        (_selectedSemSec["sec2"] == null ||
            _selectedSemSec["sec2"] == "null") &&
        !_enabled[0] &&
        !_enabled[1] &&
        !_enabled[2]);
    if (_days != null && _autoTeacher == true && mounted && !Navigator.canPop(context)) {
    Future.delayed(Duration(milliseconds: 2), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TeachersRoutine()),
      );
    });
    }
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
                onTap: () {
                  launchUrl(Uri.parse("https://t.me/sheet_routine"));
                },
              ),
              ListTile(
                title: Text("Source Code"),
                leading: Icon(Icons.code),
                onTap: () {
                  launchUrl(
                    Uri.parse(
                      "https://github.com/rafiz001/sheet-routine-flutter",
                    ),
                  );
                },
              ) /*
              ListTile(
                title: Text("Delete Databases"),
                leading: Icon(Icons.code),
                onTap: () {Hive.deleteFromDisk();},
              ),*/,
            ],
          ),
        ),
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title ?? ""),
              widget.syncAt != null
                  ? Timeago(
                      builder: (context, value) => Text(
                        "Synced: $value",
                        style: TextStyle(fontSize: 12),
                      ),
                      date: widget.syncAt!,
                    )
                  : Text("[Sync Please]", style: TextStyle(fontSize: 12)),
              // Text(
              //   widget.syncAt != null
              //       ? "Sync At: ${widget.syncAt!.hour}:${widget.syncAt!.minute} ${widget.syncAt!.day}/${widget.syncAt!.month}"
              //       : "[Sync Please]",
              //   style: TextStyle(fontSize: 12),
              // ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Roomcheacker()),
                );
              },
              tooltip: "Room Filter",
              icon: Icon(Icons.meeting_room_outlined),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TeachersRoutine()),
                );
              },
              tooltip: "Teachers Routine",
              icon: Icon(Icons.cases_outlined),
            ),

            PopupMenuButton(
              onSelected: (value) {
                if (value == "live") {
                  launchUrl(
                    Uri.parse(
                      "https://docs.google.com/spreadsheets/d/${widget.sheetID}",
                    ),
                  );
                }
                if (value == "TeachersInfo") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TeachersContact()),
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: "TeachersInfo",
                  child: Text("Teachers Info"),
                ),
                PopupMenuItem(value: "live", child: Text("Live")),
              ],
            ),
          ],
          bottom: TabBar(
            tabs: getTabList(),
            labelPadding: EdgeInsets.only(bottom: 10),
            dividerColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        ),
        body: isBlank
            ? Center(
                child: Text(
                  "1. Sync first\n2. Set semester, section and save\n3. Back to home",
                ),
              )
            : TabBarView(children: getTabs()),

        floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          onPressed: isBlank ? _refresher : _refreshController.requestRefresh,
          tooltip: 'Sync',
          child: isSyncLoading
              ? CircularProgressIndicator()
              : Icon(Icons.refresh),
        ),
      ),
    );
  }
}
