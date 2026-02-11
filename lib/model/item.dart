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
  Item({
    this.code = '',
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
    super.id,
  }) : itemType = itemType ?? ItemType(),
       discountRules = discountRules ?? [],
       cogs = cogs ?? const Money(0),
       sellPrice = sellPrice ?? const Money(0);

  @override
  String get path => 'ipos/items';

  @override
  Map<String, dynamic> toMap() => {
    'code': code,
    'name': name,
    'supplier': supplier,
    'brand': brand,
    'item_type': itemType,
    'supplier_name': supplier?.name,
    'supplier_code': supplier?.code ?? supplierCode,
    'brand_name': brand?.name ?? brandName,
    'item_type_name': itemType.name,
    'sell_price': sellPrice,
    'description': description,
    'cogs': cogs,
    'uom': uom,
  };

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];
    super.setFromJson(json, included: included);
    code = attributes['code'];
    name = attributes['name'];
    description = attributes['description'];
    brandName = attributes['brand_name'] ?? '';
    itemTypeName = attributes['item_type_name'] ?? '';
    supplierCode = attributes['supplier_code'] ?? '';
    cogs = Money.tryParse(attributes['cogs']) ?? cogs;
    uom = attributes['uom'] ?? '';
    sellPrice = Money.tryParse(attributes['sell_price']) ?? sellPrice;
    supplier = SupplierClass().findRelationData(
      relation: json['relationships']['supplier'],
      included: included,
    );
    itemType =
        ItemTypeClass().findRelationData(
          relation: json['relationships']['item_type'],
          included: included,
        ) ??
        ItemType(name: itemTypeName);
    brand = BrandClass().findRelationData(
      relation: json['relationships']['brand'],
      included: included,
    );
  }

  Percentage get margin => cogs == Money(0)
      ? Percentage(0)
      : Percentage((sellPrice / cogs).value - 1);

  @override
  String get valueDescription => name;
}

class ItemClass extends ModelClass<Item> {
  @override
  Item initModel() => Item();
}
