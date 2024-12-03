import 'package:flutter/cupertino.dart';
import 'package:photoapp/main.dart';
import 'package:photoapp/widgets/db_helper.dart';
import 'package:photoapp/screens/home_screen.dart';
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

  Future<void> _checkForCookie() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, String?> data = await DbHelper.getCookieAndServer();
      String? cookie = data['cookie'];
      String? server = data['server'];

      if (cookie != null && server != null) {
        if (!server.startsWith('http://') && !server.startsWith('https://')) {
          server = 'http://$server'; // Default to http if no protocol is provided
        }

        final response = await http.get(
          Uri.parse('$server/protected'),
          headers: {'Cookie': '$cookie'},
        );

        if (response.statusCode == 200) {
          print("Valid session found. Navigating to HomeScreen.");
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(builder: (context) => HomeScreen()),
          );
          return;
        } else {
          print("Session expired or unauthorized. Status code: ${response.statusCode}");
          await DbHelper.clearCookieAndServer(); // Clear invalid session
        }
      }
    } catch (e) {
      print("Error during cookie validation: $e");
    }

    // If validation fails, stay on the login screen
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    String server = _serverAddressController.text.trim();
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    // Ensure server address is valid
    if (!server.startsWith('http://') && !server.startsWith('https://')) {
      server = 'http://$server'; // Default to http if no protocol is provided
    }

    try {
      final response = await http.post(
        Uri.parse('$server/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final cookie = response.headers['set-cookie'];
        if (cookie != null) {
          final sessionCookie = cookie.split(';').firstWhere((cookie) => cookie.startsWith('session='));
          await DbHelper.saveCookieAndServer(sessionCookie, server);
          print("Session cookie saved: $sessionCookie");

          // Ensure session cookie is available for subsequent requests
          setState(() {
            _serverAddressController.text = server;
          });

          // Introduce a 1-second delay before navigating
          await Future.delayed(Duration(seconds: 1));

          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(builder: (context) => HomeScreen()),
          );
          return;
        }
      }
      _showErrorDialog("Login Failed", "Invalid username or password.");
    } catch (e) {
      print("Error during login: $e");
      _showErrorDialog("Login Error", "Failed to connect to the server. Please check the server address.");
    } finally {
      setState(() {
        _isLoading = false;
      });
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
          ? Center(child: CupertinoActivityIndicator())
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
                    obscureText: true, // Secure the password
                  ),
                  SizedBox(height: 16.0),
                  CupertinoTextField(
                    controller: _serverAddressController,
                    placeholder: 'Server Address (e.g., http://localhost:5000)',
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
