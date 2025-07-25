// house_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/house.dart';
import '../models/house_contract.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart'; // ایمپورت برای CurrencyInputFormatter

class HouseDetailPage extends StatefulWidget {
  final House house;

  HouseDetailPage({required this.house});

  @override
  _HouseDetailPageState createState() => _HouseDetailPageState();
}

class _HouseDetailPageState extends State<HouseDetailPage> {
  // این Map وضعیت نمایش هر فیلد اصلی را نگه می‌دارد.
  Map<String, bool> _showMainFields = {
    'startDate': true,
    'endDate': true,
    'annualRent': true,
  };

  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController annualRentController = TextEditingController();

  bool _isAdding = false;
  // **تغییر:** اضافه کردن متغیر برای مدیریت حالت ویرایش
  bool _isEditing = false;
  HouseContract? _editingContract; // **تغییر:** نگه داشتن قرارداد در حال ویرایش

  List<HouseContract> _contractRecords = [];
  bool _isLoading = true;

  // برای فیلدهای دینامیک
  List<Map<String, TextEditingController>> _additionalFields = [];

  @override
  void initState() {
    super.initState();
    _fetchContracts();
  }

  @override
  void dispose() {
    startDateController.dispose();
    endDateController.dispose();
    annualRentController.dispose();
    _disposeAdditionalFieldControllers(); // پاک کردن کنترلرهای دینامیک
    super.dispose();
  }

  void _disposeAdditionalFieldControllers() {
    for (var field in _additionalFields) {
      field['key']?.dispose();
      field['value']?.dispose();
    }
  }

  Future<void> _fetchContracts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (widget.house.id != null) {
        final records = await DatabaseHelper().getHouseContractsForHouse(widget.house.id!);
        setState(() {
          _contractRecords = records;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('شناسه خانه در دسترس نیست.')),
        );
      }
    } catch (e) {
      print('خطا در دریافت قراردادها: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در بارگذاری قراردادها.')),
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

  // **تغییر:** تابع برای حذف فیلدهای اضافی
  void _removeAdditionalField(int index) {
    setState(() {
      _additionalFields[index]['key']?.dispose();
      _additionalFields[index]['value']?.dispose();
      _additionalFields.removeAt(index);
    });
  }

  // **تغییر:** تابع برای آماده‌سازی فرم برای ویرایش
  void _startEditingContract(HouseContract contract) {
    setState(() {
      _isEditing = true;
      _isAdding = true; // نمایش فرم ویرایش
      _editingContract = contract;

      // پر کردن فیلدهای اصلی
      startDateController.text = contract.startDate;
      endDateController.text = contract.endDate;
      annualRentController.text = contract.annualRent; // اکنون String است

      // پر کردن فیلدهای اضافی
      _disposeAdditionalFieldControllers(); // پاک کردن کنترلرهای قبلی
      _additionalFields.clear();
      if (contract.additionalFields != null) {
        contract.additionalFields!.forEach((key, value) {
          _additionalFields.add({
            'key': TextEditingController(text: key),
            'value': TextEditingController(text: value),
          });
        });
      }

      // **تغییر:** تنظیم مجدد وضعیت نمایش فیلدهای اصلی برای فرم ویرایش
      _showMainFields = {
        'startDate': true,
        'endDate': true,
        'annualRent': true,
      };
    });
  }

  // **تغییر:** تابع برای اضافه کردن/به‌روزرسانی قرارداد
  Future<void> _saveContract() async {
    final startDate = startDateController.text.trim();
    final endDate = endDateController.text.trim();
    final annualRentString = annualRentController.text.trim(); // الان String است

    // **تغییر:** بررسی اینکه آیا فیلدهای اصلی که نمایش داده می‌شوند، پر شده‌اند.
    if (_showMainFields['startDate']! && startDate.isEmpty ||
        _showMainFields['endDate']! && endDate.isEmpty ||
        _showMainFields['annualRent']! && annualRentString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لطفاً فیلدهای اصلی قرارداد را پر کنید.')),
      );
      return;
    }

    // اعتبارسنجی مبلغ اجاره: باید یک عدد معتبر باشد (پس از حذف کاما)
    final cleanAnnualRentString = annualRentString.replaceAll(',', '');
    if (_showMainFields['annualRent']! && (cleanAnnualRentString.isEmpty || double.tryParse(cleanAnnualRentString) == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('اجاره سالیانه باید یک عدد معتبر باشد.')),
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
      if (_isEditing && _editingContract != null) {
        // **تغییر:** به‌روزرسانی قرارداد موجود
        final updatedContract = HouseContract(
          id: _editingContract!.id,
          houseId: widget.house.id!,
          // **تغییر:** فقط فیلدهایی که نمایش داده می‌شوند و پر شده‌اند را استفاده کنید.
          startDate: _showMainFields['startDate']! ? startDate : _editingContract!.startDate,
          endDate: _showMainFields['endDate']! ? endDate : _editingContract!.endDate,
          annualRent: _showMainFields['annualRent']! ? annualRentString : _editingContract!.annualRent, // اکنون String است
          additionalFields: currentAdditionalFields.isNotEmpty ? currentAdditionalFields : null,
        );
        await DatabaseHelper().updateHouseContract(updatedContract);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('قرارداد با موفقیت به‌روزرسانی شد!')),
        );
      } else {
        // **تغییر:** افزودن قرارداد جدید
        final newContract = HouseContract(
          houseId: widget.house.id!,
          startDate: startDate,
          endDate: endDate,
          annualRent: annualRentString, // اکنون String است
          additionalFields: currentAdditionalFields.isNotEmpty ? currentAdditionalFields : null,
        );
        await DatabaseHelper().insertHouseContract(newContract);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('قرارداد با موفقیت ثبت شد!')),
        );
      }

      _resetForm(); // **تغییر:** بازنشانی فرم پس از ذخیره

      _fetchContracts(); // Refresh the list
    } catch (e) {
      print('خطا در ذخیره/به‌روزرسانی قرارداد: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ذخیره/به‌روزرسانی قرارداد.')),
      );
    }
  }

  // **تغییر:** تابع برای بازنشانی فرم
  void _resetForm() {
    startDateController.clear();
    endDateController.clear();
    annualRentController.clear();
    _disposeAdditionalFieldControllers();
    _additionalFields.clear();
    setState(() {
      _isAdding = false;
      _isEditing = false; // **تغییر:** تنظیم حالت ویرایش به false
      _editingContract = null; // **تغییر:** خالی کردن قرارداد در حال ویرایش
      // **تغییر:** بازنشانی وضعیت نمایش فیلدهای اصلی
      _showMainFields = {
        'startDate': true,
        'endDate': true,
        'annualRent': true,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.house.address} - جزئیات'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('شهر: ${widget.house.city}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _contractRecords.isEmpty
                      ? Center(child: Text('هیچ قراردادی ثبت نشده است.'))
                      : ListView.builder(
                          itemCount: _contractRecords.length,
                          itemBuilder: (context, index) {
                            final contract = _contractRecords[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 6),
                              elevation: 2,
                              child: ListTile(
                                leading: Icon(Icons.description),
                                title: Text('اجاره: ${contract.annualRent} تومان'), // اکنون String است
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('شروع: ${contract.startDate} - پایان: ${contract.endDate}'),
                                    if (contract.additionalFields != null &&
                                        contract.additionalFields!.isNotEmpty)
                                      ...contract.additionalFields!.entries
                                          .map((entry) => Text('${entry.key}: ${entry.value}'))
                                          .toList(),
                                  ],
                                ),
                                // **تغییر:** اضافه کردن دکمه ویرایش در کنار دکمه حذف
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.blueAccent),
                                      onPressed: () {
                                        _startEditingContract(contract);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () async {
                                        if (contract.id != null) {
                                          await DatabaseHelper().deleteHouseContract(contract.id!);
                                          _fetchContracts(); // Refresh the list after deletion
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('قرارداد حذف شد.')),
                                          );
                                        }
                                      },
                                    ),
                                  ],
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
                  label: Text('افزودن قرارداد'),
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
                      if (_showMainFields['startDate']!)
                        TextField(
                          controller: startDateController,
                          decoration: InputDecoration(labelText: 'تاریخ شروع (مثلاً 1402/01/01)'),
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),
                      SizedBox(height: 8),
                      if (_showMainFields['endDate']!)
                        TextField(
                          controller: endDateController,
                          decoration: InputDecoration(labelText: 'تاریخ پایان (مثلاً 1403/01/01)'),
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),
                      SizedBox(height: 8),
                      if (_showMainFields['annualRent']!)
                        TextField(
                          controller: annualRentController,
                          decoration: InputDecoration(labelText: 'مبلغ اجاره ماهیانه (به تومان)'),
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
                      ..._additionalFields.asMap().entries.map((entry) {
                        int idx = entry.key;
                        Map<String, TextEditingController> field = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: field['key'],
                                  decoration: InputDecoration(labelText: 'نام فیلد'),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: field['value'],
                                  decoration: InputDecoration(labelText: 'توضیحات'),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => _removeAdditionalField(idx),
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
                            onPressed: _resetForm,
                            child: Text('لغو'),
                          ),
                          SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _saveContract,
                            child: Text(_isEditing ? 'به‌روزرسانی' : 'ثبت'),
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
}