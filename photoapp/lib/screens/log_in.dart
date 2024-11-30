import 'package:flutter/cupertino.dart';
import 'package:photoapp/main.dart';
import 'package:photoapp/widgets/widgets.dart';
import 'package:photoapp/screens/home_screen.dart';

//import 'home_screen'; // homscreen after login

//import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _serverAddressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkForCookie();
  }

  // Check if the user has a valid cookie saved in the database and validate it with the Flask server
  Future<void> _checkForCookie() async {
    setState(() {
      _isLoading = true;
    });

    Map<String, String?> data = await DbHelper.getCookieAndServer();
    String? cookie = data['cookie'];
    String? server = data['server'];

    if (cookie != null && server != null) {
      final response = await http.get(
        Uri.parse('$server/protected'),
        headers: {'Cookie': '$cookie'},
      );

      if (response.statusCode == 200) {
        // If the server confirms the cookie is valid, navigate to the HomeScreen
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (context) => HomeScreen()),
        );
        return;
      }
    }

    // If the cookie is invalid or no server is available, show the login form
    setState(() {
      _isLoading = false;
    });
  }

  // Log in to the Flask server and save the cookie
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final server = _serverAddressController.text;
    final username = _usernameController.text;
    final password = _passwordController.text;

    final response = await http.post(
      Uri.parse('$server/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      // Extract the cookie from the response
      final cookie = response.headers['set-cookie'];
      if (cookie != null) {
        final sessionCookie = cookie.split(';').firstWhere((cookie) => cookie.startsWith('session='));
        // Save the cookie and server address locally
        await DbHelper.saveCookieAndServer(sessionCookie, server);
        print("Session cookie saved: $sessionCookie");

        // Navigate to the HomeScreen
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (context) => HomeScreen()),
        );
        return;
      }
    }

    // If login fails, show an error
    setState(() {
      _isLoading = false;
    });
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Login Failed'),
        content: Text('Invalid username or password.'),
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
        middle: Text('Login'),
      ),
      child: _isLoading
          ? Center(
              child: CupertinoActivityIndicator(),
            ) // Show loading spinner
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoTextField(
                    controller: _usernameController,
                    placeholder: 'Username',
                  ),
                  SizedBox(height: 16.0),
                  CupertinoTextField(
                    controller: _passwordController,
                    placeholder: 'Password',
                  ),
                  SizedBox(height: 16.0),
                  CupertinoTextField(
                    controller: _serverAddressController,
                    placeholder: 'Server Address',
                  ),
                  SizedBox(height: 32.0),
                  CupertinoButton.filled(
                    child: Text('Login'),
                    onPressed: _login,
                  ),
                ],
              ),
            ),
    );
  }
}
