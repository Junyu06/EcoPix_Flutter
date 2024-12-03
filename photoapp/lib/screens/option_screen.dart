import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data'; // For Uint8List
import '../widgets/db_helper.dart';

class OptionsPage extends StatefulWidget {
  final String exifType;
  final List<String> options;
  final Function(String) onOptionSelected;

  OptionsPage({
    required this.exifType,
    required this.options,
    required this.onOptionSelected,
  });

  @override
  _OptionsPageState createState() => _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {
  late List<String> _sortedOptions;

  @override
  void initState() {
    super.initState();
    //_sortedOptions = List<String>.from(widget.options); // Copy options to a new list
    _sortedOptions = List<String>.from(widget.options)..sort((a, b) => a.compareTo(b));
  }

  void _showSortingOptions(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text('Sort By'),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _sortedOptions.shuffle(); // Shuffle options randomly
                });
                Navigator.pop(context);
              },
              child: Text('Random'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _sortedOptions.sort((a, b) => a.compareTo(b)); // Sort A-Z
                });
                Navigator.pop(context);
              },
              child: Text('A-Z'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _sortedOptions.sort((a, b) => b.compareTo(a)); // Sort Z-A
                });
                Navigator.pop(context);
              },
              child: Text('Z-A'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Select ${widget.exifType}'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.sort_down),
          onPressed: () {
            _showSortingOptions(context);
          },
        ),
      ),
      child: ListView.builder(
        itemCount: _sortedOptions.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              widget.onOptionSelected(_sortedOptions[index]);
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.systemGrey4,
                    width: 0.5,
                  ),
                ),
              ),
              child: Text(
                _sortedOptions[index],
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

