import 'package:flutter/cupertino.dart';

class SubFolderScreen extends StatefulWidget {
  final String? folderName; // Optional folder name to display when navigating

  SubFolderScreen({this.folderName});

  @override
  _SubFolderScreenState createState() => _SubFolderScreenState();
}

class _SubFolderScreenState extends State<SubFolderScreen> {
  String _selectedSegment = 'Folder'; // Tracks the current selection
  String _selectedSortingOption = 'random'; // Default sorting option

  // Mock folder data (for now)
  List<Map<String, String>> _folders = [
    {'name': 'Folder 1'},
    {'name': 'Folder 2'},
    {'name': 'Folder 3'},
    {'name': 'Subfolder 1'}, // Example subfolder
    {'name': 'Subfolder 2'},
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.folderName ?? 'Folders'), // Show folder name if navigating into a folder
      ),
      child: SafeArea(
        child: _buildFoldersGridView(),
      ),
    );
  }

  // Grid view to display folders
  Widget _buildFoldersGridView() {
    return GridView.builder(
      padding: EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Two folders per row
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.0, // Equal width and height for each folder box
      ),
      itemCount: _folders.length, // Number of folders
      itemBuilder: (context, index) {
        return _buildFolderBox(_folders[index]['name']!);
      },
    );
  }

  // Display the folder box with a tap gesture to open the folder
  Widget _buildFolderBox(String folderName) {
    return GestureDetector(
      onTap: () {
        // Open the selected folder when tapped
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => SubFolderScreen(folderName: folderName), // Open another folder screen
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.folder, size: 50, color: CupertinoColors.activeBlue),
              SizedBox(height: 8),
              Text(folderName),
            ],
          ),
        ),
      ),
    );
  }
}
