import 'package:fe_pos/model/model.dart';

class PaymentType extends Model with SaveNDestroyModel {
  String name;
  PaymentType({super.id, this.name = ''});

  @override
  String get path => 'payment_types';
  @override
  String get modelName => 'payment_type';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    final attributes = json['attributes'];
    name = attributes['name'];
  }

  @override
  Map<String, dynamic> toMap() => {
    'name': name,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  @override
  String get modelValue => name;
}

class PaymentTypeClass extends ModelClass<PaymentType> {
  @override
  PaymentType initModel() => PaymentType();
}
