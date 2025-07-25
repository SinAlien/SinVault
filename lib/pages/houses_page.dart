import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/house.dart';
import 'house_detail_page.dart'; // <--- اضافه شده


class HousesPage extends StatefulWidget {
  @override
  _HousesPageState createState() => _HousesPageState();
}

class _HousesPageState extends State<HousesPage> {
  List<House> houseList = [];
  bool _isLoading = true;
  bool showForm = false;

  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchHouses();
  }

  @override
  void dispose() {
    addressController.dispose();
    cityController.dispose();
    super.dispose();
  }

  Future<void> _fetchHouses() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final houses = await DatabaseHelper().getHouses();
      setState(() {
        houseList = houses;
        _isLoading = false;
      });
    } catch (e) {
      print('خطا در دریافت خانه‌ها: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در بارگذاری خانه‌ها.')),
      );
    }
  }

  Future<void> _submitHouse() async {
    final address = addressController.text.trim();
    final city = cityController.text.trim();

    if (address.isEmpty || city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لطفاً آدرس و شهر را وارد کنید.')),
      );
      return;
    }

    try {
      final newHouse = House(owner: 'user1', address: address, city: city); // owner فعلا ثابت
      await DatabaseHelper().insertHouse(newHouse);
      addressController.clear();
      cityController.clear();
      setState(() {
        showForm = false;
      });
      _fetchHouses(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خانه با موفقیت اضافه شد!')),
      );
    } catch (e) {
      print('خطا در ارسال خانه: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ذخیره خانه.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('مدیریت خانه‌ها')),
      body: Column(
        children: [
          if (showForm) ...[
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: addressController,
                decoration: InputDecoration(labelText: 'آدرس خانه'),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: cityController,
                decoration: InputDecoration(labelText: 'شهر'),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _submitHouse,
                  child: Text('ثبت خانه'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showForm = false;
                      addressController.clear();
                      cityController.clear();
                    });
                  },
                  child: Text('لغو'),
                ),
              ],
            ),
            SizedBox(height: 16),
          ],
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : houseList.isEmpty
                    ? Center(child: Text('هیچ خانه‌ای ثبت نشده است.'))
                    : ListView.builder(
                        itemCount: houseList.length,
                        itemBuilder: (context, index) {
                          final house = houseList[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            elevation: 2,
                            child: ListTile(
                              title: Text('خانه: ${house.address}'),
                              subtitle: Text('شهر: ${house.city}'),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () async {
                                  if (house.id != null) {
                                    await DatabaseHelper().deleteHouse(house.id!);
                                    _fetchHouses(); // Refresh the list after deletion
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('خانه حذف شد.')),
                                    );
                                  }
                                },
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HouseDetailPage(house: house),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            showForm = !showForm;
          });
        },
        child: Icon(showForm ? Icons.close : Icons.add),
      ),
    );
  }
}