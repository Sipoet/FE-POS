import 'package:fe_pos/model/discount_detail.dart';
import 'package:fe_pos/model/item_variant.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/product.dart';
import 'package:fe_pos/model/unit_of_measurement.dart';

class PurchaseOrderDetail extends Model {
  Product? product;
  double quantity;
  String? barcode;
  Money price;
  Money subtotal;
  Money discountAmount;
  List<DiscountDetail>? discountDetails;
  Money total;
  int? rowNumber;
  UnitOfMeasurement? uom;
  List<Tagging> taggings = [];
  PurchaseOrderDetail({
    this.discountDetails,
    this.quantity = 0,
    this.product,
    this.barcode,
    this.rowNumber,
    List<Tagging>? taggings,
    this.subtotal = const Money(0),
    this.discountAmount = const Money(0),
    this.total = const Money(0),
    this.uom,
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
    'row_number': rowNumber,
    'total': total,
    'barcode': barcode,
    'uom': uom,
    'uom_id': uom?.id,
  };
  @override
  String get path => 'purchase_order_details';
  String? get productCode => product?.supplierProductCode;
  Percentage? get margin => product == null
      ? null
      : Percentage(
          price.value == 0 ? 0 : (product!.sellPrice.value / price.value) - 1,
        );

  ItemVariant? get itemVariant =>
      product is ItemVariant ? (product as ItemVariant) : null;

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    if (included.isNotEmpty) {
      final relation = json['relationships']?['product'];
      if (relation?['data']?['type'] == 'item_variant') {
        product = ItemVariantClass().findRelationData(
          included: included,
          relation: relation,
        );
      } else if (relation?['data']?['type'] == 'product') {
        product = ProductClass().findRelationData(
          included: included,
          relation: relation,
        );
      }
      taggings = TaggingClass().findRelationsData(
        included: included,
        relation: json['relationships']?['taggings'],
      );
      uom = UnitOfMeasurementClass().findRelationData(
        relation: json['relationships']?['uom'],
        included: included,
      );
    }
    rowNumber = attributes['row_number'];
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
    barcode = attributes['barcode'];
  }
}

class PurchaseOrderDetailClass extends ModelClass<PurchaseOrderDetail> {
  @override
  PurchaseOrderDetail initModel() => PurchaseOrderDetail();
}
