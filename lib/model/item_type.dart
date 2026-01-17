import 'package:fe_pos/model/model.dart';

class ItemType extends Model {
  String description;
  String name;
  ItemType({this.description = '', this.name = '', super.id});

  @override
  Map<String, dynamic> toMap() => {'description': description, 'name': name};

  @override
  String toString() {
    return name;
  }

  @override
  String get path => 'ipos/item_types';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];
    super.setFromJson(json, included: included);
    description = attributes['description'];
    name = attributes['name'];
  }

  @override
  String get valueDescription => description;
}

class ItemTypeClass extends ModelClass<ItemType> {
  @override
  ItemType initModel() => ItemType();
}
