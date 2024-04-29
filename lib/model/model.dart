import 'package:fe_pos/tool/custom_type.dart';
export 'package:fe_pos/tool/custom_type.dart';

abstract class Model {
  // int? id;
  DateTime? createdAt;
  DateTime? updatedAt;
  Model({this.createdAt, this.updatedAt});
  Map<String, dynamic> toMap();

  Map<String, dynamic> toJson() {
    var json = toMap();
    json.forEach((key, object) {
      if (object is Money || object is Percentage) {
        json[key] = object.value;
      } else if (object is Date || object is DateTime) {
        json[key] = object.toIso8601String();
      } else if (object is Enum) {
        json[key] = object.toString();
      }
    });
    return json;
  }

  static void fromModel(Model model, Map attributes) {
    model.createdAt = DateTime.tryParse(attributes['created_at'] ?? '');
    model.updatedAt = DateTime.tryParse(attributes['updated_at'] ?? '');
  }

  static T? findRelationData<T extends Model>(
      {required List included,
      Map? relation,
      required T Function(Map<String, dynamic>) convert}) {
    final relationData = relation?['data'];
    if (relationData == null) {
      return null;
    }
    final data = included.firstWhere((row) =>
        row['type'] == relationData['type'] && row['id'] == relationData['id']);
    if (data == null) {
      return null;
    }
    return convert(data);
  }
}

abstract class ModelClass {
  Model fromJson(Map<String, dynamic> json);
}
