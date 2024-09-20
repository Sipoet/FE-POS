import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class PayrollType extends Model {
  String name;
  PayrollType({
    this.name = '',
    super.id,
    super.createdAt,
    super.updatedAt,
  });

  @override
  Map<String, dynamic> toMap() => {
        'name': name,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  @override
  factory PayrollType.fromJson(Map<String, dynamic> json,
      {PayrollType? model, List included = const []}) {
    var attributes = json['attributes'];

    model ??= PayrollType();

    Model.fromModel(model, attributes);
    model.id = int.parse(json['id']);
    model.name = attributes['name'];
    return model;
  }
}
