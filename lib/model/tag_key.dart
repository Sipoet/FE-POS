import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/tag.dart';
export 'package:fe_pos/model/tag.dart';

class TagKey extends Model with SaveNDestroyModel {
  String name;
  String? group;
  List<Tag> tags = [];

  TagKey({this.name = '', this.group, List<Tag>? tags, super.id})
    : tags = tags ?? [];

  @override
  Map<String, dynamic> toMap() => {'name': name, 'group': group};

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
