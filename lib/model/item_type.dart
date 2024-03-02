import 'package:fe_pos/model/model.dart';

class ItemType extends Model {
  String description;
  String name;
  String? id;
  ItemType({required this.description, required this.name, this.id});

  @override
  Map<String, dynamic> toMap() => {
        'ketjenis': description,
        'jenis': name,
      };

  @override
  factory ItemType.fromJson(Map<String, dynamic> json,
      {ItemType? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= ItemType(description: '', name: '');
    model.id = json['id'];
    model.description = attributes['ketjenis'];
    model.name = attributes['jenis'];
    return model;
  }
}
