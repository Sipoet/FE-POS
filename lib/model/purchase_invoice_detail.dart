export 'package:fe_pos/model/product.dart';
import 'package:fe_pos/model/item_variant.dart';
import 'package:fe_pos/model/stock_keeping_unit.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/purchase_invoice.dart';
import 'package:fe_pos/model/purchase_order_detail.dart';
export 'package:fe_pos/tool/custom_type.dart';
export 'package:fe_pos/model/discount_detail.dart';
import 'package:fe_pos/model/unit_of_measurement.dart';

class PurchaseInvoiceDetail extends Model {
  Product? product;
  Supplier? supplier;
  double quantity;
  double? noteQuantity;
  Money price;
  Money subtotal;
  Money discountAmount;
  PurchaseOrderDetail? purchaseOrderDetail;
  List<DiscountDetail>? discountDetails;
  Money total;
  StockKeepingUnit? sku;
  UnitOfMeasurement? uom;
  List<Tagging> taggings = [];
  String? barcode;
  double? orderQuantityBasedDetailUom;
  PurchaseInvoice? purchaseInvoice;
  Date? expiredDate;
  Date? productionDate;
  double? orderQuantity;
  UnitOfMeasurement? orderUom;
  bool isNewVariant;
  int? rowNumber;
  PurchaseInvoiceDetail({
    this.discountDetails,
    this.quantity = 0,
    this.noteQuantity,
    this.product,
    this.barcode,
    this.orderUom,
    this.orderQuantity,
    this.orderQuantityBasedDetailUom,
    this.purchaseOrderDetail,
    this.sku,
    this.expiredDate,
    this.productionDate,
    this.rowNumber,
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
    'expired_date': expiredDate,
    'production_date': productionDate,
    'sell_price': sellPrice,
    'supplier': supplier,
    'row_number': rowNumber,
    'note_quantity': noteQuantity,
    'purchase_order_detail': purchaseOrderDetail,
    'purchase_order_detail_id': purchaseOrderDetail?.id,
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
  Percentage? get margin => product == null
      ? null
      : Percentage(
          price.value == 0 ? 0 : (product!.sellPrice.value / price.value) - 1,
        );

  ItemVariant? get itemVariant =>
      product is ItemVariant ? (product as ItemVariant) : null;

  Money get sellPrice => product?.sellPrice ?? const Money(0);

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
      orderUom = UnitOfMeasurementClass().findRelationData(
        relation: json['relationships']?['order_uom'],
        included: included,
      );
      sku = StockKeepingUnitClass().findRelationData(
        relation: json['relationships']?['sku'],
        included: included,
      );
    }
    orderQuantity = double.tryParse(attributes['order_quantity'].toString());
    orderQuantityBasedDetailUom = double.tryParse(
      attributes['order_quantity_based_detail_uom'].toString(),
    );
    rowNumber = attributes['row_number'];
    quantity = double.tryParse(attributes['quantity'].toString()) ?? 0;
    noteQuantity = double.tryParse(attributes['note_quantity'].toString()) ?? 0;
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
    expiredDate = Date.tryParse(attributes['expired_date'] ?? '');
    productionDate = Date.tryParse(attributes['production_date'] ?? '');
  }
}

class PurchaseInvoiceDetailClass extends ModelClass<PurchaseInvoiceDetail> {
  @override
  PurchaseInvoiceDetail initModel() => PurchaseInvoiceDetail();
}
