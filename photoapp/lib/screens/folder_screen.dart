import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:photoapp/screens/photo_detail.dart';
import '../widgets/db_helper.dart';
import 'dart:typed_data';
import 'photo_detail.dart';

class FolderScreen extends StatefulWidget {
  @override
  _FolderScreenState createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  String _selectedSegment = 'Folder'; // Tracks the current selection
  String _currentPath = '/Photos'; // Tracks the current path in the folder structure
  List<String> _navigationStack = ['/Photos'];
  List<Map<String, dynamic>> _folders = []; // List of folders
  List<Map<String, dynamic>> _photos = []; // List of photos
  bool _isLoading = false; // Loading state
  String? _serverUrl;
  String? _cookie;
  final Map<String, Uint8List> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
  try {
    Map<String, String?> userData = await DbHelper.getCookieAndServer();
    setState(() {
      _serverUrl = userData['server'];
      _cookie = userData['cookie'];
      _navigationStack = [_currentPath]; // Reset navigation stack
    });
    await _fetchFolders();
  } catch (e) {
    print('Error initializing: $e');
  }
}


Future<void> _fetchFolders() async {
  if (_serverUrl == null || _cookie == null) return;

  setState(() {
    _isLoading = true;
  });

  try {
    final response = await http.get(
      Uri.parse("$_serverUrl/folders?path=$_currentPath"),
      headers: {'Cookie': _cookie!},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        _folders = List<Map<String, dynamic>>.from(data['subfolders']).map((folder) {
          return {
            "name": folder["name"],
            "path": folder["path"],
            "creation_date": folder["creation_date"] ?? "", // Handle missing creation_date
          };
        }).toList();

        _photos = []; // Clear photos when changing folders
      });
    } else {
      print('Failed to fetch folders: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching folders: $e');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


  Future<void> _fetchPhotos() async {
  if (_serverUrl == null || _cookie == null) return;

  setState(() {
    _isLoading = true;
  });

  try {
    final response = await http.get(
      Uri.parse("$_serverUrl/folders/photos?path=$_currentPath"),
      headers: {'Cookie': _cookie!},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      //print('Photos API Response: $data'); // Debug log
      setState(() {
        _photos = List<Map<String, dynamic>>.from(data['photos']);
        //print('Photos fetched: $_photos'); // Debug log
      });
    } else {
      print('Failed to fetch photos: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching photos: $e');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


  Widget _buildFoldersGridView() {
  if (_folders.isEmpty) {
    // Display message when no folders are available
    return Center(
      child: Text(
        'Amazing things are happening here',
        style: TextStyle(fontSize: 26, color: CupertinoColors.systemGrey),
      ),
    );
  }

  return GridView.builder(
    padding: EdgeInsets.all(16.0),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2, // Two folders per row
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      childAspectRatio: 1.0, // Equal width and height
    ),
    itemCount: _folders.length,
    itemBuilder: (context, index) {
      return _buildFolderBox(_folders[index]['name']!, _folders[index]['path']!);
    },
  );
}

Widget _buildPhotosGridView() {
  if (_photos.isEmpty) {
    // Display message when no photos are available
    return Center(
      child: Text(
        'More photos on the way.',
        style: TextStyle(fontSize: 26, color: CupertinoColors.systemGrey),
      ),
    );
  }

  return GridView.builder(
    padding: EdgeInsets.all(16.0),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3, // Three photos per row
      crossAxisSpacing: 8.0,
      mainAxisSpacing: 8.0,
      childAspectRatio: 1.0, // Equal width and height
    ),
    itemCount: _photos.length,
    itemBuilder: (context, index) {
      return _buildPhotoBox(_photos[index],index);
    },
  );
}


  Widget _buildFolderBox(String folderName, String folderPath) {
  return GestureDetector(
    onTap: () {
      setState(() {
        _navigationStack.add(_currentPath); // Push the current path to the stack
        _currentPath = folderPath; // Navigate to the clicked folder
      });
      _fetchFolders();
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
              child: Icon(
                CupertinoIcons.folder,
                size: 50,
                color: CupertinoColors.black,
              ),
            ),
          ),
        ),
        SizedBox(height: 8.0),
        Text(folderName, style: TextStyle(color: CupertinoColors.black)),
      ],
    ),
  );
}


  Widget _buildPhotoBox(Map<String, dynamic> photo, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, CupertinoPageRoute(
              fullscreenDialog: true,
              builder: (context) => PhotoDetailScreen(
                photos: _photos,
                intialIndex: index,
                serverUrl: _serverUrl ?? '',
                cookie: _cookie ?? '',
              ),
            ),);
      },
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: buildImageFromCookie(
            "$_serverUrl${photo['thumbnail_url']}",
            _cookie ?? '',
          ),
        ),
      ),
    );
  }

  Widget buildImageFromCookie(String imageUrl, String cookie) {
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
          return Image.memory(
            snapshot.data!.bodyBytes,
            fit: BoxFit.cover,
          );
        }
      },
    );
  }

  Widget _buildBackButton() {
  return _navigationStack.length > 1
      ? CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.back),
          onPressed: () {
            setState(() {
              _currentPath = _navigationStack.removeLast(); // Navigate back
            });
            _fetchFolders(); // Fetch folders for the updated path
          },
        )
      : Container(); // Empty when no back navigation is possible
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
                if (_selectedSegment == 'Folder') {
                  // Sort folders randomly
                  _folders.shuffle();
                } else {
                  // Sort photos randomly
                  _photos.shuffle();
                }
              });
              Navigator.pop(context);
            },
            child: Text('Random'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                if (_selectedSegment == 'Folder') {
                  // Sort folders A-Z
                  _folders.sort((a, b) => a['name'].compareTo(b['name']));
                } else {
                  // Sort photos A-Z
                  _photos.sort((a, b) => a['filename'].compareTo(b['filename']));
                }
              });
              Navigator.pop(context);
            },
            child: Text('A-Z'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                if (_selectedSegment == 'Folder') {
                  // Sort folders Z-A
                  _folders.sort((a, b) => b['name'].compareTo(a['name']));
                } else {
                  // Sort photos Z-A
                  _photos.sort((a, b) => b['filename'].compareTo(a['filename']));
                }
              });
              Navigator.pop(context);
            },
            child: Text('Z-A'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                if (_selectedSegment == 'Folder') {
                  // Sort folders by new-old
                  _folders.sort((a, b) =>
                      DateTime.parse(b['creation_date']).compareTo(DateTime.parse(a['creation_date'])));
                } else {
                  // Sort photos by new-old
                  _photos.sort((a, b) =>
                      DateTime.parse(b['creation_date']).compareTo(DateTime.parse(a['creation_date'])));
                }
              });
              Navigator.pop(context);
            },
            child: Text('New-Old'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                if (_selectedSegment == 'Folder') {
                  // Sort folders by old-new
                  _folders.sort((a, b) =>
                      DateTime.parse(a['creation_date']).compareTo(DateTime.parse(b['creation_date'])));
                } else {
                  // Sort photos by old-new
                  _photos.sort((a, b) =>
                      DateTime.parse(a['creation_date']).compareTo(DateTime.parse(b['creation_date'])));
                }
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




@override
Widget build(BuildContext context) {
  return CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(
      leading: _navigationStack.length > 1 // Show back button only if not at the root
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(CupertinoIcons.back),
              onPressed: () {
                setState(() {
                  _currentPath = _navigationStack.removeLast(); // Go back to the previous folder
                });
                _fetchFolders(); // Fetch the folders for the new path
              },
            )
          : null, // No back button at the root
      middle: CupertinoSegmentedControl<String>(
        padding: EdgeInsets.symmetric(horizontal: 12.0),
        children: {
          'Folder': Text('Folder'),
          'Photo': Text('Photo'),
        },
        onValueChanged: (String value) {
          setState(() {
            _selectedSegment = value;
            if (_selectedSegment == 'Photo') {
              _fetchPhotos();
            } else {
              _fetchFolders();
            }
          },);
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
      child: _isLoading
          ? Center(child: CupertinoActivityIndicator())
          : (_selectedSegment == 'Folder'
              ? _buildFoldersGridView()
              : _buildPhotosGridView()),
    ),
  );
}



}
