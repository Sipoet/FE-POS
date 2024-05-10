import 'package:fe_pos/model/item_type.dart';
export 'package:fe_pos/model/item_type.dart';
import 'package:fe_pos/model/model.dart';

class DiscountItemType extends Model {
  ItemType? itemType;
  int? id;
  bool isExclude;
  DiscountItemType({this.id, this.isExclude = false, this.itemType});

  @override
  factory DiscountItemType.fromJson(Map<String, dynamic> json,
      {List included = const []}) {
    var attributes = json['attributes'];
    return DiscountItemType(
      id: int.parse(json['id']),
      isExclude: attributes['is_exclude'],
      itemType: Model.findRelationData<ItemType>(
          included: included,
          relation: json['relationships']['item_type'],
          convert: ItemType.fromJson),
    );
  }

  String? get itemTypeName => itemType?.name;

  @override
  Map<String, dynamic> toMap() => {
        'item_type_name': itemTypeName,
        'item_type.jenis': itemTypeName,
        'is_exclude': isExclude
      };
}
