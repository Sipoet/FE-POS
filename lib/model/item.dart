import 'package:fe_pos/model/brand.dart';
import 'package:fe_pos/model/item_type.dart';
import 'package:fe_pos/model/supplier.dart';
export 'package:fe_pos/model/brand.dart';
export 'package:fe_pos/model/item_type.dart';
export 'package:fe_pos/model/supplier.dart';
import 'package:fe_pos/model/model.dart';

export 'package:fe_pos/tool/custom_type.dart';

class Item extends Model {
  String code;
  String name;
  String? supplierCode;
  String itemTypeName;
  String? brandName;
  Supplier? supplier;
  ItemType itemType;
  Brand? brand;
  Item(
      {this.code = '',
      this.name = '',
      this.itemTypeName = '',
      this.brandName,
      this.supplierCode,
      this.supplier,
      this.brand,
      ItemType? itemType,
      super.id})
      : itemType = itemType ?? ItemType();

  @override
  Map<String, dynamic> toMap() => {
        'kodeitem': code,
        'namaitem': name,
        'supplier.nama': supplier?.name,
        'supplier.kode': supplierCode,
        'brand.merek': brandName,
        'item_type.jenis': itemTypeName,
      };

  @override
  factory Item.fromJson(Map<String, dynamic> json,
      {Item? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= Item();
    model.id = json['id'];
    model.code = attributes['kodeitem'];
    model.name = attributes['namaitem'];
    model.brandName = attributes['merek'];
    model.itemTypeName = attributes['jenis'];
    model.supplierCode = attributes['supplier1'];
    model.supplier = Model.findRelationData<Supplier>(
        relation: json['relationships']['supplier'],
        included: included,
        convert: Supplier.fromJson);
    model.itemType = Model.findRelationData<ItemType>(
            relation: json['relationships']['item_type'],
            included: included,
            convert: ItemType.fromJson) ??
        ItemType();
    model.brand = Model.findRelationData<Brand>(
        relation: json['relationships']['brand'],
        included: included,
        convert: Brand.fromJson);
    return model;
  }
}
