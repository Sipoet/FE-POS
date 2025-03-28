import 'package:fe_pos/model/model.dart';

class DiscountRule extends Model {
  DiscountRule({super.id, super.createdAt, super.updatedAt});
  @override
  Map<String, dynamic> toMap() => {};
  @override
  factory DiscountRule.fromJson(Map<String, dynamic> json,
      {DiscountRule? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= DiscountRule();
    model.id = json['id'];
    Model.fromModel(model, attributes);
    return model;
  }

  @override
  String get modelValue => id;
}
