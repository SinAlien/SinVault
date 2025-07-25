// service_record.dart
class ServiceRecord {
  int? id;
  int carId; // کلید خارجی برای لینک کردن به Car
  String date;
  String kilometer; // تغییر نوع به String
  String operation;

  ServiceRecord({this.id, required this.carId, required this.date, required this.kilometer, required this.operation});

  // تبدیل یک ServiceRecord به یک Map برای ذخیره در پایگاه داده
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'carId': carId,
      'date': date,
      'kilometer': kilometer, // به عنوان String ذخیره می‌شود
      'operation': operation,
    };
  }

  // ایجاد یک ServiceRecord از یک Map
  factory ServiceRecord.fromMap(Map<String, dynamic> map) {
    return ServiceRecord(
      id: map['id'] as int?,
      carId: map['carId'] as int,
      date: map['date'] as String,
      kilometer: map['kilometer'] as String, // به عنوان String خوانده می‌شود
      operation: map['operation'] as String,
    );
  }
}