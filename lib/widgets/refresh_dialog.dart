import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:lottie/lottie.dart';
import 'package:sheet_routine/fetcher/excel_fetcher.dart';

class RefreshDialog extends StatefulWidget {
  RefreshDialog({Key? key}) : super(key: key);
  @override
  _RefreshDialogState createState() => _RefreshDialogState();
}

int _c = -1;
bool _jobExecuted = false;
dynamic _file;
Excel? xl;
List<String> _sheetNames = [];
Map<String, dynamic> _timeRowData = {};
List<String> _msg = [
  "",
  "Downloading...",
  "Decoding...",
  "Reading Time Row...",
  "Reading full routine...",
  "Reading teacher details...",
];

Widget _dialogElement(int val, String name, BuildContext context) {
  return Row(
    children: [
      /*_c > val
          ? Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary,
              size: 40,
            )
          :*/
      CircularProgressIndicator(value: (_c.toDouble()) / 5),
      Padding(padding: EdgeInsets.only(right: 15)),
      Text(name),
    ],
  );
}

class _RefreshDialogState extends State<RefreshDialog> {
  @override
  void initState() {
    super.initState();
    // Execute functions after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((duration) {
      print("callback $_c");
      _c == -1 ? _c = 0 : print("c not equal -1 it is: $_c");
      _executer();
    });
  }

  _executer() async {
    // if(_jobExecuted) return;
    int timeRow = 1;
    int timeColumn = 3;
    int sectionColumn = 2;
    int semesterColumn = 1;
    print("c= $_c");
    if (_c == 0) {
      // _file = await downloadFile();
      _file = await loadLocal();
      if (_file == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Download error.")));
        Navigator.pop(context);
      }
      setState(() {
        _c++;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Downloaded.")));
      return;
    }
    if (_c == 1) {
      xl = await decodeFile(_file);
      setState(() {
        _c++;
      });

      return;
    }

    if (_c == 2) {
      _timeRowData = await readTimeRow(xl!, timeColumn, timeRow);
      setState(() {
        _c++;
      });
      return;
    }
    if (_c == 3) {
      await readExcelFile(xl!, _timeRowData["lastCollumn"]);
      setState(() {
        _c++;
      });
      return;
    }
    if (_c == 4) {
      var teachers = await getTeacherDetails(xl!);
      print(teachers);
      setState(() {
        _c = -1;
        //_jobExecuted = true;
      });
      return;
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
