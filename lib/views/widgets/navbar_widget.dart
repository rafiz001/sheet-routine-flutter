import 'package:flutter/material.dart';

class NavbarWidget extends StatefulWidget {
  NavbarWidget({Key? key}) : super(key: key);

  @override
  _NavbarWidgetState createState() => _NavbarWidgetState();
}

class _NavbarWidgetState extends State<NavbarWidget> {
  int navBarIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Container(
       child: NavigationBar(
        backgroundColor:  Theme.of(context).colorScheme.inversePrimary,

        destinations: [
          NavigationDestination(icon: Icon(Icons.home), label: "Home"),
          NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
        ],
        onDestinationSelected: (int value) {
          setState(() {
            navBarIndex = value;
          });
        },
        selectedIndex: navBarIndex,
      ),
    );
  }
}