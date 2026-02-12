import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/item_type.dart';
import 'package:fe_pos/model/brand.dart';
import 'package:fe_pos/model/product_tag.dart';
import 'package:fe_pos/model/supplier.dart';
export 'package:fe_pos/model/item_type.dart';
export 'package:fe_pos/model/brand.dart';
export 'package:fe_pos/model/supplier.dart';
export 'package:fe_pos/model/product_tag.dart';

class Product extends Model with SaveNDestroyModel {
  String description;
  String? supplierProductCode;
  ItemType? itemType;
  String defaultBarcode;
  Brand? brand;
  Supplier? supplier;
  Money sellPrice;
  List<ProductTag> tags = [];

  Product(
      {super.id,
      this.description = '',
      this.supplierProductCode,
      this.defaultBarcode = '',
      this.itemType,
      List<ProductTag>? tags,
      this.brand,
      this.sellPrice = const Money(0),
      this.supplier,
      super.createdAt,
      super.updatedAt})
      : tags = tags ?? [];

  @override
  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'item_type_id': itemType?.id,
        'brand_id': brand?.id,
        'supplier_id': supplier?.id,
        'item_type': itemType,
        'brand': brand,
        'default_barcode': defaultBarcode,
        'supplier': supplier,
        'supplier_product_code': supplierProductCode,
        'sell_price': sellPrice,
      };

  @override
  String get modelName => 'product';

  String get name => description;

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'] ?? {};
    super.setFromJson(json, included: included);
    description = attributes['description'] ?? '';
    defaultBarcode = attributes['default_barcode'] ?? '';
    supplierProductCode = attributes['supplier_product_code'];
    brand = BrandClass().findRelationData(
        relation: json['relationships']?['brand'], included: included);
    itemType = ItemTypeClass().findRelationData(
        relation: json['relationships']?['item_type'], included: included);
    supplier = SupplierClass().findRelationData(
        relation: json['relationships']?['supplier'], included: included);
    tags = ProductTagClass().findRelationsData(
        relation: json['relationships']?['product_tags'], included: included);
  }

  @override
  String get modelValue => description;
}

class ProductClass extends ModelClass<Product> {
  @override
  Product initModel() => Product();
}
