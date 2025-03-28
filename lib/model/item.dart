import 'package:fe_pos/model/brand.dart';
import 'package:fe_pos/model/item_type.dart';
import 'package:fe_pos/model/supplier.dart';
export 'package:fe_pos/model/brand.dart';
export 'package:fe_pos/model/item_type.dart';
export 'package:fe_pos/model/supplier.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/discount_rule.dart';
export 'package:fe_pos/model/discount_rule.dart';

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
  Money cogs;
  String uom;
  String? description;
  Money sellPrice;
  List<DiscountRule> discountRules;
  Item(
      {this.code = '',
      this.name = '',
      this.itemTypeName = '',
      this.brandName,
      this.supplierCode,
      this.supplier,
      this.description,
      this.brand,
      List<DiscountRule>? discountRules,
      this.uom = '',
      Money? sellPrice,
      Money? cogs,
      ItemType? itemType,
      super.id})
      : itemType = itemType ?? ItemType(),
        discountRules = discountRules ?? [],
        cogs = cogs ?? const Money(0),
        sellPrice = sellPrice ?? const Money(0);

  @override
  Map<String, dynamic> toMap() => {
        'code': code,
        'name': name,
        'supplier': supplier,
        'brand': brand,
        'item_type': itemType,
        'supplier_name': supplier?.name,
        'supplier_code': supplierCode,
        'brand_name': brandName,
        'item_type_name': itemTypeName,
        'sell_price': sellPrice,
        'cogs': cogs,
        'uom': uom
      };

  @override
  factory Item.fromJson(Map<String, dynamic> json,
      {Item? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= Item();
    model.id = json['id'];
    Model.fromModel(model, attributes);
    model.code = attributes['code'];
    model.name = attributes['name'];
    model.description = attributes['description'];
    model.brandName = attributes['brand_name'] ?? '';
    model.itemTypeName = attributes['item_type_name'] ?? '';
    model.supplierCode = attributes['supplier_code'] ?? '';
    model.cogs = Money.tryParse(attributes['cogs']) ?? model.cogs;
    model.uom = attributes['uom'] ?? '';
    model.sellPrice =
        Money.tryParse(attributes['sell_price']) ?? model.sellPrice;
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
    model.discountRules = Model.findRelationsData<DiscountRule>(
        relation: json['relationships']['discount_rules'],
        included: included,
        convert: DiscountRule.fromJson);
    return model;
  }

  Percentage get margin => cogs == Money(0)
      ? Percentage(0)
      : Percentage((sellPrice / cogs).value - 1);

  @override
  String get modelValue => "$code - $name";
}
