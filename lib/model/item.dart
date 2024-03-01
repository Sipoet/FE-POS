import 'package:fe_pos/model/brand.dart';
import 'package:fe_pos/model/item_type.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/supplier.dart';

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
  String? id;
  Item(
      {required this.code,
      required this.name,
      required this.itemTypeName,
      this.brandName,
      this.supplierCode,
      this.supplier,
      this.brand,
      required this.itemType,
      this.id});

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
    Supplier? supplier;
    ItemType itemType = ItemType(name: '', description: '');
    Brand? brand;
    final supplierRelated = json['relationships']['supplier'];
    final brandRelated = json['relationships']['brand'];
    final itemTypeRelated = json['relationships']['item_type'];
    if (included.isNotEmpty) {
      if (supplierRelated != null) {
        final supplierData = included.firstWhere((row) =>
            row['type'] == supplierRelated['data']['type'] &&
            row['id'] == supplierRelated['data']['id']);
        if (supplierData != null) {
          supplier = Supplier.fromJson(supplierData);
        }
      }
      if (brandRelated != null) {
        final brandData = included.firstWhere((row) =>
            row['type'] == brandRelated['data']['type'] &&
            row['id'] == brandRelated['data']['id']);
        if (brandData != null) {
          brand = Brand.fromJson(brandData);
        }
      }
      if (itemTypeRelated != null) {
        final itemTypeData = included.firstWhere((row) =>
            row['type'] == itemTypeRelated['data']['type'] &&
            row['id'] == itemTypeRelated['data']['id']);

        itemType = ItemType.fromJson(itemTypeData);
      }
    }
    model ??= Item(code: '', name: '', itemType: itemType, itemTypeName: '');
    model.id = json['id'];
    model.code = attributes['kodeitem'];
    model.name = attributes['namaitem'];
    model.brandName = attributes['merek'];
    model.itemTypeName = attributes['jenis'];
    model.supplierCode = attributes['supplier1'];
    model.supplier = supplier;
    model.itemType = itemType;
    model.brand = brand;
    return model;
  }
}
