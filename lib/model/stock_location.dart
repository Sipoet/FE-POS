import 'package:fe_pos/model/item.dart';
import 'package:fe_pos/model/location.dart';
export 'package:fe_pos/model/item.dart';
export 'package:fe_pos/model/location.dart';
import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class StockLocation extends Model {
  double quantity;
  Item item;
  Location location;

  String? rack;
  StockLocation({
    Item? item,
    this.rack,
    Location? location,
    this.quantity = 0,
    super.id,

    super.createdAt,
    super.updatedAt,
  }) : item = item ?? Item(),
       location = location ?? Location();

  @override
  Map<String, dynamic> toMap() => {
    'item_code': item.code,
    'item_name': item.name,
    'quantity': quantity,
    'location_code': location.code,
    'rack': rack,
    'item': item,
    'location': location,
  };
  String get itemCode => item.code;

  @override
  String get path => 'ipos/item_stocks';

  String get locationCode => location.code;

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];

    super.setFromJson(json, included: included);
    if (included.isNotEmpty) {
      item =
          ItemClass().findRelationData(
            included: included,
            relation: json['relationships']?['item'],
          ) ??
          Item(id: attributes['item_code'], code: attributes['item_code']);
      location =
          LocationClass().findRelationData(
            included: included,
            relation: json['relationships']?['location'],
          ) ??
          Location(
            id: attributes['location_code'],
            code: attributes['location_code'],
          );
    }
    quantity = double.parse(attributes['quantity'] ?? '0');
    rack = attributes['rack'] ?? '';
  }
}

class StockLocationClass extends ModelClass<StockLocation> {
  @override
  StockLocation initModel() => StockLocation();
}
