import 'package:fe_pos/model/model.dart';

class DiscountRule extends Model {
  DiscountRule({super.id, super.createdAt, super.updatedAt});
  @override
  Map<String, dynamic> toMap() => {};
  @override
  String get modelName => 'discount_rule';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    // var attributes = json['attributes'];
    super.setFromJson(json, included: included);
  }

  @override
  String get modelValue => id;
}

class DiscountRuleClass extends ModelClass<DiscountRule> {
  @override
  DiscountRule initModel() => DiscountRule();
}
