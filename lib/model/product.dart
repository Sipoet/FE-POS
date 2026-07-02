import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/product_category.dart';
import 'package:fe_pos/model/product_measurement.dart';
import 'package:fe_pos/model/stock_keeping_unit.dart';
import 'package:fe_pos/model/product_sell_price.dart';
import 'package:fe_pos/model/item_variant.dart';
import 'package:fe_pos/model/tag.dart';
import 'package:fe_pos/model/supplier.dart';
import 'package:fe_pos/model/brand.dart';
import 'package:fe_pos/model/unit_of_measurement.dart';
import 'package:fe_pos/tool/image_model.dart';
import 'package:flutter/material.dart';
export 'package:fe_pos/tool/image_model.dart';

export 'package:fe_pos/model/brand.dart';
export 'package:fe_pos/model/supplier.dart';
export 'package:fe_pos/model/tag.dart';

export 'package:fe_pos/model/product_category.dart';

class Product extends Model with SaveNDestroyModel, Tagable {
  String description;
  String? supplierProductCode;
  String? brandName;
  UnitOfMeasurement? baseUom;
  ProductCategory? productCategory;
  bool barcodeUsingBatch;
  String barcode;
  Brand? brand;
  Supplier? supplier;
  Money sellPrice;
  Account? stockAccount;
  StatusSellPrice statusSellPrice;
  List<ProductMeasurement> productMeasurements = [];
  List<StockKeepingUnit> stockKeepingUnits = [];
  List<ProductSellPrice> productSellPrices = [];
  List<ItemVariant> itemVariants = [];
  List<ImageModel> images = [];
  ImageModel? defaultImage;

  Product({
    super.id,
    this.description = '',
    this.supplierProductCode,
    this.barcode = '',
    this.productCategory,
    this.brandName,
    this.baseUom,
    this.stockAccount,
    this.defaultImage,
    this.statusSellPrice = .notChanged,
    this.barcodeUsingBatch = false,
    this.brand,
    this.sellPrice = const Money(0),
    this.supplier,
    List<Tagging>? taggings,
    super.createdAt,
    super.updatedAt,
  }) {
    initTaggings(taggings);
  }

  @override
  String get path => 'products';

  @override
  Map<String, dynamic> toMap() => {
    'description': description,
    'product_category_id': productCategory?.id,
    'product_category': productCategory,
    'brand_id': brand?.id,
    'barcode_using_batch': barcodeUsingBatch,
    'brand_name': brand?.id ?? brandName,
    'brand': brand,
    'images': images,
    'image': defaultImage,
    'supplier_id': supplier?.id,
    'supplier': supplier,
    'barcode': barcode,
    'base_uom': baseUom,
    'base_uom_id': baseUom?.id,
    'supplier_product_code': supplierProductCode,
    'sell_price': sellPrice,
    'stock_account': stockAccount,
    'stock_account_id': stockAccount?.id,
    'product_measurements_attributes': productMeasurements
        .map((e) => e.asJson())
        .toList(),
    'stock_keeping_units_attributes': stockKeepingUnits
        .map((e) => e.asJson())
        .toList(),
    'taggings_attributes': taggings.map((e) => e.asJson()).toList(),
    'product_sell_prices_attributes': productSellPrices
        .map((e) => e.asJson())
        .toList(),
    // 'product_variants_attributes': itemVariants
    //     .map((e) => e.asJson())
    //     .toList(),
  };

  List<ImageModel> get markedDestroyedImages =>
      images.where((image) => image.isDestroyed).toList();

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'] ?? {};
    super.setFromJson(json, included: included);
    description = attributes['description'] ?? '';
    barcode = attributes['barcode'] ?? '';
    supplierProductCode = attributes['supplier_product_code'];
    barcodeUsingBatch = attributes['barcode_using_batch'] ?? false;
    brand = BrandClass().findRelationData(
      relation: json['relationships']?['brand'],
      included: included,
    );
    sellPrice =
        Money.tryParse(attributes['sell_price'].toString()) ?? const Money(0);
    brandName = brand?.name ?? attributes['brand_name'];
    productCategory = ProductCategoryClass().findRelationData(
      relation: json['relationships']?['product_category'],
      included: included,
    );
    stockAccount = AccountClass().findRelationData(
      relation: json['relationships']?['stock_account'],
      included: included,
    );
    supplier = SupplierClass().findRelationData(
      relation: json['relationships']?['supplier'],
      included: included,
    );
    baseUom = UnitOfMeasurementClass().findRelationData(
      relation: json['relationships']?['base_uom'],
      included: included,
    );
    setTaggingsFromJson(json, included: included);
    images = ImageModelClass().findRelationsData(
      relation: json['relationships']?['images'],
      included: included,
    );
    productMeasurements = ProductMeasurementClass().findRelationsData(
      relation: json['relationships']?['product_measurements'],
      included: included,
    );
    productSellPrices = ProductSellPriceClass().findRelationsData(
      relation: json['relationships']?['product_sell_prices'],
      included: included,
    );
    stockKeepingUnits = StockKeepingUnitClass().findRelationsData(
      relation: json['relationships']?['stock_keeping_units'],
      included: included,
    );
    defaultImage = attributes['image'] == null
        ? null
        : ImageModelClass().fromJson(
            attributes['image']?['data'],
            included: included,
          );
  }

  @override
  String get modelValue => "$barcode $supplierProductCode";
  @override
  String get valueDescription => description;
}

class ProductClass extends ModelClass<Product> {
  @override
  Product initModel() => Product();
}

enum StatusSellPrice {
  notChanged,
  cancel,
  onProgress,
  failed,
  success;

  Widget? get icon {
    switch (this) {
      case notChanged:
        return null;
      case cancel:
        return Icon(
          Icons.remove_circle_outline_sharp,
          color: Colors.yellow.shade500,
        );
      case onProgress:
        return CircularProgressIndicator();
      case failed:
        return Icon(Icons.close_rounded, color: Colors.red);
      case success:
        return Icon(Icons.done_rounded, color: Colors.green.shade900);
    }
  }
}
