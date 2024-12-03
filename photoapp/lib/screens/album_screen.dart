import 'package:flutter/cupertino.dart';
import 'package:photoapp/screens/photo_grip_view_screen.dart';

class AlbumScreen extends StatefulWidget {
  @override
  _AlbumScreenState createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {

  List<Map<String, String>> _albums = [
    {'name': 'Album 1'},
    {'name': 'Album 2'},
    {'name': 'Album 3'}
  ]; // Placeholder albums data

  String _selectedSortingOption = 'Random'; // Default sorting option

  bool _isLoading = true;

  void _loadAlbums(){
    //set the 
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemGrey.withOpacity(0.0), // Transparent navigation bar
        middle: Text('Albums', style: TextStyle(color: CupertinoColors.black)), // Title
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.sort_down),
          onPressed: () {
            _showSortingOptions(context); // Show sorting options
          },
        ),
      ),
      child: SafeArea(
        child: _buildAlbumsGridView(), // Always show grid view, with "Create New" as the last item
      ),
    );
  }

  // Grid view to display albums with "Create New" as the last item
  Widget _buildAlbumsGridView() {
    return GridView.builder(
      padding: EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Two albums per row
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.0, // Equal width and height
      ),
      itemCount: _albums.length + 1, // One more item for "Create New"
      itemBuilder: (context, index) {
        if (index < _albums.length) {
          return _buildAlbumBox(_albums[index]['name']!);
        } else {
          return _buildCreateNewBox();
        }
      },
    );
  }

  // Display the box for each album
  Widget _buildAlbumBox(String albumName) {
    return GestureDetector(
      onTap: () {
        _openAlbumDetails(albumName); // Open the album when tapped
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
          Text(albumName, style: TextStyle(color: CupertinoColors.black)),
        ],
      ),
    );
  }

  // "Create New" box
  Widget _buildCreateNewBox() {
    return GestureDetector(
      onTap: () {
        _showCreateNewDialog(); // Show dialog to create a new album
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
                child: Icon(CupertinoIcons.add, size: 50, color: CupertinoColors.black),
              ),
            ),
          ),
          SizedBox(height: 8.0),
          Text('Create New', style: TextStyle(color: CupertinoColors.black)),
        ],
      ),
    );
  }

  void _refreshScreen(){
    setState(() {//it will refresh the widget
      _albums = _albums.reversed.toList();//change it later for 
    });
  }

  // Show sort options
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
                _refreshScreen();
              },
              child: Text('Random'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _selectedSortingOption = 'a-z';
                });
                Navigator.pop(context);
                _refreshScreen();
              },
              child: Text('A-Z'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _selectedSortingOption = 'z-a';
                });
                Navigator.pop(context);
                _refreshScreen();
              },
              child: Text('Z-A'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _selectedSortingOption = 'new-old';
                });
                Navigator.pop(context);
                _refreshScreen();
              },
              child: Text('New-Old'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _selectedSortingOption = 'old-new';
                });
                Navigator.pop(context);
                _refreshScreen();
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

  // Function to open album details using CupertinoPageRoute
  void _openAlbumDetails(String albumName) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => PhotoGridViewScreen(selectedSortingOption: _selectedSortingOption, albumName: albumName,),
        
        /*CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text(albumName), // Album title
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(CupertinoIcons.back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          child: Center(
            child: Text('Details for $albumName'), // Placeholder for album details
          ),
        ),
        */
      ),
    );
  }

  // Show dialog to create a new album
  void _showCreateNewDialog() {
    TextEditingController _controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Create New Album'),
          content: CupertinoTextField(
            controller: _controller,
            placeholder: 'Enter album name',
          ),
          actions: [
            CupertinoDialogAction(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            CupertinoDialogAction(
              child: Text('Create'),
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  setState(() {
                    _albums.add({'name': _controller.text});
                  });
                }
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}