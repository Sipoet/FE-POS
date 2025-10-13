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
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    religion = attributes['religion'] == null
        ? null
        : Religion.fromString(attributes['religion']);
    description = attributes['description'];
    date = Date.tryParse(attributes['date'] ?? '') ?? date;
  }

  @override
  String get modelValue => description ?? '';
}

class HolidayClass extends ModelClass<Holiday> {
  @override
  Holiday initModel() => Holiday();
}
