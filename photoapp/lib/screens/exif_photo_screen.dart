import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/db_helper.dart';
import 'package:photoapp/screens/photo_detail.dart'; // Import PhotoDetailScreen
import 'package:photoapp/widgets/unsplash_api.dart'; // Import Unsplash API
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
// this is for album dart
class PhotoGridViewScreen extends StatefulWidget {
  final String selectedSortingOption; // Sorting option
  final String exifType; // Album name
  final String? value;

  PhotoGridViewScreen({
    required this.selectedSortingOption,
    required this.exifType,
    required this.value,
  });

  @override
  _PhotoGridViewScreenState createState() => _PhotoGridViewScreenState();
}

class _PhotoGridViewScreenState extends State<PhotoGridViewScreen> {
  List<dynamic> _photos = [];
  bool _isLoading = false; // Loading state
  late ScrollController _scrollController;
  String? _serverUrl;
  String? _cookie;
  final Map<String, Uint8List> _imageCache = {}; // Local in-memory cache

  String _selectedSortingOption = 'new-to-old'; // Default sorting option

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _selectedSortingOption = widget.selectedSortingOption;
      // Fetch server URL and cookie
      Map<String, String?> userData = await DbHelper.getCookieAndServer();
      setState(() {
        _serverUrl = userData['server'];
        _cookie = userData['cookie'];
      });
       //print('Initialized with album_id: $album_id, server: $_serverUrl, cookie: $_cookie');
      await _fetchPhotosByOption(widget.exifType, widget.value??'');
    } catch (e) {
      print('Error initializing: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Clean up the controller
    super.dispose();
  }

Future<void> _fetchPhotosByOption(String exifType, String value) async {
  try {
    final response = await http.get(
      Uri.parse("$_serverUrl/photoexif?exif_type=$exifType&action=photo&value=$value"),
      headers: {'Cookie': _cookie!},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      //print('Photos for $exifType=$value: ${data['photos']}');
      setState(() {
        _photos = data['photos']; // Assign the "photos" list specifically
      });
    } else {
      print('Failed to fetch photos: ${response.statusCode}');
      _showErrorDialog('Error', 'Failed to fetch photos.');
    }
  } catch (e) {
    print('Error fetching photos: $e');
    _showErrorDialog('Error', 'Failed to fetch photos.');
  }
}

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }


  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent &&
        !_isLoading) {
      //_fetchPhotos();
    }
  }
    
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          _photos.isNotEmpty
              ? (_photos[0]['album'] != null ? _photos[0]['album']['name'] : 'Album')
              : 'Album', // Fallback for empty photos or no album
          style: TextStyle(color: CupertinoColors.black),
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
        child: Column(
          children: [
            Expanded(
              child: _buildPhotoGrid(),
            ),
            if (_isLoading) CupertinoActivityIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
  return GridView.builder(
    controller: _scrollController,
    padding: EdgeInsets.all(8.0),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 8.0,
      mainAxisSpacing: 8.0,
    ),
    itemCount: _photos.length,
    itemBuilder: (context, index) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            CupertinoPageRoute(
              fullscreenDialog: true,
              builder: (context) => PhotoDetailScreen(
                photos: _photos,
                intialIndex: index,
                serverUrl: _serverUrl ?? '',
                cookie: _cookie ?? '',
              ),
            ),
          );
        },
        child: buildImageFromCookie('$_serverUrl${_photos[index]['thumbnail_url']}', _cookie ?? ''),
      );
    },
  );
}


  Widget buildImageFromCookie(String imageUrl, String cookie) {
    if (_imageCache.containsKey(imageUrl)) {
      // Use cached image
      return Image.memory(
        _imageCache[imageUrl]!,
        fit: BoxFit.cover,
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

            return Image.memory(
              snapshot.data!.bodyBytes,
              fit: BoxFit.cover,
            );
          }
        },
      );
    }
  }


  void _refreshScreen(){
    setState(() {//it will refresh the widget
      _photos = _photos.reversed.toList();//change it later for 
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
                _photos.shuffle(); // Shuffle photos locally
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
                _photos.sort((a, b) => a['filename'].compareTo(b['filename']));
              });
              Navigator.pop(context);
              _refreshScreen();
             //_fetchPhotos(refresh: true); // Re-fetch photos with sorting applied
            },
            child: Text('A-Z'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedSortingOption = 'z-a';
                _photos.sort((a, b) => b['filename'].compareTo(a['filename']));
              });
              Navigator.pop(context);
              _refreshScreen();
              //_fetchPhotos(refresh: true); // Re-fetch photos with sorting applied
            },
            child: Text('Z-A'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedSortingOption = 'new-to-old';
                _photos.sort((a, b) => DateTime.parse(b['creation_date'])
                    .compareTo(DateTime.parse(a['creation_date'])));
              });
              Navigator.pop(context);
              _refreshScreen();
              //_fetchPhotos(refresh: true); // Re-fetch photos with sorting applied
            },
            child: Text('New-Old'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedSortingOption = 'old-to-new';
                _photos.sort((a, b) => DateTime.parse(a['creation_date'])
                    .compareTo(DateTime.parse(b['creation_date'])));
              });
              Navigator.pop(context);
              _refreshScreen();
              //_fetchPhotos(refresh: true); // Re-fetch photos with sorting applied
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