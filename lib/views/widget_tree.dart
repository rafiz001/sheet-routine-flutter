import 'package:flutter/material.dart';
import 'package:sheet_routine/data/notifiers.dart';
import 'package:sheet_routine/views/pages/home_page.dart';
import 'package:sheet_routine/views/pages/profile_page.dart';

import 'widgets/navbar_widget.dart';

List<Widget> pages = [
  HomePage(),
  ProfilePage(),
];

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key}) ;
 
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(valueListenable: isDarkNotifier, builder: (context, isDark, child) {
      return  Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: SelectableText("Md. Rafiz Uddin"),
        centerTitle: true,
        actions: [IconButton(onPressed: () {
          isDarkNotifier.value=!isDark;
        }, icon: Icon(isDark?Icons.light_mode:Icons.dark_mode))],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(child: Text("RAfiz")),
            ListTile(title: Text("Hi this is a tile 0")),
            ListTile(title: Text("Hi this is a tile 1")),
            ListTile(title: Text("Hi this is a tile 2")),
          ],
        ),
      ),
      body: ValueListenableBuilder(valueListenable: selectedPageNotifier, builder: (context, selectedPage, child) {
        return pages.elementAt(selectedPage);
      },),
      floatingActionButton: FloatingActionButton(
        onPressed: null, //_incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.calculate),
      ), // This trailing comma makes auto-formatting nicer for build methods.
      bottomNavigationBar: NavbarWidget(),
    );
    },);
  }
}
