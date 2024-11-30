import 'package:flutter/cupertino.dart';
import 'package:photoapp/screens/log_in.dart'; 
import 'package:photoapp/widgets/widgets.dart'; 
import 'package:photoapp/screens/user_screens.dart';


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool showHome = true; // Control whether to show Home or User

  void switchToHome() {
    setState(() {
      showHome = true; // Show Home content
    });
  }

  void switchToUser() {
    setState(() {
      showHome = false; // Show User content
    });
  }

  @override
  Widget build(BuildContext context) {
    return LeftMenu(
      onHomePressed: switchToHome, // Switch to Home
      onUserPressed: switchToUser,  // Switch to User
      onSignOutPressed: () async {
        await DbHelper.clearCookieAndServer();
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (context) => LoginScreen()), // Navigate to Login screen
        );
      },
      content: showHome ? TabBarWidget() : UserScreen(), // Switch content dynamically
    );
  }
}
