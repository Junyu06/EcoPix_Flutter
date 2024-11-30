import 'package:flutter/cupertino.dart';

class FolderScreen extends StatefulWidget {
  @override
  _FolderScreenState createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  String _selectedSegment = 'Folder'; // Tracks the current selection
  String _selectedSortingOption = 'random'; // Default sorting option

  List<Map<String, String>> _folder = [//mock, later use api get
    {'name': 'Folder 1'},
    {'name': 'Folder 2'},
    {'name': 'Folder 3'}
  ];

  Widget _buildAlbumsGridView() {
    return GridView.builder(
      padding: EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Two albums per row
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.0, // Equal width and height
      ),
      itemCount: _folder.length ,
      itemBuilder: (context, index) {
        return _buildAlbumBox(_folder[index]['name']!);
      },
    );
  }

  //Widget _openFolder(String _foldername){
  //  return Cupertino
 // }

  // Display the box for each album
  Widget _buildAlbumBox(String _foldername) {
    return GestureDetector(
      onTap: () {
        //_openFolder(_foldername); // Open the album when tapped
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: Icon(CupertinoIcons.photo, size: 50, color: CupertinoColors.black),
              ),
            ),
          ),
          SizedBox(height: 8.0),
          Text(_foldername, style: TextStyle(color: CupertinoColors.black)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: CupertinoSegmentedControl<String>(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          children: {
            'Folder': Text(' Folder '),
            'Photo': Text(' Photo '),
          },
          onValueChanged: (String value) {
            setState(() {
              _selectedSegment = value;
            });
          },
          groupValue: _selectedSegment,
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.sort_down),
          onPressed: () {
            _showSortingOptions(context); // Show sorting options
          },
        ),
      ),
      child: SafeArea(
        child: _buildContent(), // Build the content based on the selected segment
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedSegment == 'Folder') {
      return _folderScreen(); // Show folder content
    } else {
      return _photoScreen(); // Show photo content
    }
  }

  Widget _folderScreen() {
    return Center(
      child: Text('There is no folder found under this directory'),
    );
  }

  Widget _photoScreen() {
    return Center(
      child: Text('There is no photo found under this directory'),
    );
  }

  // Function to show sorting options using CupertinoActionSheet
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
                  _selectedSortingOption = 'random';
                });
                Navigator.pop(context);
              },
              child: Text('Random'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _selectedSortingOption = 'a-z';
                });
                Navigator.pop(context);
              },
              child: Text('A-Z'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _selectedSortingOption = 'z-a';
                });
                Navigator.pop(context);
              },
              child: Text('Z-A'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _selectedSortingOption = 'new-old';
                });
                Navigator.pop(context);
              },
              child: Text('New-Old'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _selectedSortingOption = 'old-new';
                });
                Navigator.pop(context);
              },
              child: Text('Old-New'),
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
}
