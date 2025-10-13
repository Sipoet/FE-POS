import 'package:fe_pos/model/model.dart';

class Product extends Model {
  String description;
  Product({super.id, this.description = '', super.createdAt, super.updatedAt});

  @override
  Map<String, dynamic> toMap() => {
        'description': description,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  @override
  String get modelName => 'product';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];
    super.setFromJson(json, included: included);
    description = attributes['description'];
  }

  @override
  String get modelValue => description;
}

class ProductClass extends ModelClass<Product> {
  @override
  Product initModel() => Product();
}
