import 'package:fe_pos/model/model.dart';

class Brand extends Model with SaveNDestroyModel {
  String name;
  String description;
  Brand({
    this.name = '',
    this.description = '',
    super.id,
    super.createdAt,
    super.updatedAt,
  });
  @override
  Map<String, dynamic> toMap() => {'description': description, 'name': name};

  @override
  String get path => 'brands';
  @override
  String get modelValue => name;

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];
    super.setFromJson(json, included: included);
    description = attributes['description'] ?? '';
    name = attributes['name'] ?? '';
  }
}

class BrandClass extends ModelClass<Brand> {
  @override
  Brand initModel() => Brand();
}
