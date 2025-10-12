import 'package:fe_pos/model/supplier.dart';
export 'package:fe_pos/model/supplier.dart';
import 'package:fe_pos/model/model.dart';

class DiscountSupplier extends Model {
  Supplier? supplier;

  bool isExclude;
  DiscountSupplier({super.id, this.supplier, this.isExclude = false});

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    isExclude = attributes['is_exclude'];
    supplier = SupplierClass().findRelationData(
      included: included,
      relation: json['relationships']['supplier'],
    );
  }

  String? get supplierCode => supplier?.code;

  @override
  Map<String, dynamic> toMap() => {
        'supplier_code': supplierCode,
        'supplier.kode': supplierCode,
        'is_exclude': isExclude
      };

  @override
  String get modelValue => supplier?.modelValue ?? '';
}

class DiscountSupplierClass extends ModelClass<DiscountSupplier> {
  @override
  DiscountSupplier initModel() => DiscountSupplier();
}
