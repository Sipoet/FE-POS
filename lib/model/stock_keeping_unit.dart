import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/product.dart';
import 'package:fe_pos/model/unit_of_measurement.dart';

class StockKeepingUnit extends Model with SaveNDestroyModel {
  String barcode;
  String batchCode;
  String uniqCode;
  Date? prodDate;
  Date? purchaseDate;
  Date? expiredDate;
  UnitOfMeasurement? uom;
  Supplier? supplier;
  Product? product;
  double? quantity;
  Money? cogs;
  // Money? sellPrice;

  StockKeepingUnit({
    super.id,
    super.createdAt,
    super.updatedAt,
    this.barcode = '',
    this.uniqCode = '',
    this.prodDate,
    this.expiredDate,
    this.uom,
    this.supplier,
    this.product,
    this.quantity,
    this.cogs,
    this.batchCode = '',
  });

  @override
  Map<String, dynamic> toMap() => {
    'barcode': barcode,
    'batch_code': batchCode,
    'uniq_code': uniqCode,
    'uom': uom,
    'uom_id': uom?.id,
    'supplier': supplier,
    'supplier_id': supplier?.id,
    'product': product,
    'product_id': product?.id,
    'production_date': prodDate,
    'purchase_date': purchaseDate,
    'expired_date': expiredDate,
    'quantity': quantity,
    'cogs': cogs,
  };
  @override
  String get path => 'stock_keeping_units';
  @override
  String get modelName => 'stock_keeping_unit';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'] ?? {};
    barcode = attributes['barcode'] ?? '';
    batchCode = attributes['batch_code'] ?? '';
    uniqCode = attributes['uniq_code'] ?? '';
    prodDate = Date.tryParse(attributes['production_date'] ?? '');
    purchaseDate = Date.tryParse(attributes['purchase_date'] ?? '');
    expiredDate = Date.tryParse(attributes['expired_date'] ?? '');
    cogs = Money.tryParse(attributes['cogs']);
    quantity = double.tryParse(attributes['quantity'] ?? '');
    uom = UnitOfMeasurementClass().findRelationData(
      relation: json['relationships']?['uom'],
      included: included,
    );
    product = ProductClass().findRelationData(
      relation: json['relationships']?['product'],
      isRootIncluded: false,
      included: included,
    );
    supplier = SupplierClass().findRelationData(
      relation: json['relationships']?['supplier'],
      included: included,
    );
    // sellPrice = Money.tryParse(attributes['sell_price'] ?? '');
  }
}

class StockKeepingUnitClass extends ModelClass<StockKeepingUnit> {
  @override
  StockKeepingUnit initModel() => StockKeepingUnit();
}
