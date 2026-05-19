import 'package:fe_pos/model/model.dart';

class DiscountDetail extends Model {
  double discount;
  String type;
  DiscountDetail({this.type = '', this.discount = 0});
  @override
  Map<String, dynamic> toMap() => {'type': discount, 'discount': discount};

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    discount = double.tryParse(attributes['discount'] ?? '0') ?? 0;

    type = attributes['type'];
  }
}

class DiscountDetailClass extends ModelClass<DiscountDetail> {
  @override
  DiscountDetail initModel() => DiscountDetail();
}
