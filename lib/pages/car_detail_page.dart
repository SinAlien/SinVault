// car_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/car.dart';
import '../models/service_record.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart'; // مطمئن شوید این ایمپورت هست

class CarDetailPage extends StatefulWidget {
  final Car car; // دریافت مدل Car به جای Map

  CarDetailPage({required this.car});

  @override
  _CarDetailPageState createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  final TextEditingController actionController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController kmController = TextEditingController();

  bool _isAdding = false;
  List<ServiceRecord> _historyRecords = [];
  bool _isLoading = true;

  // برای فیلدهای دینامیک
  List<Map<String, TextEditingController>> _additionalFields = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  @override
  void dispose() {
    actionController.dispose();
    dateController.dispose();
    kmController.dispose();
    _disposeAdditionalFieldControllers(); // پاک کردن کنترلرهای دینامیک
    super.dispose();
  }

  void _disposeAdditionalFieldControllers() {
    for (var field in _additionalFields) {
      field['key']?.dispose();
      field['value']?.dispose();
    }
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (widget.car.id != null) {
        final records = await DatabaseHelper().getServiceRecordsForCar(widget.car.id!);
        setState(() {
          _historyRecords = records;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('شناسه خودرو در دسترس نیست.')),
        );
      }
    } catch (e) {
      print('خطا در دریافت تاریخچه: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در بارگذاری تاریخچه.')),
      );
    }
  }

  // اضافه کردن یک فیلد اضافی جدید
  void _addAdditionalField() {
    setState(() {
      _additionalFields.add({
        'key': TextEditingController(),
        'value': TextEditingController(),
      });
    });
  }

  Future<void> _addRecord() async {
    final action = actionController.text.trim();
    final date = dateController.text.trim();
    final kmString = kmController.text.trim(); // kmString حال حاوی کاما است

    if (action.isEmpty || date.isEmpty || kmString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لطفاً همه فیلدها را پر کنید.')),
      );
      return;
    }

    // بررسی صحت ورودی کیلومتر: باید فقط شامل اعداد و کاما باشد
    final cleanKmString = kmString.replaceAll(',', '');
    // از آنجایی که kilometer در مدل ServiceRecord به String تغییر کرده،
    // نیازی به int.tryParse برای ذخیره‌سازی نیست.
    // اما برای اعتبارسنجی ورودی کاربر، منطقی است که بررسی کنیم آیا این یک عدد معتبر است.
    if (cleanKmString.isEmpty || int.tryParse(cleanKmString) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('کیلومتر باید یک عدد معتبر باشد.')),
      );
      return;
    }

    // جمع‌آوری فیلدهای اضافی
    Map<String, String> currentAdditionalFields = {};
    for (var field in _additionalFields) {
      final key = field['key']!.text.trim();
      final value = field['value']!.text.trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        currentAdditionalFields[key] = value;
      }
    }

    try {
      final newRecord = ServiceRecord(
        carId: widget.car.id!,
        date: date,
        kilometer: kmString, // اینجا kmString را مستقیماً ذخیره می‌کنید (که شامل کاماهاست)
        operation: action,
      );
      await DatabaseHelper().insertServiceRecord(newRecord);
      actionController.clear();
      dateController.clear();
      kmController.clear();
      _disposeAdditionalFieldControllers(); // پاک کردن کنترلرهای فیلدهای دینامیک
      _additionalFields.clear(); // پاک کردن لیست فیلدهای دینامیک

      setState(() {
        _isAdding = false;
      });
      _fetchHistory(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('عملیات با موفقیت ثبت شد!')),
      );
    } catch (e) {
      print('خطا در ارسال رکورد: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ذخیره عملیات.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.car.brand} ${widget.car.model} - جزئیات'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('مدل: ${widget.car.model}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _historyRecords.isEmpty
                      ? Center(child: Text('هیچ رکوردی ثبت نشده است.'))
                      : ListView.builder(
                          itemCount: _historyRecords.length,
                          itemBuilder: (context, index) {
                            final record = _historyRecords[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 6),
                              elevation: 2,
                              child: ListTile(
                                leading: Icon(Icons.build),
                                title: Text(record.operation),
                                // کیلومتر به صورت String با کاما نمایش داده می‌شود
                                subtitle: Text('${record.date} - کیلومتر: ${record.kilometer}'),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () async {
                                    if (record.id != null) {
                                      await DatabaseHelper().deleteServiceRecord(record.id!);
                                      _fetchHistory(); // Refresh the list after deletion
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('عملیات حذف شد.')),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
            if (!_isAdding)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('افزودن عملیات'),
                  onPressed: () {
                    setState(() {
                      _isAdding = true;
                    });
                  },
                ),
              ),
            if (_isAdding)
              Card(
                margin: EdgeInsets.only(top: 12),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: actionController,
                        decoration: InputDecoration(labelText: 'نوع عملیات'),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: dateController,
                        decoration: InputDecoration(labelText: 'تاریخ عملیات (مثلاً 1402/04/30)'),
                        keyboardType: TextInputType.text,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: kmController,
                        decoration: InputDecoration(labelText: 'کیلومتر خودرو'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          CurrencyInputFormatter(
                            thousandSeparator: ThousandSeparator.Comma,
                            mantissaLength: 0, // این خط باعث می‌شود اعشار .00 اضافه نشود
                            leadingSymbol: '', // حذف نماد ارز از ابتدا
                            trailingSymbol: '', // حذف نماد ارز از انتها
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // فیلدهای دینامیک
                      ..._additionalFields.map((field) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: field['key'],
                                  decoration: InputDecoration(labelText: 'نام فیلد (مثلاً "توضیحات بیشتر")'),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: field['value'],
                                  decoration: InputDecoration(labelText: 'توضیحات بیشتری'),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      // دکمه افزودن فیلد جدید
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: Icon(Icons.add_circle_outline),
                          label: Text('افزودن فیلد بیشتر'),
                          onPressed: _addAdditionalField,
                        ),
                      ),
                      SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              _resetForm(); // استفاده از تابع بازنشانی فرم
                            },
                            child: Text('لغو'),
                          ),
                          SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _addRecord,
                            child: Text('ثبت'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // تابع کمکی برای بازنشانی فرم
  void _resetForm() {
    actionController.clear();
    dateController.clear();
    kmController.clear();
    _disposeAdditionalFieldControllers();
    _additionalFields.clear();
    setState(() {
      _isAdding = false;
    });
  }
}