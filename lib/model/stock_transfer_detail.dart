export 'package:fe_pos/model/product.dart';
import 'package:fe_pos/model/item_variant.dart';
import 'package:fe_pos/model/stock_keeping_unit.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/stock_transfer.dart';
export 'package:fe_pos/tool/custom_type.dart';
export 'package:fe_pos/model/discount_detail.dart';
import 'package:fe_pos/model/unit_of_measurement.dart';

class StockTransferDetail extends Model {
  Product? product;
  double quantity;
  StockKeepingUnit? sku;
  UnitOfMeasurement? uom;
  String? barcode;
  StockTransfer? stockTransfer;
  int? rowNumber;
  StockTransferDetail({
    this.quantity = 0,
    this.product,
    this.barcode,
    this.sku,
    this.rowNumber,
    this.stockTransfer,
    this.uom,
  });
  @override
  String get path => 'stock_transfer_details';
  @override
  Map<String, dynamic> toMap() => {
    'barcode': barcode,
    'quantity': quantity,
    'sell_price': sellPrice,
    'row_number': rowNumber,
    'product_category': product?.productCategory,
    'brand': product?.brand,
    'product': product,
    'product_id': product?.id,
    'product_code': productCode,
    'sku': sku,
    'uom': uom,
    'uom_id': uom?.id,
  };

  String? get productCode => product?.supplierProductCode;

  ItemVariant? get itemVariant =>
      product is ItemVariant ? (product as ItemVariant) : null;

  Money get sellPrice => product?.sellPrice ?? const Money(0);

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    if (included.isNotEmpty) {
      final relation = json['relationships']?['product'];
      if (relation?['data']?['type'] == 'item_variant') {
        product = ItemVariantClass().findRelationData(
          included: included,
          relation: relation,
        );
      } else if (relation?['data']?['type'] == 'product') {
        product = ProductClass().findRelationData(
          included: included,
          relation: relation,
        );
      }

      stockTransfer =
          StockTransferClass().findRelationData(
            included: included,
            isRootIncluded: false,
            relation: json['relationships']?['stock_transfer'],
          ) ??
          StockTransfer(id: attributes['stock_transfer_id']);

      uom = UnitOfMeasurementClass().findRelationData(
        relation: json['relationships']?['uom'],
        included: included,
      );

      sku = StockKeepingUnitClass().findRelationData(
        relation: json['relationships']?['sku'],
        included: included,
      );
    }
    rowNumber = attributes['row_number'];
    quantity = double.tryParse(attributes['quantity'].toString()) ?? 0;
    barcode = attributes['barcode'];
  }
}

class StockTransferDetailClass extends ModelClass<StockTransferDetail> {
  @override
  StockTransferDetail initModel() => StockTransferDetail();
}
