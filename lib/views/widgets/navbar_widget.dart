import 'package:flutter/material.dart';
import 'package:sheet_routine/data/notifiers.dart';

class NavbarWidget extends StatelessWidget {
  NavbarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        return Container(
          child: NavigationBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,

            destinations: [
              NavigationDestination(icon: Icon(Icons.home), label: "Home"),
              NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
            ],
            onDestinationSelected: (int value) {
              selectedPageNotifier.value = value;
            },
            selectedIndex: selectedPage,
          ),
        );
      },
    );
  }
}
