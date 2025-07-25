import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/login_page.dart';
import 'pages/mainpage.dart'; // برای هدایت مستقیم به MainPage پس از لاگین

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;
  String? _username;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    if (username != null) {
      setState(() {
        _isLoggedIn = true;
        _username = username;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SinVault',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: _isLoggedIn
          ? MainPage(username: _username)
          : LoginPage(onLoginSuccess: (username) {
              setState(() {
                _isLoggedIn = true;
                _username = username;
              });
            }),
    );
  }
}