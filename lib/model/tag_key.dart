import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/tag.dart';
import 'package:fe_pos/tool/model_route.dart';
export 'package:fe_pos/model/tag.dart';

class TagKey extends Model with SaveNDestroyModel {
  String name;
  String? group;
  List<Tag> tags = [];

  TagKey({this.name = '', this.group, List<Tag>? tags, super.id})
    : tags = tags ?? [];

  @override
  Map<String, dynamic> toMap() => {
    'name': name,
    'group': group,
    'tags_attributes': tags,
  };

  @override
  String get path => 'tag_keys';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];
    super.setFromJson(json, included: included);
    name = attributes['name'];
    group = attributes['group'];
    tags = TagClass().findRelationsData(
      relation: json['relationships']?['tags'],
      included: included,
    );
  }
}

class TagKeyClass extends ModelClass<TagKey> {
  @override
  TagKey initModel() => TagKey();
}

class TagKeyGroup extends Model {
  TagKey? tagKey;
  int? sourceId;
  String sourceType;
  TagKeyGroup({this.sourceId, this.sourceType = '', this.tagKey, super.id});
  @override
  Map<String, dynamic> toMap() => {
    'source_id': sourceId,
    'source_type': sourceType,
    'tag_key_id': tagKey?.id,
    'tag_key': tagKey,
  };

  @override
  String get path => 'tag_keys';

  Model? get source {
    final route = ModelRoute();
    final modelCLass = route.modelClassOf(sourceType);
    if (modelCLass == null) {
      return null;
    }
    final model = modelCLass.initModel();
    model.id = sourceId;
    return model;
  }

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];
    id = json['id'];
    sourceId = attributes['source_id'];
    sourceType = attributes['source_type'];
    tagKey = TagKeyClass().findRelationData(
      relation: json['relationships']?['tag_key'],
      included: included,
    );
  }
}

class TagKeyGroupClass extends ModelClass<TagKeyGroup> {
  @override
  TagKeyGroup initModel() => TagKeyGroup();
}
