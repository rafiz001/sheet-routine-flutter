
import 'package:hive_flutter/hive_flutter.dart';


Future<dynamic> getValueFromHive(String box, String key, dynamic defaultValue) async {
   var settingsBox = await Hive.openBox(box);
  return settingsBox.get(key, defaultValue: defaultValue);
}

Future<Null> setValueToHive(String box, String key, dynamic value) async {
   var settingsBox = await Hive.openBox(box);
   settingsBox.put(key, value);

}

void debugPrintAllBoxes() async {
final boxName = "settings";

    final box = await Hive.openBox(boxName);
    print('\nBox: $boxName');
    print('Keys: ${box.keys}');
    print('Values: ${box.values}');
  }
