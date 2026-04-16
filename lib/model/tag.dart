import 'dart:async';

import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/tag_key.dart';

class Tag extends Model {
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
    tagKey = TagKeyClass().findRelationData(
      relation: json['relationships']?['tag_key'],
      included: included,
    );
  }

  @override
  String get path => 'tags';
}

class TagClass extends ModelClass<Tag> {
  @override
  Tag initModel() => Tag();
}
