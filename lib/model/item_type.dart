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
  Map<String, dynamic> toMap() => {
        'description': description,
        'name': name,
        'parent_id': parentId,
        'created_at': createdAt,
        'updated_at': updatedAt,
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
    if (attributes['parent_id'] != null) {
      model.parent =
          ItemType(id: attributes['parent_id'], name: attributes['parent_id']);
    }

    return model;
  }
  set parent(ItemType? itemType) {
    parentId = itemType?.id;
    _parent = itemType;
  }

  ItemType? get parent => _parent;
  @override
  String get modelValue => name;
}
