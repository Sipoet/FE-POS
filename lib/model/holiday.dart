import 'package:fe_pos/model/employee.dart';
import 'package:fe_pos/model/model.dart';

export 'package:fe_pos/tool/custom_type.dart';

class Holiday extends Model {
  Date date;
  Religion? religion;
  String? description;
  Holiday({Date? date, this.religion, this.description, super.id})
      : date = date ?? Date.today();

  @override
  Map<String, dynamic> toMap() => {
        'date': date,
        'religion': religion,
        'description': description,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  @override
  factory Holiday.fromJson(Map<String, dynamic> json,
      {Holiday? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= Holiday();
    model.id = json['id'];
    Model.fromModel(model, attributes);
    model.religion = attributes['religion'] == null
        ? null
        : Religion.fromString(attributes['religion']);
    model.description = attributes['description'];
    model.date = Date.tryParse(attributes['date'] ?? '') ?? model.date;
    return model;
  }

  @override
  String get modelValue => description ?? '';
}
