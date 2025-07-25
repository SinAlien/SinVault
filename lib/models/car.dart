class Car {
  int? id;
  String owner; // برای شناسایی کاربر، در آینده
  String brand;
  String model;

  Car({this.id, required this.owner, required this.brand, required this.model});

  // تبدیل یک Car به یک Map برای ذخیره در پایگاه داده
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner': owner,
      'brand': brand,
      'model': model,
    };
  }

  // ایجاد یک Car از یک Map که از پایگاه داده خوانده شده است
  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      id: map['id'] as int?,
      owner: map['owner'] as String,
      brand: map['brand'] as String,
      model: map['model'] as String,
    );
  }
}