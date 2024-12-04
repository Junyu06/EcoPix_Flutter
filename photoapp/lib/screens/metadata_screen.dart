import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data'; // For Uint8List
import '../widgets/db_helper.dart';
import 'option_screen.dart';
import 'exif_photo_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // For LatLng
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';

class MetadataScreen extends StatefulWidget {
  @override
  _MetadataScreen createState() => _MetadataScreen();
}

class _MetadataScreen extends State<MetadataScreen> {
  String _selectedSegment = 'Folder'; // Tracks the current selection
  String _selectedSortingOption = 'a-z'; // Default sorting option
  String? _serverUrl; // Replace with your actual server URL
  String? _cookie; // Replace with the actual session cookie
  final Map<String, Uint8List> _imageCache = {}; // Local in-memory cache
  List<Marker> _markers =[];

  @override
  void initState(){
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
      await _fetchGpsData();
    } catch (e) {
      print("Error initializing: $e");
    }
  }

Future<void> _fetchGpsData() async {
  if (_serverUrl == null || _cookie == null) return;

  try {
    final response = await http.get(
      Uri.parse("$_serverUrl/photoexif?exif_type=GPS&action=list"),
      headers: {'Cookie': _cookie!},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> clusters = data['clusters']; // Ensure correct key is used

      setState(() {
  _markers = clusters.map((cluster) {
    return Marker(
      point: LatLng(
        cluster['cluster_latitude'],
        cluster['cluster_longitude'],
      ),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () {
          print('Cluster tapped with ID: ${cluster['id']}');
          Navigator.push(context, CupertinoPageRoute(
                builder: (context) => PhotoGridViewScreen(
                  selectedSortingOption: 'new-to-old',
                  exifType: 'GPS',
                  value: cluster['id'].toString(),
                ),
              ),);
          // Add navigation or actions for the tapped cluster here
        },
        child: Icon(
          CupertinoIcons.map_pin,
          color: const Color.fromARGB(255, 0, 0, 0),
          size: 30,
        ),
      ),
    );
  }).toList();
});

    } else {
      print('Failed to fetch GPS data: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching GPS data: $e');
  }
}



  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: CupertinoSegmentedControl<String>(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          children: {
            'Folder': Text('GPS'),
            'Photo': Text('EXIF'),
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
            _showSortingOptions(context);
          },
        ),
      ),
      child: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedSegment == 'Folder') {
      //return Center(child: Text('GPS Screen Coming Soon'));
      return _buildGpsScreen();
    } else {
      return _photoScreen();
    }
  }

Widget _buildGpsScreen() {
  return FlutterMap(
    options: MapOptions(
      initialCenter: _markers.isNotEmpty
          ? _markers[0].point
          : LatLng(40.752495, -73.712736),
      initialZoom: 10,
      maxZoom: 18,
      minZoom: 3,
    ),
    children: [
      TileLayer(
        urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
        userAgentPackageName: 'com.example.app',
      ),
      MarkerClusterLayerWidget(
        options: MarkerClusterLayerOptions(
          maxClusterRadius: 45,
          size: Size(40, 40),
          // fitBoundsOptions: FitBoundsOptions(
          //   padding: EdgeInsets.all(50),
          // ),
          markers: _markers,
          builder: (context, cluster) {
            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Text(
                cluster.length.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
          showPolygon: false, // Set to true if you want to highlight clusters with a polygon
          polygonOptions: PolygonOptions(
            borderColor: Colors.blueAccent,
            color: Colors.black12,
            borderStrokeWidth: 3,
          ),
        ),
      ),
    ],
  );
}


  Widget _photoScreen() {
    return ListView(
      padding: EdgeInsets.all(16.0),
      children: [
        _buildOptionTile('Camera Model', () => _fetchAndDisplayOptions('camera_model')),
        _buildOptionTile('Focal Length', () => _fetchAndDisplayOptions('focal_length')),
        _buildOptionTile('Lens', () => _fetchAndDisplayOptions('lens')),
      ],
    );
  }

  Widget _buildOptionTile(String optionName, Function onTapFunction) {
    return GestureDetector(
      onTap: () {
        onTapFunction();
      },
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(8.0),
        ),
        margin: EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(optionName, style: TextStyle(color: CupertinoColors.black)),
            Icon(CupertinoIcons.chevron_forward, color: CupertinoColors.activeBlue),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchAndDisplayOptions(String exifType) async {
  if (_serverUrl == null || _cookie == null) {
    print('Server URL or cookie is null');
    return;
  }

  try {
    final response = await http.get(
      Uri.parse("$_serverUrl/photoexif?exif_type=$exifType&action=list"),
      headers: {'Cookie': _cookie!},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Ensure all values are converted to strings
      final List<String> options =
          List<String>.from(data['values'].map((value) => value.toString()));

      _showOptionsDialog(exifType, options);
    } else {
      print('Failed to fetch options: ${response.statusCode}');
      _showErrorDialog('Error', 'Failed to fetch options.');
    }
  } catch (e) {
    print('Error fetching options: $e');
    _showErrorDialog('Error', 'Failed to fetch options.');
  }
}


void _showOptionsDialog(String exifType, List<String> options) {
  String? selectedOption; // Track the selected option

  Navigator.push(
    context,
    CupertinoPageRoute(
      builder: (context) => OptionsPage(
        exifType: exifType,
        options: options,
        onOptionSelected: (option) {
          selectedOption = option; // Update the selected option
          Navigator.pop(context); // Close the OptionsPage
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => PhotoGridViewScreen(
                selectedSortingOption: 'new-to-old', // Default sorting option
                exifType: exifType,
                value: selectedOption,
              ),
            ),
          ).then((_) {
            // Return to OptionsPage with the previously selected option
            _showOptionsDialog(exifType, options);
          });
        },
      ),
    ),
  );
}


  Future<void> _fetchPhotosByOption(String exifType, String value) async {
    try {
      final response = await http.get(
        Uri.parse("$_serverUrl/photoexif?exif_type=$exifType&action=photo&value=$value"),
        headers: {'Cookie': _cookie!},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Photos for $exifType=$value: ${data['photos']}');
        // You can navigate to a new screen to display the photos or update the UI here.
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
