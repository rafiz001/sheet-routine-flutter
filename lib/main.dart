import 'package:flutter/material.dart';
import 'package:sheet_routine/widgets/refresh_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        //textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 20.0)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.greenAccent,
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
      home: const MyHomePage(title: 'Sheet Routine'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {


    /* alert dialog*/

    showDialog(
      context: context,
      builder: (context) => RefreshDialog()
    );
      /*
      
   */

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
              ListTile(title: Text("Setting")),
            ],
          ),
        ),
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
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
          onPressed: _incrementCounter,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
