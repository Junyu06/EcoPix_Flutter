import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data'; // For Uint8List
import '../widgets/db_helper.dart';
import 'dart:convert';



class PhotoDetailScreen extends StatefulWidget{
  final List<dynamic> photos;//list of photo for pass in
  final int intialIndex; //index of the photo to display first
  final String serverUrl;  // Add serverUrl
  final String cookie;     // Add cookie


  const PhotoDetailScreen(
    {
      required this.photos, required this.intialIndex,required this.serverUrl,required this.cookie,
    }
  );

  @override
  _PhotoDetailScreenState createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen>{
  late PageController _pageController;
  int currentIndex = 0;
  bool _showTooBar = true;
  final Map<String, Uint8List> _imageCache = {}; // Local in-memory cache
  String? _serverUrl;
  String? _cookie;
  


  @override
  void initState(){
    super.initState();
    _pageController = PageController(initialPage: widget.intialIndex);
    currentIndex = widget.intialIndex;

    _initialize();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadImages(currentIndex);
    });
  }

  Future<void> _initialize() async {
    try {
      // Fetch server URL and cookie
      Map<String, String?> userData = await DbHelper.getCookieAndServer();
      setState(() {
        _serverUrl = userData['server'];
        _cookie = userData['cookie'];
      });
    } catch (e) {
      print('Error initializing: $e');
    }
  }

  void _preloadImages(int index){
    for (int i = index -3; i<= index+3; i++){
      if (i>=0 && i< widget.photos.length){
        if (_serverUrl!= null){
          buildImageFromCookie('$_serverUrl${widget.photos[i]['photo_url']}', _cookie ?? '');
        }
      }
    }
  }

  void _toggleTooBar(){
    setState(() {
      _showTooBar =!_showTooBar;//toggle toolbar visibility
    });
  }

  Future<void> _sharePhoto() async{//change later for save photo
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shared_photo', widget.photos[currentIndex]['urls']['full']);
    print('Photo Shared: ${widget.photos[currentIndex]['urls']['full']}');
  }

  void _setRating(int stars){
    //change it later for star rating logic
    print('Rated $stars stars for photo: ${widget.photos[currentIndex]['urls']['full']}');
  }

  @override
Widget build(BuildContext context) {
  final photoDate = widget.photos[currentIndex]; // Get current photo data
  return CupertinoPageScaffold(
    backgroundColor: CupertinoColors.black, // Ensure the background is black
    navigationBar: _showTooBar ? CupertinoNavigationBar(
      backgroundColor: CupertinoColors.black.withOpacity(0.5), // Semi-transparent background for the nav bar
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        child: Icon(CupertinoIcons.clear, color: CupertinoColors.white), // White close icon
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      middle: Text(
        '${widget.photos[currentIndex]['filename']}', 
        style: TextStyle(color: CupertinoColors.white), // White text
      ),
    ) : null,
    child: Stack(
      children: [
        GestureDetector(
          onTap: () {
            // Show toolbar when tapped
            _toggleTooBar();
          },
          onVerticalDragUpdate: (details) {
            int sensitivity = 8;
            if (details.delta.dy > sensitivity) {
              Navigator.pop(context);
            } else if (details.delta.dy < -sensitivity) {
              Navigator.pop(context);
            }
          },
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
              _preloadImages(index);
            },
            itemBuilder: (context, index) {
              return Center(
                child: Container(
                  child: buildImageFromCookie('$_serverUrl${widget.photos[index]['photo_url']}', _cookie ?? ''),
                ),
              );
            },
          ),
        ),
        // Conditionally show the toolbar at the bottom
        if (_showTooBar == true)
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: 
            Container(
              color: CupertinoColors.black.withOpacity(0.5),
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _sharePhoto();
                    },
                    child: Icon(CupertinoIcons.share, color: CupertinoColors.white),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _showInfo();
                    },
                    child: Icon(CupertinoIcons.info, color: CupertinoColors.white),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _showAlbumAction();
                    },
                    child: Icon(CupertinoIcons.star, color: CupertinoColors.white),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _deletePhoto();
                    },
                    child: Icon(CupertinoIcons.delete, color: CupertinoColors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

void _showInfo() {
  final photoData = widget.photos[currentIndex]; // Current photo metadata

  Navigator.of(context).push(
    CupertinoPageRoute(
      builder: (BuildContext context) {
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text('Photo Metadata'),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Table(
                columnWidths: const {
                  0: IntrinsicColumnWidth(), // Adjust column widths as needed
                  1: FlexColumnWidth(),
                },
                border: TableBorder.all(color: CupertinoColors.separator),
                children: photoData.entries.map<TableRow>((entry) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          entry.value?.toString() ?? 'N/A',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    ),
  );
}

  void _deletePhoto(){//chnage it later
    //nothing
  }

  void _showAlbumAction() {
  showCupertinoModalPopup(
    context: context,
    builder: (BuildContext context) {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAlbums(), // Fetch the list of albums
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CupertinoActivityIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return CupertinoActionSheet(
              title: Text('Error'),
              message: Text('Failed to load albums'),
              actions: [],
              cancelButton: CupertinoButton(
                child: Text('Close'),
                onPressed: () => Navigator.pop(context),
              ),
            );
          }

          List<Map<String, dynamic>> albums = snapshot.data!;
          return CupertinoActionSheet(
            title: Text('Manage Albums'),
            message: Text('Select an album to add/remove this photo.'),
            actions: albums.map((album) {
              return CupertinoActionSheetAction(
                child: Text(album['name']),
                onPressed: () {
                  _togglePhotoInAlbum(album['id'], widget.photos[currentIndex]['id']);
                  Navigator.pop(context); // Close the action sheet
                },
              );
            }).toList(),
            cancelButton: CupertinoButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
          );
        },
      );
    },
  );
}

Future<List<Map<String, dynamic>>> _fetchAlbums() async {
  try {
    if (_serverUrl == null || _cookie == null) throw Exception("Server or cookie missing");
    final response = await http.get(
      Uri.parse("$_serverUrl/albums"),
      headers: {'Cookie': _cookie!},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch albums: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching albums: $e');
    return [];
  }
}

Future<void> _togglePhotoInAlbum(int albumId, int photoId) async {
  try {
    final response = await http.get(
      Uri.parse("$_serverUrl/album/adddeletePhoto?album_id=$albumId&photo_id=$photoId"),
      headers: {'Cookie': _cookie!},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(data['message']); // Print success message
      setState(() {
        // Optionally update UI based on server response
      });
    } else {
      print('Failed to toggle photo in album: ${response.statusCode}');
    }
  } catch (e) {
    print('Error toggling photo in album: $e');
  }
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
