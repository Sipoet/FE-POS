import 'dart:async';

import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/tag_key.dart';
import 'package:fe_pos/tool/model_route.dart';

class Tag extends Model with SaveNDestroyModel {
  String value;
  TagKey? tagKey;
  Tag({this.value = '', super.id, this.tagKey});

  @override
  Map<String, dynamic> toMap() => {
    'name': name,
    'value': value,
    'tag_key_id': tagKey?.id,
    'tagKey': tagKey,
  };
  String? get name => tagKey?.name;

  int? get tagKeyId => tagKey?.id as int?;
  @override
  String get path => 'tags';
  Future<TagKey?> getTagKey(server) async {
    if (tagKey?.id == null) {
      return null;
    }
    tagKey = await TagKeyClass().find(server, tagKey!.id);
    return tagKey;
  }

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];
    id = json['id'];
    value = attributes['value'];
    tagKey =
        TagKeyClass().findRelationData(
          relation: json['relationships']?['tag_key'],
          included: included,
        ) ??
        TagKey(id: attributes['tag_key_id'], name: attributes['name'] ?? '');
  }

  @override
  String get modelValue => '$name: $value';
}

class TagClass extends ModelClass<Tag> {
  @override
  Tag initModel() => Tag();
}

class Tagging extends Model {
  Tag? tag;
  int? sourceId;
  String sourceType;
  Tagging({this.sourceId, this.sourceType = '', this.tag, super.id});
  @override
  Map<String, dynamic> toMap() => {
    'source_id': sourceId,
    'source_type': sourceType,
    'tag_id': tag?.id,
    'tag': tag,
  };

  @override
  String get path => 'taggings';

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
    tag = TagClass().findRelationData(
      relation: json['relationships']?['tag'],
      included: included,
    );
    if (tag == null && attributes['tag_id'] != null) {
      tag = Tag(id: attributes['tag_id']);
    }
  }
}

class TaggingClass extends ModelClass<Tagging> {
  @override
  Tagging initModel() => Tagging();
}

mixin Tagable {
  List<Tagging> taggings = [];
  void initTaggings(List<Tagging>? newTaggings) => taggings = newTaggings ?? [];
  List<Tag> get tags =>
      taggings.where((e) => e.tag != null).map<Tag>((e) => e.tag!).toList();

  String get tagDescription => tags.map<String>((e) => e.value).join(' ');

  void setTags(List<Tag> newTags) {
    int index = 0;
    while (newTags.length > index || taggings.length > index) {
      final tagging = taggings.elementAtOrNull(index);
      final tag = newTags.elementAtOrNull(index);
      if (tagging == null) {
        taggings.add(Tagging(tag: tag));
      } else if (tag == null) {
        tagging.flagDestroy();
      } else {
        tagging.tag = tag;
      }
      index++;
    }
  }

  void setTaggingsFromJson(
    Map<String, dynamic> json, {
    List included = const [],
  }) {
    if (included.isEmpty) {
      return;
    }
  }
}
