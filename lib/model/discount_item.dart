import 'package:fe_pos/model/item.dart';
export 'package:fe_pos/model/item.dart';
import 'package:fe_pos/model/model.dart';

class DiscountItem extends Model {
  Item? item;

  bool isExclude;
  DiscountItem({super.id, this.item, this.isExclude = false});

  @override
  String get modelName => 'discount_item';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    isExclude = attributes['is_exclude'] ?? false;
    item = ItemClass().findRelationData(
      included: included,
      relation: json['relationships']['item'],
    );
  }

  String? get itemCode => item?.code;

  @override
  Map<String, dynamic> toMap() => {
        'item_code': itemCode,
        'item.kodeitem': itemCode,
        'is_exclude': isExclude,
      };

  @override
  String get modelValue => item?.code ?? '';
}

class DiscountItemClass extends ModelClass<DiscountItem> {
  @override
  DiscountItem initModel() => DiscountItem();
}
