import 'package:fe_pos/model/discount_detail.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/product.dart';

class PurchaseOrderDetail extends Model {
  Product? product;
  double quantity;
  Money price;
  Money subtotal;
  Money discountAmount;
  List<DiscountDetail>? discountDetail;
  Money total;
  String uom;
  PurchaseOrderDetail({
    this.discountDetail,
    this.quantity = 0,
    this.product,
    this.subtotal = const Money(0),
    this.discountAmount = const Money(0),
    this.total = const Money(0),
    this.uom = 'pcs',
    this.price = const Money(0),
  });
  @override
  Map<String, dynamic> toMap() => {
    'product_code': productCode,
    'quantity': quantity,
    'discount_detail': discountDetail,
    'product': product,
    'product_id': product?.id,
    'discount_amount': discountAmount,
    'subtotal': subtotal,
    'total': total,
    'uom': uom,
  };

  String? get productCode => product?.supplierProductCode;

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    if (included.isNotEmpty) {
      product = ProductClass().findRelationData(
        included: included,
        relation: json['relationships']['product'],
      );
    }
    quantity = double.tryParse(attributes['quantity'] ?? '0') ?? 0;
    final klass = DiscountDetailClass();
    discountDetail = (attributes['discount_detail'] as List)
        .map<DiscountDetail>((e) => klass.fromJson(e))
        .toList();
    discountAmount =
        Money.tryParse(attributes['discount_amount']) ?? const Money(0);
    subtotal = Money.tryParse(attributes['subtotal']) ?? const Money(0);
    total = Money.tryParse(attributes['total']) ?? const Money(0);
    price = Money.tryParse(attributes['price']) ?? const Money(0);
    uom = attributes['uom'];
  }
}

class PurchaseOrderDetailClass extends ModelClass<PurchaseOrderDetail> {
  @override
  PurchaseOrderDetail initModel() => PurchaseOrderDetail();
}
