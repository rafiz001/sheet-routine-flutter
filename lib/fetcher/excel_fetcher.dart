import 'package:dio/dio.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:sheet_routine/data/hive.dart';
import 'package:sheet_routine/pages/google_sheet_config.dart';

class cn {
  static Excel _decodeInIsolate(dynamic bytes) {
    return Excel.decodeBytes(bytes);
  }
}

dynamic checkAndGet(dynamic configFromDB, String key, dynamic defaultValue) {
  return (configFromDB is Map && configFromDB.containsKey(key))
      ? configFromDB[key]
      : defaultValue;
}

Map<String, int> parseCellId(String cellId) {
  // Parse cell ID like "A1" to get column and row indices
  RegExp regExp = RegExp(r'^([A-Z]+)(\d+)$');
  Match? match = regExp.firstMatch(cellId);

  if (match != null) {
    String columnStr = match.group(1)!;
    int row = int.parse(match.group(2)!) - 1;

    // Convert column letters to index
    int col = 0;
    for (int i = 0; i < columnStr.length; i++) {
      col = col * 26 + (columnStr.codeUnitAt(i) - 65 + 1);
    }
    col -= 1; // Convert to 0-based index

    return {'col': col, 'row': row};
  }

  return {'col': 0, 'row': 0};
}

Future<List<int>?> downloadFile(dynamic configFromDB) async {
  String urlID = checkAndGet(
    configFromDB,
    "sheet_ID",
    "1ZenZW0eYq4Na2sgDYQDjn9eRIX8r6S-cxPEtM97yAj4",
  ); //1vJQVPX0-YypjwBAoiFcMNofKR91X8Zt57NAKlXrUre4
  String url =
      "https://docs.google.com/spreadsheets/u/0/d/$urlID/export?format=xlsx";
  final dio = Dio();
  try {
    // Download the file
    final response = await dio.get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    if (response.statusCode == 200) {
      return response.data;
    }
  } catch (_) {
    return null;
  }
}

Future<List<int>?> loadLocal() async {
  try {
    ByteData data = await rootBundle.load(
      'assets/Class Routine (Spring-25).xlsx',
    );
    var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    return bytes;
  } catch (_) {
    return null;
  }
}

Future<Excel?> decodeFile(List<int> response) async {
  Excel? excel;

  excel = Excel.decodeBytes(response);

  return excel;
}

Future<Map<String, dynamic>> readTimeRow(
  Excel excel,
  int timeColumn,
  int timeRow,
) async {
  List<String> timeData = [];
  // Get the time
  var config = await getValueFromHive("settings", "config", null);
  List<dynamic> temp = checkAndGet(
    config,
    "sheetNames",
    routineConfig["sheetNames"] as List<String>,
  );
  List<String> sheetNames = List<String>.from(temp);

  int i = 0;
  while (true) {
    var temp = excel
        .tables[sheetNames[0]]!
        .rows[timeRow][timeColumn + i++]!
        .value;
    if (temp == null) {
      break;
    } else {
      timeData.add(temp.toString());
    }
  }
  int lastCollumn = timeColumn + i - 1;
  await setValueToHive("routine", "timeData", timeData);
  return {"timeRow": timeData, "lastCollumn": lastCollumn};
}

Future<List<String>> getSheetNames(Excel excel) async {
  return excel.tables.keys.toList();
}

Future<void> readExcelFile(
  Excel excel,
  int lastCollumn,
  dynamic configFromDB,
) async {
  int timeRow = checkAndGet(configFromDB, "timeRow", 1);

  int timeColumn = checkAndGet(configFromDB, "timeColumn", 3);

  int sectionColumn = checkAndGet(configFromDB, "sectionColumn", 2);

  int semesterColumn = checkAndGet(configFromDB, "semesterColumn", 1);

  List<dynamic> temp = checkAndGet(
    configFromDB,
    "sheetNames",
    routineConfig["sheetNames"] as List<String>,
  );
  List<String> sheetNames = List<String>.from(temp);

  Map<String, Map<String, Map<String, List<dynamic>>>> days =
      {}; //sunday,1st,A,[CSE 121,2]

  // Get sheet names
  for (int k = 0; k < sheetNames.length; k++) {
    var sheetName = sheetNames[k];
    if (kDebugMode) {
      print(sheetName);
    }
    Map<int, Map<int, int>> mergedHorizontal = {}; //row, col, length
    // Get merged cells information - spannedItems contains cell references like "A1:C3"
    List<String> mergedCells = excel.tables[sheetName]!.spannedItems;
    for (var mergedCell in mergedCells) {
      var splitted = mergedCell.split(":");
      var start = parseCellId(splitted[0]);
      var end = parseCellId(splitted[1]);

      if (start["row"] == end["row"]) {
        if (!mergedHorizontal.containsKey(start["row"])) {
          mergedHorizontal[start["row"] ?? 0] = {};
        }
        mergedHorizontal[start["row"]]![start["col"] ?? 0] =
            ((end["col"] ?? 0) - (start["col"] ?? 0)).abs() + 1;
      }
    }

    //print(mergedHorizontal);
    Map<String, Map<String, List<dynamic>>> sems = {};
    String lastSemester = "";
    // Access row
    for (int i = timeRow + 1; i < 100; i++) {
      var row = excel.tables[sheetName]!.rows[i];
      bool newSemesterSarting = true;
      List<dynamic> sub = [];
      Map<String, List<dynamic>> sec = {};
      if (row[sectionColumn]?.value == null &&
          excel.tables[sheetName]!.rows[i + 1][sectionColumn]?.value == null)
        break;
      // Access cell
      for (int j = 0; j < lastCollumn; j++) {
        var cell = row[j];
        if (j == semesterColumn && cell?.value.toString() == null) {
          newSemesterSarting = false;
        }
        if (j >= timeColumn) {
          List<dynamic> temp = [cell?.value.toString()];
          temp.add(
            (mergedHorizontal.containsKey(i) &&
                    (mergedHorizontal[i]!.containsKey(j)))
                ? mergedHorizontal[i]![j]
                : 1,
          );
          sub.add(temp);
        }
      }
      sec[row[sectionColumn]!.value.toString()] = sub;
      if (newSemesterSarting) {
        lastSemester = row[semesterColumn]!.value.toString();
        sems[lastSemester] = sec;
      } else {
        sems[lastSemester] = {...?sems[lastSemester], ...sec};
      }
    }
    days[sheetName] = sems;
  }
  await setValueToHive("routine", "days", days);
  await setValueToHive("routine", "syncAt", DateTime.now());

  if (kDebugMode) {
    print(days);
  }
}

Future<Map<String, List<String>>> getTeacherDetails(
  Excel excel,
  dynamic configFromDB,
) async {
  String teacher_sheet = checkAndGet(
    configFromDB,
    "teacher_sheet",
    "Information",
  );
  int teacher_row = checkAndGet(configFromDB, "teacher_row", 15);
  int teacher_short_code = checkAndGet(configFromDB, "teacher_short_code", 1);
  int teacher_name = checkAndGet(configFromDB, "teacher_name", 2);
  int teacher_contact = checkAndGet(configFromDB, "teacher_contact", 6);
  Map<String, List<String>> output = {};
  int i = teacher_row;
  while (true) {
    var row = excel.tables[teacher_sheet]!.rows[i];
    if (row[teacher_short_code]?.value == null) break;
    List<String> temp = [];
    temp.add(row[teacher_name]?.value.toString() ?? "");
    temp.add(row[teacher_contact]?.value.toString() ?? "");
    output[row[teacher_short_code]?.value.toString() ?? ""] = temp;

    i++;
  }
  await setValueToHive("routine", "teacher", output);
  return output;
}
