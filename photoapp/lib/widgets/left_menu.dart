import 'package:flutter/cupertino.dart'; // Add this import

class LeftMenu extends StatefulWidget {
  final Function onHomePressed;
  final Function onUserPressed;
  final Function onSignOutPressed;
  final Widget content; // Dynamic content passed from HomeScreen

  const LeftMenu({
    required this.onHomePressed,
    required this.onUserPressed,
    required this.onSignOutPressed,
    required this.content,
  });

  @override
  _LeftMenuState createState() => _LeftMenuState();
}

class _LeftMenuState extends State<LeftMenu> {
  bool _isMenuOpen = false; // Track if the menu is open
  final double _menuWidth = 250; // Width of the sliding menu

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        AnimatedPositioned(
          duration: Duration(milliseconds: 250),
          left: _isMenuOpen ? _menuWidth : 0, // Slide content to the right when menu is open
          right: _isMenuOpen ? -_menuWidth : 0, // Adjust right offset when menu is open
          top: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: _isMenuOpen ? _toggleMenu : null, // Close the menu when tapping outside
            child: CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                middle: Text('PhotoApp'),
                leading: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(CupertinoIcons.bars), // Menu icon
                  onPressed: _toggleMenu, // Open/close the menu
                ),
              ),
              child: widget.content, // Show the dynamic content (Home or User)
            ),
          ),
        ),

        // Left Menu
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 250),
            width: _isMenuOpen ? _menuWidth : 0, // Width of the menu
            color: CupertinoColors.systemGrey6, // Menu background color
            child: _isMenuOpen
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CupertinoButton(
                        child: Text('Home'),
                        onPressed: () {
                          widget.onHomePressed();
                          _toggleMenu(); // Close the menu when Home is clicked
                        },
                      ),
                      CupertinoButton(
                        child: Text('User'),
                        onPressed: () {
                          widget.onUserPressed();
                          _toggleMenu(); // Close the menu when User is clicked
                        },
                      ),
                      CupertinoButton(
                        child: Text('Sign Out'),
                        onPressed: () {
                          widget.onSignOutPressed();
                          _toggleMenu(); // Close the menu when Sign Out is clicked
                        },
                      ),
                    ],
                  )
                : Container(), // Empty container when the menu is closed
          ),
        ),
      ],
    );
  }
}
