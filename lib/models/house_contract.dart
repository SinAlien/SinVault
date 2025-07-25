// house_contract.dart
class HouseContract {
  int? id;
  int houseId; // کلید خارجی برای لینک کردن به House
  String startDate;
  String endDate;
  String annualRent; // تغییر نوع به String
  Map<String, String>? additionalFields; // برای فیلدهای دینامیک

  HouseContract({
    this.id,
    required this.houseId,
    required this.startDate,
    required this.endDate,
    required this.annualRent,
    this.additionalFields,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'houseId': houseId,
      'startDate': startDate,
      'endDate': endDate,
      'annualRent': annualRent, // به عنوان String ذخیره می‌شود
      'additionalFields': additionalFields != null ? _encodeMap(additionalFields!) : null, // تبدیل Map به String
    };
  }

  factory HouseContract.fromMap(Map<String, dynamic> map) {
    return HouseContract(
      id: map['id'] as int?,
      houseId: map['houseId'] as int,
      startDate: map['startDate'] as String,
      endDate: map['endDate'] as String,
      annualRent: map['annualRent'] as String, // به عنوان String خوانده می‌شود
      additionalFields: map['additionalFields'] != null ? _decodeMap(map['additionalFields'] as String) : null, // تبدیل String به Map
    );
  }

  // توابع کمکی برای تبدیل Map به String و بالعکس برای ذخیره در SQLite
  static String _encodeMap(Map<String, String> map) {
    return map.entries.map((e) => '${e.key}:${e.value}').join(';');
  }

  static Map<String, String> _decodeMap(String encodedString) {
    return Map.fromEntries(encodedString.split(';').map((e) {
      final parts = e.split(':');
      return MapEntry(parts[0], parts.sublist(1).join(':'));
    }));
  }
}