import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photoapp/screens/photo_detail.dart'; // Import PhotoDetailScreen
import 'package:photoapp/widgets/unsplash_api.dart'; // Import Unsplash API

class PhotoGridViewScreen extends StatefulWidget {
  final String selectedSortingOption; // Sorting option
  final String albumName; // Album name
  final String url; // For later getting own server

  PhotoGridViewScreen({
    required this.selectedSortingOption,
    required this.albumName,
    required this.url,
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

  String _selectedSortingOption = 'Random'; // Default sorting option

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _fetchPhotos(); // Fetch initial photos
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Clean up the controller
    super.dispose();
  }

  Future<void> _fetchPhotos() async {
    if (_isLoading) return; // Prevent multiple calls
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch photos from the Unsplash API using the ServerConnection class
      List<dynamic> newPhotos = await API.fetchPhotos(_pageNumber, _photosPerPage);

      setState(() {
        _photos.addAll(newPhotos);
        _pageNumber++; // Increase page number for the next fetch
      });
    } catch (error) {
      print('Error fetching photos: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent &&
        !_isLoading) {
      _fetchPhotos(); // Load more photos when reaching the bottom
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          widget.albumName, // Album name as the title
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
        child: _buildPhotoGridView(), // Build the grid view of photos
      ),
    );
  }

  Widget _buildPhotoGridView() {
    return GridView.builder(
      controller: _scrollController, // Attach scroll controller
      padding: EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Three photos per row
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.0, // Square grid items
      ),
      itemCount: _photos.length + (_isLoading ? 1 : 0), // Show loading indicator at the end
      itemBuilder: (context, index) {
        if (index == _photos.length) {
          return Center(child: CircularProgressIndicator()); // Loading indicator
        }
        return GestureDetector(
          onTap: () {
            // Navigate to the PhotoDetailScreen on press
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => new PhotoDetailScreen(
                  photos: _photos, 
                  intialIndex: index,
                ),
              ),
            );
          },
          child: _buildPhotoTile(_photos[index]),
        );
      },
    );
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

  // Widget for individual photo tiles
  Widget _buildPhotoTile(dynamic photo) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: CachedNetworkImage(
          imageUrl: photo['urls']['thumb'], // Unsplash photo URL
          placeholder: (context, url) => CircularProgressIndicator(),
          errorWidget: (context, url, error) => Icon(CupertinoIcons.exclamationmark_triangle),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
