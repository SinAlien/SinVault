class House {
  int? id;
  String owner; // می‌تواند برای فیلتر کردن خانه‌های هر کاربر در آینده استفاده شود
  String address; // آدرس خانه
  String city; // شهر

  House({this.id, required this.owner, required this.address, required this.city});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner': owner,
      'address': address,
      'city': city,
    };
  }

  factory House.fromMap(Map<String, dynamic> map) {
    return House(
      id: map['id'] as int?,
      owner: map['owner'] as String,
      address: map['address'] as String,
      city: map['city'] as String,
    );
  }
}