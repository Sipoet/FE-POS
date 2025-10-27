import 'package:fe_pos/model/model.dart';

class Tag extends Model {
  String name;
  String category;

  Tag? parent;

  Tag(
      {this.name = '',
      this.category = '',
      this.parent,
      super.id,
      super.createdAt,
      super.updatedAt});

  @override
  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'parent_id': parent?.id,
      };

  @override
  String get modelName => 'tag';
}

class TagClass extends ModelClass<Tag> {
  @override
  Tag initModel() => Tag();
}
