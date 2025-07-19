
import 'package:hive_flutter/hive_flutter.dart';


Future<String> getThemeFromHive() async {
   var settingsBox = await Hive.openBox('settings');
  return settingsBox.get("theme", defaultValue: "Green");
}

Future<Null> setTheme(String selectedTheme) async {
   var settingsBox = await Hive.openBox('settings');
   settingsBox.put("theme", selectedTheme);

}