import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/product.dart';
import 'package:fe_pos/model/tag.dart';
export 'package:fe_pos/model/product.dart';
export 'package:fe_pos/model/tag.dart';

class ProductTag extends Model {
  Product? product;
  Tag? tag;
  String? value;

  ProductTag(
      {this.tag,
      this.value,
      this.product,
      super.id,
      super.createdAt,
      super.updatedAt});

  @override
  Map<String, dynamic> toMap() => {
        'tag': tag,
        'product': product,
        'value': value,
        'tag_id': tag?.id,
        'product_id': product?.id,
      };

  @override
  String get modelName => 'tag';
}

class ProductTagClass extends ModelClass<ProductTag> {
  @override
  ProductTag initModel() => ProductTag();
}
