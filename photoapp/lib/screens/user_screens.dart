import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:photoapp/widgets/widgets.dart';
import 'dart:convert';
import 'package:photoapp/screens/home_screen.dart';

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  String? message; // Message to display on the screen
  bool isLoading = true; // To handle loading state

  @override
  void initState() {
    super.initState();
    _fetchProtectedData();
  }

  // Fetch data from the /protected route
  Future<void> _fetchProtectedData() async {
    Map<String, String?> data = await DbHelper.getCookieAndServer();
    String? cookie = data['cookie'];
    String? server = data['server'];

    if (cookie != null && server != null) {
      final response = await http.get(
        Uri.parse('$server/protected'),
        headers: {'Cookie': cookie},
      );

      if (response.statusCode == 200) {
        // Parse the response body
        final responseData = jsonDecode(response.body);

        setState(() {
          message = responseData['message']; // Update the message with the response
          isLoading = false; // Stop loading
        });
      } else {
        setState(() {
          message = "Unauthorized access. cookie is = $cookie";
          isLoading = false;
        });
      }
    }
  }

  // Trigger the /photo/index API route
  Future<void> _startIndexing(BuildContext context) async {
    try {
      // Retrieve server URL and cookie
      Map<String, String?> data = await DbHelper.getCookieAndServer();
      String? cookie = data['cookie'];
      String? server = data['server'];

      if (server == null || cookie == null) {
        _showAlert(context, 'Error', 'Server or cookie not set.');
        return;
      }

      // Call the /photo/index API
      final response = await http.get(
        Uri.parse('$server/photo/index'),
        headers: {'Cookie': cookie},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _showAlert(context, 'Success', responseData['message']);
      } else {
        final responseData = jsonDecode(response.body);
        _showAlert(context, 'Error', responseData['message']);
      }
    } catch (e) {
      _showAlert(context, 'Error', 'Failed to connect to server.');
    }
  }

  // Show a dialog with a message
  void _showAlert(BuildContext context, String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('User Screen'),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isLoading)
            CupertinoActivityIndicator() // Show a loading spinner while fetching data
          else
            Text(message ?? 'No content available'), // Show the fetched message

          SizedBox(height: 20), // Add spacing between the text and the button

          CupertinoButton.filled(
            child: Text('Start Indexing'),
            onPressed: () => _startIndexing(context),
          ),
        ],
      ),
    );
  }
}