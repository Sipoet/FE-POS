import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/tag_key.dart';

class ProductCategory extends Model with SaveNDestroyModel {
  String name;
  ProductCategory? parent;
  String description;
  List<TagKeyGroup> tagKeyGroups;
  ProductCategory({
    super.id,
    super.createdAt,
    super.updatedAt,
    this.parent,
    List<TagKeyGroup>? tagKeyGroups,
    this.name = '',
    this.description = '',
  }) : tagKeyGroups = tagKeyGroups ?? [];

  @override
  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'parent': parent,
    'tag_key_groups_attributes': tagKeyGroups.map((e) => e.asJson()).toList(),
  };
  @override
  String get path => 'product_categories';
  List<TagKey> get tagKeys => tagKeyGroups
      .where((e) => e.tagKey != null)
      .map((e) => e.tagKey!)
      .toList();

  void setTagKeys(List<TagKey> newTagKeys) {
    int index = 0;
    while (newTagKeys.length > index || tagKeyGroups.length > index) {
      final tagKeyGroup = tagKeyGroups.elementAtOrNull(index);
      final tagKey = newTagKeys.elementAtOrNull(index);
      if (tagKeyGroup == null) {
        tagKeyGroups.add(TagKeyGroup(tagKey: tagKey));
      } else if (tagKey == null) {
        tagKeyGroup.flagDestroy();
      } else {
        tagKeyGroup.tagKey = tagKey;
      }
      index++;
    }
  }

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    name = attributes['name'];
    description = attributes['description'] ?? '';
    parent = ProductCategoryClass().findRelationData(
      relation: json['relationships']?['parent'],
      included: included,
      isRootIncluded: false,
    );
    tagKeyGroups = TagKeyGroupClass().findRelationsData(
      relation: json['relationships']?['tag_key_groups'],
      included: included,
    );
  }

  @override
  String get modelValue => name;
}

class ProductCategoryClass extends ModelClass<ProductCategory> {
  @override
  ProductCategory initModel() => ProductCategory();
}
