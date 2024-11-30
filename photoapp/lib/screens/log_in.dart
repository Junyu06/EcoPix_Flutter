import 'package:flutter/cupertino.dart';
import 'package:photoapp/main.dart';
import 'package:photoapp/widgets/widgets.dart';
import 'package:photoapp/screens/home_screen.dart';

//import 'home_screen'; // homscreen after login

class LoginScreen extends StatefulWidget{
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>{
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _serverAddressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState(){
    super.initState();
    _checkForCookie();
  }

  //check if the user has a valid cookie saved in the database
  Future<void> _checkForCookie() async{
    setState(() {
      _isLoading = true;
    });

    Map<String, String?> data = await DbHelper.getCookieAndServer();
    String? cookie = data['cookie'];
    String? server = data['server'];

    if (cookie != null && await _validatedCookie(cookie)){
      Navigator.pushReplacement(
        context, 
        CupertinoPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      setState(() {
        _isLoading = false; //show login from if cookie is invalid
      });
    }
  }

  //dummy cookie validation (replace with real connetion after)
  Future<bool> _validatedCookie(String cookie) async {
    await Future.delayed(Duration(seconds: 1));
    return cookie == "valid_cookie";
  }

  //simulate login and save coockie and server add in the db
  Future<void> _login() async{
    setState(() {
      _isLoading = true;
    });

    await Future.delayed((Duration(seconds:1)));
    await DbHelper.saveCookieAndServer("valid_cookie", _serverAddressController.text);

    //navigae to the home screen
    Navigator.pushReplacement(
      context, 
      CupertinoPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context){
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Login'),
      ),
      child: _isLoading
        ? Center(child:  CupertinoActivityIndicator(),)//show loading spinner
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoTextField(
                  controller: _usernameController,
                  placeholder: 'Username',
                ),
                SizedBox(height: 16.0,),
                CupertinoTextField(
                  controller: _passwordController,
                  placeholder: 'Password',
                ),
                SizedBox(height: 16.0,),
                CupertinoTextField(
                  controller: _serverAddressController,
                  placeholder: 'Server Address',
                ),
                SizedBox(height: 32.0,),
                CupertinoButton.filled(
                  child: Text('Login'), 
                  onPressed: _login,
                ),
              ],
            ),
        )
    );
  }
}