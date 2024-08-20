import 'package:fe_pos/model/model.dart';

class PaymentType extends Model {
  String name;
  PaymentType({super.id, this.name = ''});

  @override
  factory PaymentType.fromJson(Map<String, dynamic> json,
      {List included = const [], PaymentType? model}) {
    final attributes = json['attributes'];

    model ??= PaymentType();
    model.id = json['id'];
    Model.fromModel(model, attributes);
    model.name = attributes['name'];
    return model;
  }
  @override
  Map<String, dynamic> toMap() => {
        'name': name,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
