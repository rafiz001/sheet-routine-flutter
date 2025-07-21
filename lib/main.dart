import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sheet_routine/data/hive.dart';
import 'package:sheet_routine/pages/google_sheet_config.dart';
import 'package:sheet_routine/pages/settings.dart';
import 'package:sheet_routine/widgets/refresh_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final syncAt = await getValueFromHive("routine", "syncAt", null);
    setState(() {
      _seedColor = seedC;
      if (config != null) {
        _title = config["routine_name"];
        _sheetId = config["sheet_ID"];
      }
      if (syncAt != null) {
        _syncAt = syncAt;
      }
      _loading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    if (_loading) return CircularProgressIndicator();
    return MaterialApp(
      title: 'Flutter Demo',
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
      home:  MyHomePage(title: _title, syncAt: _syncAt, sheetID: _sheetId),
    
      
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: Drawer(
          child: Column(
            children: [
              DrawerHeader(child: Text("Welcome")),
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
                launchUrl(Uri.parse("https://github.com"));
              },
            ),
          ],
          bottom: TabBar(
            tabs: [Text("8(A)"), Text("8(B)"), Text("1(A)")],
            labelPadding: EdgeInsets.only(bottom: 10),
          ),
        ),
        body: TabBarView(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('You have pushed the button this many times:'),
                  Text(
                    '$_counter',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            Center(child: Text("this is second tab")),
            Center(child: Text("this is third tab")),
          ],
        ),

        floatingActionButton: FloatingActionButton(
          onPressed: _refresher,
          tooltip: 'Sync',
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}
