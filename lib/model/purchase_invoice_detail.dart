export 'package:fe_pos/model/product.dart';
import 'package:fe_pos/model/stock_keeping_unit.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/purchase_invoice.dart';
export 'package:fe_pos/tool/custom_type.dart';
export 'package:fe_pos/model/discount_detail.dart';
import 'package:fe_pos/model/unit_of_measurement.dart';

class PurchaseInvoiceDetail extends Model {
  Product? product;
  Supplier? supplier;
  double quantity;
  Money price;
  Money subtotal;
  Money discountAmount;
  List<DiscountDetail>? discountDetails;
  Money total;
  StockKeepingUnit? sku;
  UnitOfMeasurement? uom;
  List<Tagging> taggings = [];
  String? barcode;
  PurchaseInvoice? purchaseInvoice;
  bool isNewVariant;
  PurchaseInvoiceDetail({
    this.discountDetails,
    this.quantity = 0,
    this.product,
    this.barcode,
    this.sku,
    this.isNewVariant = false,
    this.purchaseInvoice,
    List<Tagging>? taggings,
    this.subtotal = const Money(0),
    this.discountAmount = const Money(0),
    this.total = const Money(0),
    this.uom,
    this.price = const Money(0),
  }) : taggings = taggings ?? [];
  @override
  String get path => 'purchase_invoice_details';
  @override
  Map<String, dynamic> toMap() => {
    'barcode': barcode,
    'quantity': quantity,
    'purchase_invoice': purchaseInvoice,
    'transaction_date': purchaseInvoice?.transactionDate,
    'sell_price': sellPrice,
    'tags': tagDescription,
    'supplier': supplier,
    'product_category': product?.productCategory,
    'brand': product?.brand,
    'discount_detail': discountDetails?.map((e) => e.asJson()).toList(),
    'product': product,
    'product_id': product?.id,
    'product_code': productCode,
    'discount_amount': discountAmount,
    'taggings_attributes': taggings.map((e) => e.asJson()).toList(),
    'subtotal': subtotal,
    'margin': margin,
    'sku': sku,
    'price': price,
    'total': total,
    'uom': uom,
    'uom_id': uom?.id,
  };

  String? get productCode => product?.supplierProductCode;
  String get tagDescription => tags.map<String>((e) => e.value).join(' ');
  Percentage? get margin => product == null
      ? null
      : Percentage((product!.sellPrice.value / price.value) - 1);

  Money get sellPrice => product?.sellPrice ?? const Money(0);

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
      purchaseInvoice =
          PurchaseInvoiceClass().findRelationData(
            included: included,
            isRootIncluded: false,
            relation: json['relationships']?['purchase_invoice'],
          ) ??
          PurchaseInvoice(id: attributes['purchase_invoice_id']);
      supplier = SupplierClass().findRelationData(
        included: included,
        relation: json['relationships']?['supplier'],
      );
      uom = UnitOfMeasurementClass().findRelationData(
        relation: json['relationships']?['uom'],
        included: included,
      );
      sku = StockKeepingUnitClass().findRelationData(
        relation: json['relationships']?['sku'],
        included: included,
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
    barcode = attributes['barcode'];
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

class PurchaseInvoiceDetailClass extends ModelClass<PurchaseInvoiceDetail> {
  @override
  PurchaseInvoiceDetail initModel() => PurchaseInvoiceDetail();
}
