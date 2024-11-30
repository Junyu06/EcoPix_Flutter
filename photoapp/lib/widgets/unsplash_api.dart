import 'dart:convert';
import 'package:cupertino_http/cupertino_http.dart';

class ServerConnection {
  final String _baseUrl = 'https://api.unsplash.com/photos/';
  final String _clientId = 'X9BdQ31m-6SPxQrzmN26DFTltjeY_yjOLzKI1yneI0Q';
  //final String _per_page = '2';//set # the per page 

  // Method to fetch photos from Unsplash API
  Future<List<dynamic>> fetchPhotos(int _page, int _per_page) async {
    try {
      final client = CupertinoClient.defaultSessionConfiguration();
      final Uri url = Uri.parse('$_baseUrl?client_id=$_clientId&per_page=$_per_page&page=$_page');
      
      final response = await client.get(url);

      if (response.statusCode == 200) {
        // Decode the JSON response
        final List<dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to load photos');
      }
    } catch (error) {
      print('Error fetching data: $error');
      throw Exception('Error fetching data: $error');
    }
  }

/*
  Future<List<dynamic>> fetchPhotos({required int perPage, required int page}) async {
    try {
      final url = "$_baseUrl?client_id=YOUR_ACCESS_KEY&per_page=$perPage&page=$page";
      final response = await CupertinoClient().get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load photos');
      }
    } catch (e) {
      print('Error fetching data: $e');
      throw e;
    }
  }
  */
}
