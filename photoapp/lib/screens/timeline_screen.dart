import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/db_helper.dart'; // For server URL and cookie
import 'photo_detail.dart'; // For detail view
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/ImageProvider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:io';
import 'dart:typed_data'; // For Uint8List


class TimelineScreen extends StatefulWidget {
  @override
  _TimelineScreenState createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  List<dynamic> _photos = [];
  int _pageNumber = 1; // Initial page
  final int _perPage = 20; // Photos per page
  bool _isLoading = false;
  String _navigationBarTitle = 'Timeline';
  ScrollController _scrollController = ScrollController();
  String? _serverUrl;
  String? _cookie;
  final Map<String, Uint8List> _imageCache = {}; // Local in-memory cache

  @override
  void initState() {
    super.initState();
    _initialize();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _initialize() async {
    try {
      // Fetch server URL and cookie
      Map<String, String?> userData = await DbHelper.getCookieAndServer();
      setState(() {
        _serverUrl = userData['server'];
        _cookie = userData['cookie'];
      });
      await _fetchPhotos();
    } catch (e) {
      print('Error initializing: $e');
    }
  }

  Future<void> _fetchPhotos() async {
  if (_isLoading || _serverUrl == null || _cookie == null) return;

  setState(() {
    _isLoading = true;
  });

  try {
    String apiUrl =
        '$_serverUrl/photo/list?page=$_pageNumber&per_page=$_perPage&order=new-to-old';

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {'Cookie': _cookie!}, // Include session cookie
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Check if there are new photos
      List<dynamic> newPhotos = data['photos'];
      if (newPhotos.isEmpty) {
        // Stop further fetching when no photos are returned
        setState(() {
          _isLoading = false; // Ensure loading is stopped
        });
        return;
      }

      setState(() {
        _photos.addAll(newPhotos); // Add new photos to the list
        _pageNumber++; // Increment page for the next fetch
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

    // Update navigation bar title
    if (_photos.isNotEmpty && _scrollController.hasClients) {
      double offset = _scrollController.offset;
      int visibleIndex = (offset / 150).floor(); // Estimate visible photo index
      if (visibleIndex >= 0 && visibleIndex < _photos.length) {
        String? date = _photos[visibleIndex]['creation_date'];
        if (date != null) {
          String formattedDate = date.split('T')[0]; // Extract YYYY-MM-DD
          setState(() {
            _navigationBarTitle = formattedDate;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_navigationBarTitle),
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
                ),
              ),
            );
          },
          child: buildImageFromCookie('$_serverUrl${_photos[index]['thumbnail_url']}', _cookie ?? ''),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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



}
