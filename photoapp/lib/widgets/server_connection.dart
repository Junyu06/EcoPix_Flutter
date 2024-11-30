import 'package:cupertino_http/cupertino_http.dart';
import 'dart:convert';
import 'db_helper.dart'; // For database interaction

class ServerConnection {
  // Fetch server URL from the database
  Future<String?> getServerUrl() async {
    Map<String, String?> userData = await DbHelper.getCookieAndServer();
    return userData['server']; // Returns the server URL from the database
  }

  Future<List<dynamic>> fetchPhotosAsList() async {
    Map<String, List<String>> photoMap = await fetchPhotos();
    return photoMap.values.expand((list) => list).toList(); // Flatten the map into a list
  }

  // Fetch photos for 100 per time
  Future<Map<String, List<String>>> fetchPhotos() async {
    String? serverUrl = await getServerUrl();
    
    if (serverUrl == null || serverUrl.isEmpty) {
      throw Exception('No server URL found in the database');
    }

    String apiUrl = '$serverUrl/api/photos';
    
    // Use cupertino_http to send the GET request
    final client = CupertinoClient.defaultSessionConfiguration();
    final response = await client.get(
      Uri.parse(apiUrl),
    );

    if (response.statusCode == 200) {
      // Parse the JSON response into a Map
      return Map<String, List<String>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load photos');
    }
  }
}
