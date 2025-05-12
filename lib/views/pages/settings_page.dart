import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController controller1 = TextEditingController();
  bool? isChecked = false;
  bool switch1 = false;
  double slider1 = 70;
  String? menuItem = "d2";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              DropdownButton(
                value: menuItem,
                items: [
                  DropdownMenuItem(value: "d1", child: Text("data 1")),
                  DropdownMenuItem(value: "d2", child: Text("data 2")),
                  DropdownMenuItem(value: "d3", child: Text("data 3")),
                ],
                onChanged: (String? value) {
                  setState(() {
                    menuItem = value;
                  });
                },
              ),
              TextField(
                decoration: InputDecoration(border: OutlineInputBorder()),
                controller: controller1,
                onChanged: (data) {
                  setState(() {});
                },
              ),
              Text(controller1.text),

              CheckboxListTile(
                title: Text("Save"),
                tristate: true,
                value: isChecked,
                onChanged: (value) {
                  setState(() {
                    isChecked = value;
                  });
                },
              ),
              SwitchListTile.adaptive(
                title: Text("Light-Fan"),
                value: switch1,
                onChanged: (value) {
                  setState(() {
                    switch1 = value;
                  });
                },
              ),
              Slider(
                divisions: 100,
                max: 100,
                value: slider1,
                onChanged: (value) {
                  setState(() {
                    slider1 = value;
                  });
                },
              ),
              Text("$slider1"),
              Image.asset("assets/images/im.jpg"),
              InkWell(onTap: () {}, child: Container(height: 500)),
              Image.asset("assets/images/im.jpg"),
              ElevatedButton(onPressed: () {}, child: Text("This is button")),
              OutlinedButton(onPressed: () {}, child: Text("rafiz")),
            ],
          ),
        ),
      ),
    );
  }
}
