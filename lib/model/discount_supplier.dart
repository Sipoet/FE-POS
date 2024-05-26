import 'package:fe_pos/model/supplier.dart';
export 'package:fe_pos/model/supplier.dart';
import 'package:fe_pos/model/model.dart';

class DiscountSupplier extends Model {
  Supplier? supplier;

  bool isExclude;
  DiscountSupplier({super.id, this.supplier, this.isExclude = false});

  @override
  factory DiscountSupplier.fromJson(Map<String, dynamic> json,
      {List included = const []}) {
    var attributes = json['attributes'];
    return DiscountSupplier(
      id: int.parse(json['id']),
      isExclude: attributes['is_exclude'],
      supplier: Model.findRelationData<Supplier>(
          included: included,
          relation: json['relationships']['supplier'],
          convert: Supplier.fromJson),
    );
  }

  String? get supplierCode => supplier?.code;

  @override
  Map<String, dynamic> toMap() => {
        'supplier_code': supplierCode,
        'supplier.kode': supplierCode,
        'is_exclude': isExclude
      };
}
