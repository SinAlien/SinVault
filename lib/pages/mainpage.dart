import 'package:flutter/material.dart';
import 'carspage.dart';
import 'houses_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'dart:io' show exit; // برای خروج کامل از اپلیکیشن

class MainPage extends StatelessWidget {
  final String? username;

  MainPage({this.username});

  // تابع لاگ اوت (برگشت به صفحه لاگین)
  void _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('username'); // پاک کردن نام کاربری
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage(onLoginSuccess: (username){})),
    );
  }

  // تابع خروج کامل از اپلیکیشن (اختیاری)
  void _exitApp(BuildContext context) {
    // در اندروید و iOS، این کار باعث بسته شدن کامل اپ می‌شود.
    // در محیط توسعه (IDE) ممکن است تنها برنامه را از دیباگ خارج کند.
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('خروج از برنامه'),
          content: Text('آیا مطمئن هستید که می‌خواهید از برنامه خارج شوید؟'),
          actions: <Widget>[
            TextButton(
              child: Text('خیر'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // بستن دیالوگ
              },
            ),
            TextButton(
              child: Text('بله'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // بستن دیالوگ
                exit(0); // خروج کامل
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'سین‌ولت', // نام برنامه خود را اینجا قرار دهید
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true, // عنوان در وسط قرار گیرد
        elevation: 4, // کمی سایه برای AppBar
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'خروج از حساب کاربری', // توضیحات برای دکمه
          ),
          // اضافه کردن دکمه خروج کامل از اپلیکیشن
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => _exitApp(context),
            tooltip: 'خروج کامل از برنامه',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0), // پدینگ کلی برای محتوا
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch, // دکمه‌ها عرض کامل را بگیرند
            children: [
              // متن خوش‌آمدگویی
              if (username != null)
                Text(
                  'سلام، ${username ?? 'کاربر عزیز'} 👋', // اگر username نال بود، 'کاربر عزیز' نمایش داده شود
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor, // استفاده از رنگ اصلی تم
                  ),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 40), // فاصله بیشتر بعد از خوش‌آمدگویی

              // دکمه مدیریت خودروها
              _buildFeatureButton(
                context,
                icon: Icons.directions_car,
                text: 'مدیریت خودروها',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CarsPage()),
                  );
                },
              ),
              SizedBox(height: 20), // فاصله بین دکمه‌ها

              // دکمه مدیریت خانه‌ها
              _buildFeatureButton(
                context,
                icon: Icons.home,
                text: 'مدیریت خانه‌ها',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HousesPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // تابع کمکی برای ساخت دکمه‌های ویژگی‌ها
  Widget _buildFeatureButton(BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 6, // سایه بیشتر برای برجسته‌تر شدن
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // گوشه‌های گردتر
      ),
      child: InkWell( // برای افکت ریپل هنگام کلیک
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36, // آیکون بزرگتر
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(width: 16),
              Text(
                text,
                style: TextStyle(
                  fontSize: 22, // متن بزرگتر
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}