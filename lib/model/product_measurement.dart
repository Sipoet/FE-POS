import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/product.dart';
import 'package:fe_pos/model/unit_of_measurement.dart';

class ProductMeasurement extends Model {
  UnitOfMeasurement? uom;
  double conversion;
  Product? product;
  ProductMeasurement({this.uom, this.product, this.conversion = 0});
  @override
  Map<String, dynamic> toMap() => {
    'uom': uom,
    'uom_id': uom,
    'product': product,
    'product_id': product?.id,
    'conversion': conversion,
  };
  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'] ?? {};
    super.setFromJson(json, included: included);
    uom = UnitOfMeasurementClass().findRelationData(
      included: included,
      relation: json['relationships']?['uom'],
    );
    product = ProductClass().findRelationData(
      included: included,
      isRootIncluded: false,
      relation: json['relationships']?['product'],
    );
    conversion = double.tryParse(attributes['conversion'].toString()) ?? 0;
  }
}

class ProductMeasurementClass extends ModelClass<ProductMeasurement> {
  @override
  ProductMeasurement initModel() => ProductMeasurement();
}
