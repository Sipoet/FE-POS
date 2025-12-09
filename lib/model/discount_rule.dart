import 'package:fe_pos/model/item.dart';
import 'package:fe_pos/model/model.dart';

class DiscountRule extends Model {
  Item? item;
  String code;
  DiscountRule(
      {super.id, this.code = '', this.item, super.createdAt, super.updatedAt});
  @override
  Map<String, dynamic> toMap() => {};

  @override
  String get modelName => 'discount_rule';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    code = attributes['code'];
    item = ItemClass().findRelationData(
        included: included, relation: json['relationships']?['item']);
  }

  @override
  String get modelValue => id;
}

class DiscountRuleClass extends ModelClass<DiscountRule> {
  @override
  DiscountRule initModel() => DiscountRule();
}
