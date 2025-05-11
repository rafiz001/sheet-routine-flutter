import 'package:flutter/material.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key});
   final int _counter = 0;
  /*
  void _incrementCounter() {
    setState(() {
      _counter++;

    });
   
  }

  */
  @override
  Widget build(BuildContext context) {
    return  Stack(
        children: [
          Center(
            child: Image.asset(
              "assets/images/im.jpg",
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(
            height: double.infinity,
            width: double.infinity,

            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 5,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 5,
                  children: [
                    Container(
                      height: 100,
                      width: 100,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Theme.of(context).colorScheme.surfaceBright,
                      ),
                      child: SelectableText(
                        "$_counter",
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      height: 100,
                      width: 100,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Theme.of(context).colorScheme.surfaceBright,
                      ),
                      child: SelectableText(
                        "$_counter",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 5,
                  children: [
                    Container(
                      height: 100,
                      width: 100,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Theme.of(context).colorScheme.surfaceBright,
                      ),
                      child: SelectableText(
                        "$_counter",
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      height: 100,
                      width: 100,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Theme.of(context).colorScheme.surfaceBright,
                      ),
                      child: SelectableText(
                        "$_counter",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
   
  }
}