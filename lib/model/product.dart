import 'package:fe_pos/model/model.dart';

class Product extends Model {
  String description;
  Product({super.id, this.description = '', super.createdAt, super.updatedAt});

  @override
  Map<String, dynamic> toMap() {
    // TODO: implement toMap
    throw UnimplementedError();
  }

  @override
  factory Product.fromJson(Map<String, dynamic> json,
      {List included = const [], Product? model}) {
    // TODO: implement fromJson
    var attributes = json['attributes'];
    model ??= Product();
    model.id = json['id'];
    Model.fromModel(model, attributes);
    model.description = attributes['description'];

    return model;
  }

  @override
  String get modelValue => description;
}
