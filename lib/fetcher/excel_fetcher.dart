import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:sheet_routine/data/hive.dart';
import 'package:sheet_routine/pages/google_sheet_config.dart';

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

Future<dynamic> downloadFile(dynamic configFromDB) async {
  //String urlID = "1Sdmr60rcZeBCa2ofswUr9mxIreIj71W9HYM1RRhvfMM";
  String urlID = checkAndGet(
    configFromDB,
    "sheet_ID",
    routineConfig["sheet_ID"],
  ); //1vJQVPX0-YypjwBAoiFcMNofKR91X8Zt57NAKlXrUre4

  var sems = ["1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th"];
  try {
    // Download the file
    var jsonValue = [];
    for (int i = 0; i < sems.length; i++) {
      final response = await http.get(
        Uri.parse(
          "https://docs.google.com/spreadsheets/d/$urlID/gviz/tq?tqx=out:json&sheet=${sems[i]}",
        ),
      );
      if (response.statusCode == 200) {
        var temp = response.body.split("setResponse(")[1];
        var main = temp.split(");")[0];
        jsonValue.add(json.decode(main));

        // print(jsonValue["table"]["rows"][0]['c'][0]['v']);
      }
    }
    return jsonValue;
  } catch (_) {
    return [];
  }
}

Future<List<int>?> loadLocal() async {
  try {
    ByteData data = await rootBundle.load(
      'assets/Class Routine (Summer-25).xlsx',
    );
    var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    return bytes;
  } catch (e) {
    print(e);
    return null;
  }
}

Future<Map<String, dynamic>> readTimeRow(
  dynamic json,
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
    try {
      var temp = json[0]["table"]["rows"][timeRow]['c'][timeColumn + i++]['v']
          .toString();
      if (temp == null) {
        break;
      }
      //print(temp);
      temp = temp.split("\n")[1].trim();
      timeData.add(temp);
    } catch (e) {
      break;
    }
  }
  int lastCollumn = timeColumn + i - 1;
  await setValueToHive("routine", "timeData", timeData);
  return {"timeRow": timeData, "lastCollumn": lastCollumn};
}

/*
Future<List<String>> getSheetNames(Excel excel) async {
  return excel.tables.keys.toList();
}
*/
Future<void> readExcelFile(
  // Excel excel,
  dynamic json,
  int lastCollumn,
  dynamic configFromDB,
) async {
  int timeRow = checkAndGet(configFromDB, "timeRow", routineConfig["timeRow"]);

  int timeColumn = checkAndGet(
    configFromDB,
    "timeColumn",
    routineConfig["timeColumn"],
  );

  int dayColumn = checkAndGet(
    configFromDB,
    "dayColumn",
    routineConfig["dayColumn"],
  );

  List<dynamic> temp = checkAndGet(
    configFromDB,
    "sheetNames",
    routineConfig["sheetNames"] as List<String>,
  );
  List<String> sheetNames = List<String>.from(temp);

  Map<String, Map<String, Map<String, List<dynamic>>>> days =
      {}; //sunday,1st,A,[[CSE 121,2]]
  Map<String, List<dynamic>> teachersRoutine = {};
  Map<String, List<dynamic>> roomFilter = {};

  // Traverse semesters:
  for (var s = 0; s < sheetNames.length; s++) {
    // Traverse rows:
    var dayName = "";
    var sem = "";
    var sec = "";
    for (var r = timeRow + 1; r < json[s]["table"]["rows"].length; r++) {
      if (json[s]["table"]["rows"][r]['c'] != null &&
          json[s]["table"]["rows"][r]['c'][0] != null) {
        var tempCell = json[s]["table"]["rows"][r]['c'][0]['v'].toString();
        if (tempCell != "null" || tempCell != "") {
          dayName = tempCell;
        }
      }
      // Traverse cols:
      for (var c = 1; c <= lastCollumn; c++) {
        if (json[s]["table"]["rows"][r]['c'] != null &&
            json[s]["table"]["rows"][r]['c'][c] != null) {
          var cell = json[s]["table"]["rows"][r]['c'][c]['v'].toString();
          if (cell != "null" || cell != "") {
            var cellPortions = cell.split("\n");
            var temp1 = cellPortions[1].split("(");
            var temp2 = temp1[1].split(")");
            var temp3 = temp2[0].split("Sem.");
            sem = temp3[0].trim();
            sec = temp3[1].split("Sec")[0].trim();
            var teachers = cellPortions[0].split(",");
            var room = cellPortions[2].trim();

            //var sub = temp1[0].trim();
            //print([dayName, sem, sec]);
            if (!days.containsKey(dayName)) {
              days[dayName] = {};
            }
            if (!days[dayName]!.containsKey(sem)) {
              days[dayName]![sem] = {};
            }
            if (!days[dayName]![sem]!.containsKey(sec)) {
              days[dayName]![sem]![sec] = [];
            }
            var old = days[dayName]![sem]![sec];
            old!.add([cell, c]);

            days[dayName]![sem]![sec] = old;
            // teacher add start
            if (teachersRoutine.containsKey(teachers[0].trim())) {
              teachersRoutine[teachers[0].trim()]!.add([dayName, c, cell]);
            } else {
              teachersRoutine[teachers[0].trim()] = [[dayName, c, cell]];
            }
            if (teachers.length > 1) {
              if (teachersRoutine.containsKey(teachers[1].trim())) {
                teachersRoutine[teachers[1].trim()]!.add([dayName, c, cell]);
              } else {
                teachersRoutine[teachers[1].trim()] = [[dayName, c, cell]];
              }
            }
            // teacher add done
            // roomFilter start
            if (roomFilter.containsKey(room)) {
              roomFilter[room]!.add([dayName, c, cell]);
            } else {
              roomFilter[room] = [[dayName, c, cell]];
            }
            // roomFilter done
          } else {
            var old = days[dayName]![sem]![sec];
            old!.add([null, c]);

            days[dayName]![sem]![sec] = old;
          }
        } else {
          if (!days.containsKey(dayName)) {
            days[dayName] = {};
          }
          if (!days[dayName]!.containsKey(sem)) {
            days[dayName]![sem] = {};
          }
          if (!days[dayName]![sem]!.containsKey(sec)) {
            days[dayName]![sem]![sec] = [];
          }
          var old = days[dayName]![sem]![sec];
          old!.add([null, c]);

          days[dayName]![sem]![sec] = old;
        }
      }
    }
  }

  /* Old implementation: excel
  // Get sheet names
  for (int k = 0; k < sheetNames.length; k++) {
    var sheetName = sheetNames[k];
    if (kDebugMode) {
      print(sheetName);
    }
    Map<int, Map<int, int>> mergedHorizontal = {}; //row, col, length
    Map<int, Map<int, int>> mergedVertical = {}; //col, row, length
    // Get merged cells information - spannedItems contains cell references like "A1:C3"
    if (excel.tables[sheetName] == null) {
      continue;
    }
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
      } else {
        if (!mergedVertical.containsKey(start["col"])) {
          mergedVertical[start["col"]!] = {};
        }
        mergedVertical[start["col"]]![start["row"] ?? 0] =
            ((end["row"]!) - (start["row"]!)).abs() + 1;
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
          if (mergedVertical.containsKey(j)) {
            mergedVertical[j]!.forEach((mRow, mLength) {
              if (i > mRow && i < (mRow + mLength)) {
                temp = [
                  excel.tables[sheetName]!.rows[mRow][j]?.value.toString(),
                ];
              }
            });
          }
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
  */
  await setValueToHive("routine", "days", days);
  await setValueToHive("routine", "teachersRoutine", teachersRoutine);
  await setValueToHive("routine", "roomFilter", roomFilter);
  await setValueToHive("routine", "syncAt", DateTime.now());

  //getTeacherDetails(configFromDB);
  /*
  if (kDebugMode) {
    print(teachersRoutine.keys.toList());
  }*/
}
