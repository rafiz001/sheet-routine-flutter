import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:sheet_routine/fetcher/excel_fetcher.dart';

class RefreshDialog extends StatefulWidget {
  RefreshDialog({Key? key}) : super(key: key);
  @override
  _RefreshDialogState createState() => _RefreshDialogState();
}

int _c = 0;
bool _jobExecuted = false;
Response? _file ;
Excel? xl;
List<String> _sheetNames = [];
Map<String, dynamic> _timeRowData = {};
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
           CircularProgressIndicator(value:  (_c.toDouble())/5,),
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
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _executer();
    // });
    
  }


  Future<Null> _executer() async {
    if(_jobExecuted) return;
    int timeRow = 1;
    int timeColumn = 3;
    int sectionColumn = 2;
    int semesterColumn = 1;

    if (_c == 0) {
      _file = await downloadFile(); 
      setState(() {
        _c++;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Downloaded.")));
      return;
    }
    if (_c == 1) {
      xl = await parseFile(_file); 
      setState(() {
        _c++;
      });
      return;
    }
    if (_c == 2) {
      _sheetNames = await getSheetNames(xl!);
      setState(() {
        _c++;
      });
      return;
    }
    if (_c == 3) {
      _timeRowData = await readTimeRow(xl!, timeColumn, timeRow);
      setState(() {
        _c++;
      });
      return;
    }
    if (_c == 4) {
      await readExcelFile(xl!, _timeRowData["lastCollumn"]);
      setState(() {
        _c++;
        _jobExecuted = true;
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    _executer();
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
        ],
      ),
      actions: [
        TextButton(onPressed: () => _executer(), child: Text("Execute")),
        TextButton(
          onPressed: () {_c=0; Navigator.pop(context); }, // Close dialog
          child: const Text('Close'),
        ),
      ],
    );
  }
}
