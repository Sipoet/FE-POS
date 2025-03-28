import 'package:fe_pos/model/model.dart';

class ItemType extends Model {
  String description;
  String name;
  ItemType({this.description = '', this.name = '', super.id});

  @override
  Map<String, dynamic> toMap() => {
        'description': description,
        'name': name,
      };

  @override
  String toString() {
    return name;
  }

  @override
  factory ItemType.fromJson(Map<String, dynamic> json,
      {ItemType? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= ItemType();
    model.id = json['id'];
    Model.fromModel(model, attributes);
    model.description = attributes['description'];
    model.name = attributes['name'];
    return model;
  }
  @override
  String get modelValue => name;
}
