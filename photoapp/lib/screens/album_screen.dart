import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'photo_grip_view_screen.dart'; // Import for navigation
import '../widgets/db_helper.dart'; // For getting server and cookie
import 'package:flutter/material.dart';
import 'dart:typed_data';


class AlbumScreen extends StatefulWidget {
  @override
  _AlbumScreenState createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {

  List<Map<String, dynamic>> _albums = []; // Placeholder albums data

  String _selectedSortingOption = 'new-to-old'; // Default sorting option
  String? _serverUrl;
  String? _cookie;
  final Map<String, Uint8List> _imageCache = {}; // Local in-memory cache

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Fetch server URL and cookie from the database
      Map<String, String?> userData = await DbHelper.getCookieAndServer();
      setState(() {
        _serverUrl = userData['server'];
        _cookie = userData['cookie'];
      });
      await _fetchAlbums();
    } catch (e) {
      print("Error initializing: $e");
    }
  }

  Future<void> _fetchAlbums() async {
    if (_serverUrl == null || _cookie == null) return;

    try {
      final response = await http.get(
        Uri.parse("$_serverUrl/albums"),
        headers: {'Cookie': _cookie!},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final List<Map<String, dynamic>> parsedAlbums = data.map((album) => album as Map<String, dynamic>).toList();
        setState(() {
          _albums = parsedAlbums;
          _isLoading = false;
        });
      } else {
        print("Failed to fetch albums: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching albums: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Albums'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.sort_down),
          onPressed: () {
            _showSortingOptions(context); // Show sorting options
          },
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? Center(child: CupertinoActivityIndicator())
            : _buildAlbumsGridView(),
      ),
    );
  }

  // Grid view to display albums with "Create New" as the last item
    Widget _buildAlbumsGridView() {
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: _onRefresh, // Call the refresh function
        ),
        SliverPadding(
          padding: EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                if (index == _albums.length) {
                  // Last item is the "+" sign
                  return _buildCreateNewBox();
                }
                return _buildAlbumBox(_albums[index]);
              },
              childCount: _albums.length + 1, // Include the "+" sign
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onRefresh() async {
    // Refresh the albums by calling the fetch function
    setState(() {
      _isLoading = true;
    });

    await _fetchAlbums();

    setState(() {
      _isLoading = false;
    });
  }


  // Display the box for each album
Widget _buildAlbumBox(Map<String, dynamic> album) {
  return Stack(
    children: [
      GestureDetector(
        onTap: () {
          //print('Navigating to album: ${album['id']}, sorting option: $_selectedSortingOption');
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => PhotoGridViewScreen(
                albumid: album['id'].toString(), // Pass album ID
                selectedSortingOption: _selectedSortingOption, // Pass sorting option
              ),
            ),
          );
        },

        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: album['thumbnail_url'] != null && album['thumbnail_url'] != ''
                      ? buildImageFromCookie(
                          '$_serverUrl${album['thumbnail_url']}', // Construct full URL
                          _cookie ?? '', // Pass the cookie for authentication
                        )
                      : Center(
                          child: Icon(
                            CupertinoIcons.photo,
                            size: 50,
                            color: CupertinoColors.black,
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              album['name'],
              style: TextStyle(color: CupertinoColors.black),
            ),
            Text(
              '${album['photo_count']} Photos',
              style: TextStyle(color: CupertinoColors.inactiveGray, fontSize: 12),
            ),
          ],
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.clear_circled,
            color: CupertinoColors.destructiveRed,
            size: 24,
          ),
          onPressed: () {
            _showDeleteConfirmation(album['id'], album['name']);
          },
        ),
      ),
    ],
  );
}







void _showDeleteConfirmation(int albumId, String albumName) {
  showCupertinoDialog(
    context: context,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        title: Text("Delete Album"),
        content: Text("Are you sure you want to delete the album \"$albumName\"? This action cannot be undone."),
        actions: [
          CupertinoDialogAction(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
          ),
          CupertinoDialogAction(
            child: Text(
              "Delete",
              style: TextStyle(color: CupertinoColors.destructiveRed),
            ),
            onPressed: () async {
              Navigator.pop(context); // Close the dialog
              await _deleteAlbum(albumId);
            },
          ),
        ],
      );
    },
  );
}




Future<void> _deleteAlbum(int albumId) async {
  if (_serverUrl == null || _cookie == null) return;

  try {
    final response = await http.get(
      Uri.parse("$_serverUrl/album/action?action=delete&album_id=$albumId"),
      headers: {'Cookie': _cookie!},
    );

    if (response.statusCode == 200) {
      print("Album deleted successfully: $albumId");
      setState(() {
        _albums.removeWhere((album) => album['id'] == albumId); // Remove album from UI
      });
    } else {
      print("Failed to delete album: ${response.statusCode}");
    }
  } catch (e) {
    print("Error deleting album: $e");
  }
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
                  _albums.shuffle();
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
                  _albums.sort((a, b) => a['name'].compareTo(b['name']));
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
                  _albums.sort((a, b) => b['name'].compareTo(a['name']));
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
                  _albums.sort((a, b) => DateTime.parse(b['creation_date'])
                    .compareTo(DateTime.parse(a['creation_date'])));
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
                  _albums.sort((a, b) => DateTime.parse(a['creation_date'])
                    .compareTo(DateTime.parse(b['creation_date'])));
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
              onPressed: () async {
                if (_controller.text.isNotEmpty) {
                  try {
                    await _addNewAlbum(_controller.text);
                    Navigator.pop(context);
                    _refreshScreen();
                  } catch (e) {
                    print("Error adding new album: $e");
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addNewAlbum(String albumName) async {
    if (_serverUrl == null || _cookie == null) return;

    try {
      final response = await http.get(
        Uri.parse("$_serverUrl/album/action?action=add&album_id=nothing&album_name=$albumName"),
        headers: {'Cookie': _cookie!},
      );

      if (response.statusCode == 200) {
        print("Album added successfully: $albumName");
        await _fetchAlbums(); // Refresh albums after adding
      } else {
        print("Failed to add album: ${response.statusCode}");
      }
    } catch (e) {
      print("Error adding album: $e");
    }
  }

  Widget buildImageFromCookie(String imageUrl, String cookie) {
  if (_imageCache.containsKey(imageUrl)) {
    // Use cached image
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: MemoryImage(_imageCache[imageUrl]!),
          fit: BoxFit.cover, // Ensures it fills the container
        ),
      ),
    );
  } else {
    // Fetch image and cache it
    return FutureBuilder<http.Response>(
      future: http.get(
        Uri.parse(imageUrl),
        headers: {'Cookie': cookie},
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CupertinoActivityIndicator(); // Loading indicator
        } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.statusCode != 200) {
          return Icon(
            CupertinoIcons.exclamationmark_triangle, // Error icon
            color: Colors.red,
          );
        } else {
          // Cache the image data
          _imageCache[imageUrl] = snapshot.data!.bodyBytes;

          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: MemoryImage(snapshot.data!.bodyBytes),
                fit: BoxFit.cover, // Ensures it fills the container
              ),
            ),
          );
        }
      },
    );
  }
}

}