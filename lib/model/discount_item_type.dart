import 'package:fe_pos/model/item_type.dart';
export 'package:fe_pos/model/item_type.dart';
import 'package:fe_pos/model/model.dart';

class DiscountItemType extends Model {
  ItemType? itemType;

  bool isExclude;
  DiscountItemType({super.id, this.isExclude = false, this.itemType});

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    isExclude = attributes['is_exclude'];
    itemType = ItemTypeClass().findRelationData(
      included: included,
      relation: json['relationships']['item_type'],
    );
  }

  String? get itemTypeName => itemType?.name;

  @override
  Map<String, dynamic> toMap() => {
        'item_type_name': itemTypeName,
        'item_type.jenis': itemTypeName,
        'is_exclude': isExclude
      };

  @override
  String get modelValue => itemType?.modelValue ?? '';
}

class DiscountItemTypeClass extends ModelClass<DiscountItemType> {
  @override
  DiscountItemType initModel() => DiscountItemType();
}
