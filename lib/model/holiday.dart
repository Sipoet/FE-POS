import 'package:fe_pos/model/model.dart';

export 'package:fe_pos/tool/custom_type.dart';

class Holiday extends Model {
  Date date;
  String? description;
  Holiday({Date? date, this.description, super.id})
      : date = date ?? Date.today();

  @override
  Map<String, dynamic> toMap() => {
        'date': date,
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
    model.description = attributes['description'];
    model.date = Date.tryParse(attributes['date'] ?? '') ?? model.date;
    return model;
  }

  @override
  String get modelValue => description ?? '';
}
