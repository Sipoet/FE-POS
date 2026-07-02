import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/product.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/model/product_sell_price.dart';

class ItemVariant extends Product with SaveNDestroyModel {
  ImageModel? image;
  int? parentId;
  Product? parent;
  ItemVariant({
    super.id,
    super.description = '',
    super.barcode = '',
    this.image,
    this.parent,
    super.taggings,
    super.sellPrice,
    super.createdAt,
    super.updatedAt,
  });

  @override
  String get path => 'item_variants';
  @override
  String get createPath => 'products/${parentId.toString()}/item_variants';

  @override
  Map<String, dynamic> toMap() => {
    'description': description,
    'barcode': barcode,
    'sell_price': sellPrice,
    'parent_id': parentId,
    'supplier_product_code': supplierProductCode,
    'image': image,
    'taggings_attributes': taggings.map((e) => e.asJson()).toList(),
    'product_sell_price_attributes': productSellPrices
        .map((e) => e.asJson())
        .toList(),
  };

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'] ?? {};
    super.setFromJson(json, included: included);
    description = attributes['description'] ?? '';
    barcode = attributes['barcode'] ?? '';
    parentId = int.tryParse(attributes['parent_id'].toString());

    supplierProductCode = attributes['supplier_product_code'];
    sellPrice =
        Money.tryParse(attributes['sell_price'] ?? '0') ?? const Money(0);

    taggings = TaggingClass().findRelationsData(
      relation: json['relationships']?['taggings'],
      included: included,
    );
    image = ImageModelClass().findRelationData(
      relation: json['relationships']?['image'],
      included: included,
    );
    productSellPrices = ProductSellPriceClass().findRelationsData(
      relation: json['relationships']?['product_sell_prices'],
      included: included,
    );
    parent = ProductClass().findRelationData(
      relation: json['relationships']?['parent'],
      included: included,
    );
  }

  @override
  String get modelValue => description;
}

class ItemVariantClass extends ModelClass<ItemVariant> {
  @override
  ItemVariant initModel() => ItemVariant();

  @override
  Future<QueryResponse<ItemVariant>> finds(
    Server server,
    QueryRequest queryRequest, {
    int? parentId,
  }) async {
    final param = queryRequest.toQueryParam();
    return server
        .get(
          'products/$parentId/item_variants',
          queryParam: param,
          cancelToken: queryRequest.cancelToken,
        )
        .then(responseToStatusCode, onError: responseToError);
  }
}
