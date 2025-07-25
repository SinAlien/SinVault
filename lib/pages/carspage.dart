import 'package:flutter/material.dart';
import 'car_detail_page.dart';
import '../database/database_helper.dart';
import '../models/car.dart'; // import مدل Car

class CarsPage extends StatefulWidget {
  @override
  _CarsPageState createState() => _CarsPageState();
}

class _CarsPageState extends State<CarsPage> {
  List<Car> carList = [];
  bool _isLoading = true;
  bool showForm = false;

  final TextEditingController brandController = TextEditingController(); // تغییر به brand
  final TextEditingController modelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCars();
  }

  @override
  void dispose() {
    brandController.dispose();
    modelController.dispose();
    super.dispose();
  }

  Future<void> _fetchCars() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final cars = await DatabaseHelper().getCars();
      setState(() {
        carList = cars;
        _isLoading = false;
      });
    } catch (e) {
      print('خطا در دریافت خودروها: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در بارگذاری خودروها.')),
      );
    }
  }

  Future<void> _submitCar() async {
    final brand = brandController.text.trim();
    final model = modelController.text.trim();
    
    if (brand.isEmpty || model.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لطفاً نام برند و مدل خودرو را وارد کنید.')),
      );
      return;
    }

    try {
      final newCar = Car(owner: 'user1', brand: brand, model: model); // owner فعلا ثابت است
      await DatabaseHelper().insertCar(newCar);
      brandController.clear();
      modelController.clear();
      setState(() {
        showForm = false;
      });
      _fetchCars(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خودرو با موفقیت اضافه شد!')),
      );
    } catch (e) {
      print('خطا در ارسال خودرو: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ذخیره خودرو.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('مدیریت خودروها')),
      body: Column(
        children: [
          if (showForm) ...[
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: brandController,
                decoration: InputDecoration(labelText: 'برند خودرو'), // تغییر لیبل
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: modelController,
                decoration: InputDecoration(labelText: 'مدل خودرو'),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _submitCar,
                  child: Text('ثبت خودرو'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showForm = false;
                      brandController.clear();
                      modelController.clear();
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
                : carList.isEmpty
                    ? Center(child: Text('هیچ خودرویی ثبت نشده است.'))
                    : ListView.builder(
                        itemCount: carList.length,
                        itemBuilder: (context, index) {
                          final car = carList[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            elevation: 2,
                            child: ListTile(
                              title: Text('خودرو: ${car.brand}'),
                              subtitle: Text('مدل: ${car.model}'),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () async {
                                  if (car.id != null) {
                                    await DatabaseHelper().deleteCar(car.id!);
                                    _fetchCars(); // Refresh the list after deletion
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('خودرو حذف شد.')),
                                    );
                                  }
                                },
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CarDetailPage(car: car), // پاس دادن مدل Car
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          )
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