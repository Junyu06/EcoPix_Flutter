import 'package:cupertino_http/cupertino_http.dart';
import 'dart:convert';
import 'db_helper.dart';

class ServerConnection {
  Future<String?> getServerUrl() async {
    Map<String, String?> userData = await DbHelper.getCookieAndServer();
    return userData['server'];
  }

  Future<String?> getSessionCookie() async {
    Map<String, String?> userData = await DbHelper.getCookieAndServer();
    return userData['cookie']; // Retrieve the session cookie
  }

  Future<List<dynamic>> fetchPhotoList({int page = 1, int perPage = 20, String order = 'new-to-old'}) async {
    String? serverUrl = await getServerUrl();
    String? cookie = await getSessionCookie();

    if (serverUrl == null || serverUrl.isEmpty || cookie == null) {
      throw Exception('Server URL or session cookie is missing');
    }

    String apiUrl = '$serverUrl/photo/list?page=$page&per_page=$perPage&order=$order';

    final client = CupertinoClient.defaultSessionConfiguration();
    final response = await client.get(
      Uri.parse(apiUrl),
      headers: {'Cookie': cookie}, // Include the session cookie
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['photos'];
    } else {
      throw Exception('Failed to load photos: ${response.statusCode}');
    }
  }

  // Future<Map<String, dynamic>> fetchPhotoList({int page = 1, int perPage = 20, String order = 'new-to-old'}) async {
  //   String? serverUrl = await getServerUrl();
  //   if (serverUrl == null || serverUrl.isEmpty) {
  //     throw Exception('No server URL found in the database');
  //   }

  //   String apiUrl = '$serverUrl/photo/list?page=$page&per_page=$perPage&order=$order';
  //   print(apiUrl);

  //   final client = CupertinoClient.defaultSessionConfiguration();
  //   final response = await client.get(Uri.parse(apiUrl));

  //   if (response.statusCode == 200) {
  //     return json.decode(response.body); // Response includes photos, total, page, pages, per_page
  //   } else {
  //     throw Exception('Failed to load photos: ${response.statusCode} ${response.body}');
  //   }
  // }
}
