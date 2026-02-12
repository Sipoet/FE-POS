import 'package:fe_pos/model/model.dart';

class ItemType extends Model {
  String description;
  String name;
  ItemType? _parent;
  dynamic parentId;
  ItemType({this.description = '', this.name = '', this.parentId, super.id})
      : _parent = parentId == null
            ? null
            : ItemType(id: parentId, name: parentId as String);

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
    if (attributes['parent_id'] != null) {
      parent =
          ItemType(id: attributes['parent_id'], name: attributes['parent_id']);
    }
    description = attributes['description'];
    name = attributes['name'];
  }

  set parent(ItemType? itemType) {
    parentId = itemType?.id;
    _parent = itemType;
  }

  ItemType? get parent => _parent;

  @override
  String get valueDescription => description;
}

class ItemTypeClass extends ModelClass<ItemType> {
  @override
  ItemType initModel() => ItemType();
}
