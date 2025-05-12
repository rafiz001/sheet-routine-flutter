import 'package:flutter/material.dart';
import 'package:sheet_routine/data/notifiers.dart';
import 'package:sheet_routine/views/widget_tree.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isDarkNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'Rafiz',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          debugShowCheckedModeBanner: false,
          home: const MyHomePage(title: 'MD. RAFIZ UDDIN'),
        );
      },
    );
  }
}

class MyHomePage extends  StatelessWidget{
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return WidgetTree();
  }
}
