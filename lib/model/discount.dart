class Discount {
  String? itemCode;
  String? itemType;
  String? brandName;
  String? supplierCode;
  double discount1;
  double? discount2;
  double? discount3;
  double? discount4;
  DateTime startTime;
  DateTime endTime;
  int? id;
  String code;
  Discount(
      {this.id,
      this.code = '[generated_code]',
      this.itemCode,
      this.itemType,
      this.brandName,
      this.supplierCode,
      required this.discount1,
      this.discount2,
      this.discount3,
      this.discount4,
      required this.startTime,
      required this.endTime});

  factory Discount.fromJson(Map<String, dynamic> json) {
    var attributes = json['attributes'];
    return Discount(
        id: int.parse(json['id']),
        code: attributes['code']?.trim(),
        itemCode: attributes['item_code'],
        itemType: attributes['item_type_name'],
        supplierCode: attributes['supplier_code'],
        brandName: attributes['brand_name'],
        discount1: attributes['discount1'],
        discount2: attributes['discount2'],
        discount3: attributes['discount3'],
        discount4: attributes['discount4'],
        startTime: DateTime.parse(attributes['start_time']),
        endTime: DateTime.parse(attributes['end_time']));
  }

  Map<String, dynamic> toMap() => {
        'code': code.trim(),
        'item_code': itemCode,
        'item_type_name': itemType,
        'brand_name': brandName,
        'supplier_code': supplierCode,
        'discount1': discount1,
        'discount2': discount2,
        'discount3': discount3,
        'discount4': discount4,
        'start_time': startTime,
        'end_time': endTime,
      };

  Map<String, dynamic> toJson() {
    var json = toMap();
    json['start_time'] = startTime.toIso8601String();
    json['end_time'] = endTime.toIso8601String();
    return json;
  }
}
