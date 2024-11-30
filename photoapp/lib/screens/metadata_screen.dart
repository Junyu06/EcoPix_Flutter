import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MetadataScreen extends StatefulWidget {
  @override
  _MetadataScreen createState() => _MetadataScreen();
}

class _MetadataScreen extends State<MetadataScreen> {
  String _selectedSegment = 'Folder'; // Tracks the current selection
  String _selectedSortingOption = 'random'; // Default sorting option

  // Display the box for each album
  Widget _buildAlbumBox(String _foldername) {
    return GestureDetector(
      onTap: () {
        //_openFolder(_foldername); // Open the album when tapped
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
          Text(_foldername, style: TextStyle(color: CupertinoColors.black)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: CupertinoSegmentedControl<String>(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          children: {
            'Folder': Text(' GPS '),
            'Photo': Text(' EXIF '),
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
            _showSortingOptions(context); // Show sorting options
          },
        ),
      ),
      child: SafeArea(
        child: _buildContent(), // Build the content based on the selected segment
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedSegment == 'Folder') {
      return _folderScreen(); // Show folder content
    } else {
      return _photoScreen(); // Show photo content
    }
  }

  Widget _folderScreen() {
    return FlutterMap(
    options: MapOptions(
      initialCenter: LatLng(51.509364, -0.128928), // Center the map over London
      initialZoom: 9.2,
    ),
    children: [
      TileLayer( // Display map tiles from any source
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // OSMF's Tile Server
        userAgentPackageName: 'com.example.app',
        // And many more recommended properties!
      ),
      RichAttributionWidget( // Include a stylish prebuilt attribution widget that meets all requirments
        attributions: [
          TextSourceAttribution(
            'OpenStreetMap contributors',
            onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')), // (external)
          ),
          // Also add images...
        ],
      ),
    ],
  );
  }

  Widget _buildOptionTile(String optionName, Function onTapFunction) {
    return GestureDetector(
      onTap: () {
        onTapFunction(); // Call the respective function when tapped
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

  Widget _photoScreen() {
    return ListView(
      padding: EdgeInsets.all(16.0),
      children: [
        _buildOptionTile('Camera Model', _showCameraModel),
        _buildOptionTile('Focal Length', _showFocalLength),
        _buildOptionTile('Lens', _showLens),
      ],
    );
  }

  // Function for Camera Model page
  void _showCameraModel() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => _detailScreen('Camera Model'),
      ),
    );
  }

  // Function for Focal Length page
  void _showFocalLength() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => _detailScreen('Focal Length'),
      ),
    );
  }

  // Function for Lens page
  void _showLens() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => _detailScreen('Lens'),
      ),
    );
  }

  Widget _detailScreen(String detailType) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(detailType),
      ),
      child: SafeArea(
        child: Center(
          child: Text('Details for $detailType will be displayed here'),
        ),
      ),
    );
  }

  // Function to show sorting options using CupertinoActionSheet
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
