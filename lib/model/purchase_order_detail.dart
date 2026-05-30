import 'package:fe_pos/model/discount_detail.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/product.dart';

class PurchaseOrderDetail extends Model {
  Product? product;
  double quantity;
  Money price;
  Money subtotal;
  Money discountAmount;
  List<DiscountDetail>? discountDetails;
  Money total;
  String uom;
  List<Tagging> taggings = [];
  PurchaseOrderDetail({
    this.discountDetails,
    this.quantity = 0,
    this.product,
    List<Tagging>? taggings,
    this.subtotal = const Money(0),
    this.discountAmount = const Money(0),
    this.total = const Money(0),
    this.uom = 'pcs',
    this.price = const Money(0),
  }) : taggings = taggings ?? [];
  @override
  Map<String, dynamic> toMap() => {
    'product_code': productCode,
    'quantity': quantity,
    'discount_detail': discountDetails?.map((e) => e.asJson()).toList(),
    'product': product,
    'product_id': product?.id,
    'discount_amount': discountAmount,
    'taggings_attributes': taggings.map((e) => e.asJson()).toList(),
    'subtotal': subtotal,
    'price': price,
    'total': total,
    'uom': uom,
  };

  String? get productCode => product?.supplierProductCode;
  String get tagDescription => tags.map<String>((e) => e.value).join(' ');
  Percentage? get margin => product == null
      ? null
      : Percentage((product!.sellPrice.value / price.value) - 1);
  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    if (included.isNotEmpty) {
      product = ProductClass().findRelationData(
        included: included,
        relation: json['relationships']['product'],
      );
      taggings = TaggingClass().findRelationsData(
        included: included,
        relation: json['relationships']?['taggings'],
      );
    }
    quantity = double.tryParse(attributes['quantity'] ?? '0') ?? 0;
    final klass = DiscountDetailClass();
    discountDetails = (attributes['discount_detail'] as List)
        .map<DiscountDetail>(
          (e) => klass.fromJson({'attributes': e}, included: included),
        )
        .toList();
    discountAmount =
        Money.tryParse(attributes['discount_amount']) ?? const Money(0);
    subtotal = Money.tryParse(attributes['subtotal']) ?? const Money(0);
    total = Money.tryParse(attributes['total']) ?? const Money(0);
    price = Money.tryParse(attributes['price']) ?? const Money(0);
    uom = attributes['uom'];
  }

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

  List<Tag> get tags =>
      taggings.where((e) => e.tag != null).map<Tag>((e) => e.tag!).toList();
}

class PurchaseOrderDetailClass extends ModelClass<PurchaseOrderDetail> {
  @override
  PurchaseOrderDetail initModel() => PurchaseOrderDetail();
}
