import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class Discount extends Model {
  String? itemCode;
  String? itemType;
  String? brandName;
  String? supplierCode;
  Percentage discount1;
  Percentage? discount2;
  Percentage? discount3;
  Percentage? discount4;
  DateTime startTime;
  DateTime endTime;
  int? id;
  String code;
  int weight;
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
      required this.endTime,
      this.weight = 1});

  @override
  factory Discount.fromJson(Map<String, dynamic> json) {
    var attributes = json['attributes'];
    return Discount(
        id: int.parse(json['id']),
        code: attributes['code']?.trim(),
        itemCode: attributes['item_code'],
        itemType: attributes['item_type_name'],
        supplierCode: attributes['supplier_code'],
        brandName: attributes['brand_name'],
        discount1: Percentage(attributes['discount1']),
        discount2: Percentage(attributes['discount2']),
        discount3: Percentage(attributes['discount3']),
        discount4: Percentage(attributes['discount4']),
        weight: attributes['weight'],
        startTime: DateTime.parse(attributes['start_time']),
        endTime: DateTime.parse(attributes['end_time']));
  }

  @override
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
        'weight': weight,
      };
}
