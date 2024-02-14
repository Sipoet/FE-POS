import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class Role extends Model {
  String name;
  int? id;
  Role({required this.name, this.id});

  @override
  Map<String, dynamic> toMap() => {
        'name': name,
      };

  @override
  factory Role.fromJson(Map<String, dynamic> json, {Role? model}) {
    var attributes = json['attributes'];
    model ??= Role(name: '');
    model.id = int.parse(json['id']);
    model.name = attributes['name'];
    return model;
  }
}
