import 'package:fe_pos/model/model.dart';

class Brand extends Model {
  String description;
  String name;

  Brand({this.description = '', this.name = '', super.id});

  @override
  Map<String, dynamic> toMap() => {
        'ketmerek': description,
        'merek': name,
      };

  @override
  String toString() {
    return name;
  }

  @override
  factory Brand.fromJson(Map<String, dynamic> json,
      {Brand? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= Brand();
    model.id = json['id'];
    model.description = attributes['ketmerek'] ?? '';
    model.name = attributes['merek'];
    return model;
  }
}
