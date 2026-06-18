import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/stock_keeping_unit.dart';
import 'package:fe_pos/model/unit_of_measurement.dart';

class StockSellPrice extends Model {
  UnitOfMeasurement? uom;
  Money? sellPrice;
  StockKeepingUnit? sku;
  double? maxQuantity;
  StockSellPrice({
    this.sellPrice,
    this.uom,
    this.maxQuantity,
    this.sku,
    super.id,
  });

  @override
  Map<String, dynamic> toMap() => {
    'uom': uom,
    'uom_id': uom?.id,
    'sell_price': sellPrice,
    'max_quantity': maxQuantity,
    'sku': sku,
    'sku_id': sku?.id,
  };

  String get priceWithUomText =>
      "${sellPrice?.format()}${maxQuantity == null ? '' : ' max ${maxQuantity}'} per ${uom?.name}";
  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'] ?? {};
    sellPrice = Money.tryParse(attributes['sell_price']);
    maxQuantity = double.tryParse(attributes['max_quantity'] ?? '');
    uom = UnitOfMeasurementClass().findRelationData(
      relation: json['relationships']?['uom'],
      included: included,
    );
    sku = StockKeepingUnitClass().findRelationData(
      relation: json['relationships']?['sku'],
      isRootIncluded: false,
      included: included,
    );
  }
}

class StockSellPriceClass extends ModelClass<StockSellPrice> {
  @override
  StockSellPrice initModel() => StockSellPrice();
}
