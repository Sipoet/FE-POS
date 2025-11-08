import 'package:fe_pos/model/model.dart';

class Brand extends Model {
  String description;
  String name;

  Brand({this.description = '', this.name = '', super.id});

  @override
  Map<String, dynamic> toMap() => {
        'description': description,
        'name': name,
      };

  @override
  String get modelValue => name;
  @override
  String get modelName => 'brand';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];
    super.setFromJson(json, included: included);
    description = attributes['description'] ?? '';
    name = attributes['name'];
  }
}

class BrandClass extends ModelClass<Brand> {
  @override
  Brand initModel() => Brand();
}
