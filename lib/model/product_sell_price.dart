import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/product.dart';
import 'package:fe_pos/model/unit_of_measurement.dart';

class ProductSellPrice extends Model {
  UnitOfMeasurement? uom;
  Money? sellPrice;
  Product? product;
  double? maxQuantity;
  ProductSellPrice({
    this.sellPrice,
    this.uom,
    this.maxQuantity,
    this.product,
    super.id,
  });

  @override
  Map<String, dynamic> toMap() => {
    'uom': uom,
    'uom_id': uom?.id,
    'sell_price': sellPrice,
    'max_quantity': maxQuantity,
    'product': product,
    'product_id': product?.id,
  };

  @override
  String get path => 'stock_sell_prices';

  String get priceWithUomText =>
      "${sellPrice?.format()}${maxQuantity == null ? '' : ' max $maxQuantity'} per ${uom?.name}";
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
    product = ProductClass().findRelationData(
      relation: json['relationships']?['product'],
      isRootIncluded: false,
      included: included,
    );
  }
}

class ProductSellPriceClass extends ModelClass<ProductSellPrice> {
  @override
  ProductSellPrice initModel() => ProductSellPrice();
}
