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
  final String albumid; // Album name

  PhotoGridViewScreen({
    required this.selectedSortingOption,
    required this.albumid,
  });

  @override
  _PhotoGridViewScreenState createState() => _PhotoGridViewScreenState();
}

class _PhotoGridViewScreenState extends State<PhotoGridViewScreen> {
  List<dynamic> _photos = [];
  int _pageNumber = 1; // Page number for endless scrolling
  final int _photosPerPage = 20; // Number of photos to load per page
  bool _isLoading = false; // Loading state
  late ScrollController _scrollController;
  ServerConnection API = ServerConnection(); // Unsplash API instance
  String? _serverUrl;
  String? _cookie;
  int _perPage = 20;
  String? album_id;
  final Map<String, Uint8List> _imageCache = {}; // Local in-memory cache

  String _selectedSortingOption = 'Random'; // Default sorting option

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _fetchPhotos(); // Fetch initial photos
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      album_id = widget.albumid;
      _selectedSortingOption = widget.selectedSortingOption;
      // Fetch server URL and cookie
      Map<String, String?> userData = await DbHelper.getCookieAndServer();
      setState(() {
        _serverUrl = userData['server'];
        _cookie = userData['cookie'];
      });
       //print('Initialized with album_id: $album_id, server: $_serverUrl, cookie: $_cookie');
      await _fetchPhotos();
    } catch (e) {
      print('Error initializing: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Clean up the controller
    super.dispose();
  }

  Future<void> _fetchPhotos({bool refresh = false}) async {
  if (_isLoading || _serverUrl == null || _cookie == null || album_id == null) return;

  setState(() {
    _isLoading = true;
  });

  try {
    if (refresh) {
      setState(() {
        _pageNumber = 1; // Reset pagination
        _photos.clear(); // Clear existing photos
      });
    }

    String apiUrl =
        '$_serverUrl/album/photos?page=$_pageNumber&per_page=$_photosPerPage&order=$_selectedSortingOption&album_id=$album_id';

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {'Cookie': _cookie!}, // Include session cookie
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> newPhotos = data['photos'];
      if (newPhotos.isEmpty) {
        print('No more photos to load.');
        return;
      }

      setState(() {
        _photos.addAll(newPhotos); // Add photos to the grid
        _pageNumber++; // Increment page for pagination
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



  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent &&
        !_isLoading) {
      _fetchPhotos();
    }
  }
    
  // String _albumNameMode(){
  //   String album_name = _photos[1]['album'];
  //   return album_name;
  // }

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
              });
              Navigator.pop(context);
              _fetchPhotos(refresh: true); // Re-fetch photos with sorting applied
            },
            child: Text('A-Z'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedSortingOption = 'z-a';
              });
              Navigator.pop(context);
              _fetchPhotos(refresh: true); // Re-fetch photos with sorting applied
            },
            child: Text('Z-A'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedSortingOption = 'new-to-old';
              });
              Navigator.pop(context);
              _fetchPhotos(refresh: true); // Re-fetch photos with sorting applied
            },
            child: Text('New-Old'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedSortingOption = 'old-to-new';
              });
              Navigator.pop(context);
              _fetchPhotos(refresh: true); // Re-fetch photos with sorting applied
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