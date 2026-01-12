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

int _c = -1;
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
    WidgetsBinding.instance.addPostFrameCallback((duration) {
      if (kDebugMode) {
        print("callback $_c");
      }
      _c == -1 ? _c = 0 : print("c not equal -1 it is: $_c");
      _executer();
    });
  }

  _executer() async {
    // if(_jobExecuted) return;
    var config = await getValueFromHive("settings", "config", null);

    int timeRow = (config is Map && config.containsKey("timeRow"))
        ? config["timeRow"]
        : routineConfig["timeRow"];
    int timeColumn = (config is Map && config.containsKey("timeColumn"))
        ? config["timeColumn"]
        : routineConfig["timeColumn"];

    if (kDebugMode) {
      print("c= $_c");
    }
    if (_c == 0) {
      // _file = await loadLocal();
      // loadLocal().then((value) {
       downloadFile(config).then((value) {
        _file = value;
        // if(kDebugMode){
        //   print(_file);
        // }
        if (_file == []) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Download error.")));
          // Navigator.pop(context);
          return;
        }
        if (kDebugMode) {
          print("download done!");
        }
        setState(() {
          _c = 2;
        });

        return;
      });
    }

    if (_c == 2) {
      readTimeRow(_file, timeColumn, timeRow).then((value) {
        _timeRowData = value;
        if(kDebugMode){
          print(_timeRowData);
        }
        if (_timeRowData["lastCollumn"] != null) {
          setState(() {
            _c = 3;//3;
          });
          return;
        }
      });
    }
    if (_c == 3) {
      readExcelFile(_file, _timeRowData["lastCollumn"], config).then((value) {
        setState(() {
          _c = -1;
        Navigator.pop(context);
        });
        MyApp.restartApp(context);
        return;
      });
    }
    /*
    if (_c == 4) {
      getTeacherDetails(xl!, config).then((teachers) {
        if (kDebugMode) {
          print(teachers);
        }
        setState(() {
          _c = -1;
        });
        MyApp.restartApp(context);
        Navigator.pop(context);
        return;
      });
    }*/
  }

  @override
  Widget build(BuildContext context) {
    _executer();
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
            Text((_c > -1 ? "${_msg[_c]}..." : "Initializing...")),
          ],
        ),
        actions: [
          
          TextButton(
            onPressed: () {
              _c = -1;
              Navigator.pop(context);
            }, // Close dialog
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
