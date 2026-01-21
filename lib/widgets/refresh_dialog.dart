import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sheet_routine/data/hive.dart';
import 'package:sheet_routine/fetcher/excel_fetcher.dart';
import 'package:sheet_routine/main.dart';
import 'package:sheet_routine/pages/google_sheet_config.dart';

class RefreshDialog extends StatefulWidget {
  RefreshDialog({Key? key}) : super(key: key);
  @override
  _RefreshDialogState createState() => _RefreshDialogState();
}

dynamic _file;

// bool _jobExecuted = false;
// List<String> _sheetNames = [];
Map<String, dynamic> _timeRowData = {};
List<String> _msg = [
  "Downloading",
  "Decoding",
  "Reading Time Row",
  "Reading Routine Cells",
  "Reading Teacher Details",
  "",
];
Future<bool> executer(BuildContext cntx) async {
  var result = false;
  // if(_jobExecuted) return;
  var config = await getValueFromHive("settings", "config", null);

  int timeRow = (config is Map && config.containsKey("timeRow"))
      ? config["timeRow"]
      : routineConfig["timeRow"];
  int timeColumn = (config is Map && config.containsKey("timeColumn"))
      ? config["timeColumn"]
      : routineConfig["timeColumn"];

  // _file = await loadLocal();
  // loadLocal().then((value) {
  await downloadFile(config).then((value) async{
    _file = value;

    if (_file == []) {

      return false;
    }
    if (kDebugMode) {
      print("download done!");
    }

    await readTimeRow(_file, timeColumn, timeRow).then((value) async{
      _timeRowData = value;
      if (kDebugMode) {
        print(_timeRowData);
      }
      if (_timeRowData["lastCollumn"] != null) {
        await readExcelFile(_file, _timeRowData["lastCollumn"], config).then((value) {
          result = true;
        });
      }
    });

    //return false;
  });
  return result;
}

/*
Widget _dialogElement(int val, String name, BuildContext context) {
  return Row(
    children: [
    
      CircularProgressIndicator(value: (_c.toDouble()) / 5),
      Padding(padding: EdgeInsets.only(right: 15)),
      Text(name),
    ],
  );
}*/

class _RefreshDialogState extends State<RefreshDialog> {
  @override
  void initState() {
    super.initState();
    // Execute functions after the first frame is rendered
    // WidgetsBinding.instance.addPostFrameCallback((duration) {
    //   executer();
    // });
  }

  @override
  Widget build(BuildContext context) {
    executer(context);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text("Syncing..."),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            Padding(padding: EdgeInsetsGeometry.only(right: 10)),
            Text(("Hold on.")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            }, // Close dialog
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
