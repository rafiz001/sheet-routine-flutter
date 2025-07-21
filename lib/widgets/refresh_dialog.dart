import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sheet_routine/data/hive.dart';
import 'package:sheet_routine/fetcher/excel_fetcher.dart';
import 'package:sheet_routine/main.dart';

class RefreshDialog extends StatefulWidget {
  RefreshDialog({Key? key}) : super(key: key);
  @override
  _RefreshDialogState createState() => _RefreshDialogState();
}

int _c = -1;
List<int>? _file;
Excel? xl;
// bool _jobExecuted = false;
// List<String> _sheetNames = [];
Map<String, dynamic> _timeRowData = {};
List<String> _msg = [
  "",
  "Downloaded",
  "Decoded",
  "Time Row Read Done...",
  "Reading Full Routine Done...",
  "Reading Teacher Details Done...",
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
        : 1;
    int timeColumn = (config is Map && config.containsKey("timeColumn"))
        ? config["timeColumn"]
        : 3;

    if (kDebugMode) {
      print("c= $_c");
    }
    if (_c == 0) {
      // _file = await loadLocal();
      downloadFile(config).then((value) {
        _file = value;
        if (_file == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Download error.")));
          Navigator.pop(context);
        }

        if (kDebugMode) {
          print("download done!");
        }
        setState(() {
          _c=1;
        });

        return;
      });
    }
    if (_c == 1) {
      decodeFile(_file!).then((value) {
        xl = value;
        if (xl != null) {
        setState(() {
          _c=2;
        });
          return;
        }
      });
    }

    if (_c == 2) {
      readTimeRow(xl!, timeColumn, timeRow).then((value) {
        _timeRowData = value;
        if (_timeRowData["lastCollumn"] != null) {
        setState(() {
          _c=3;
        });
          return;
        }
      });
    }
    if (_c == 3) {
      readExcelFile(xl!, _timeRowData["lastCollumn"], config).then((value) {
        setState(() {
          _c=4;
        });
        return;
      });
    }
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
    }
  }

  @override
  Widget build(BuildContext context) {
    _executer();
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /*
            _dialogElement(0, "Downloading Excel File", context),
            Padding(padding: EdgeInsets.only(bottom: 15)),
            _dialogElement(1, "Parsing Excel File", context),
            Padding(padding: EdgeInsets.only(bottom: 15)),
            _dialogElement(2, "Getting Sheet Names", context),
            Padding(padding: EdgeInsets.only(bottom: 15)),
            _dialogElement(3, "Reading Time Row", context),
            Padding(padding: EdgeInsets.only(bottom: 15)),
            _dialogElement(4, "Parsing Cells", context),
            Padding(padding: EdgeInsets.only(bottom: 15)),
            */
            Lottie.asset(
              "assets/images/loading_lottie.json",
              delegates: LottieDelegates(
                values: [
                  ValueDelegate.color(
                    const ['LOADING Outlines', '**'],
                    value: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ],
              ),
              //backgroundLoading: true,
              height: 300,
              width: 300,
            ),

            Text(_c > -1 ? _msg[_c] : "Initializing..."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _executer();
            },
            child: Text("Execute"),
          ),
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
