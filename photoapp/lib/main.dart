import 'package:flutter/cupertino.dart';
import 'screens/log_in.dart'; // Import your login screen

void main() async {
  runApp(PhotoManagementApp());
}

class PhotoManagementApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: LoginScreen(), // Start with the LoginScreen
    );
  }
}
