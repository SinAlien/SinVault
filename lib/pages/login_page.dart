import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mainpage.dart';

class LoginPage extends StatefulWidget {
  final Function(String) onLoginSuccess; // Callback برای اطلاع رسانی لاگین موفق

  LoginPage({required this.onLoginSuccess});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final Map<String, String> allowedUsers = {
    'Sina': 'Sina',
    'Feri': 'Feri',
    'User': 'pass',
    'user4': 'pass4',
  };

  void _login() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (allowedUsers.containsKey(username) &&
        allowedUsers[username] == password) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username); // ذخیره نام کاربری
      widget.onLoginSuccess(username); // اطلاع رسانی به MyApp
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainPage(username: username),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("نام کاربری یا رمز عبور اشتباه است"),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ورود")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'نام کاربری'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'رمز عبور'),
              obscureText: true,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _login,
              child: Text('ورود'),
            ),
          ],
        ),
      ),
    );
  }
}