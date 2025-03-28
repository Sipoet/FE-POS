import 'package:fe_pos/model/item.dart';
export 'package:fe_pos/model/item.dart';
import 'package:fe_pos/model/model.dart';

class DiscountItem extends Model {
  Item? item;

  bool isExclude;
  DiscountItem({super.id, required this.item, this.isExclude = false});

  @override
  factory DiscountItem.fromJson(Map<String, dynamic> json,
      {List included = const []}) {
    var attributes = json['attributes'];
    return DiscountItem(
      id: int.parse(json['id']),
      isExclude: attributes['is_exclude'] ?? false,
      item: Model.findRelationData<Item>(
          included: included,
          relation: json['relationships']['item'],
          convert: Item.fromJson),
    );
  }

  String? get itemCode => item?.code;

  @override
  Map<String, dynamic> toMap() => {
        'item_code': itemCode,
        'item.kodeitem': itemCode,
      };

  @override
  String get modelValue => item?.code ?? '';
}
