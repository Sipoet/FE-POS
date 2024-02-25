import 'package:fe_pos/tool/custom_type.dart';
export 'package:fe_pos/tool/custom_type.dart';

abstract class Model {
  // int? id;
  // Model({this.id});
  Map<String, dynamic> toMap();

  Map<String, dynamic> toJson() {
    var json = toMap();
    json.forEach((key, object) {
      if (object is Money || object is Percentage) {
        json[key] = object.value;
      } else if (object is Date || object is DateTime) {
        json[key] = object.toIso8601String();
      }
    });
    return json;
  }
}

abstract class ModelClass {
  Model fromJson(Map<String, dynamic> json);
}
