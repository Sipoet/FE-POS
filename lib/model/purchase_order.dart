import 'package:fe_pos/model/cost_detail.dart';
import 'package:fe_pos/model/discount_detail.dart';
import 'package:fe_pos/model/location.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/purchase_order_detail.dart';
import 'package:fe_pos/model/supplier.dart';
import 'package:fe_pos/model/tag.dart';
import 'package:fe_pos/tool/file_attachment.dart';
import 'package:fe_pos/tool/purchase_calculator.dart';
export 'package:fe_pos/model/supplier.dart';
export 'package:fe_pos/model/purchase_order_detail.dart';
export 'package:fe_pos/model/discount_detail.dart';
export 'package:fe_pos/model/location.dart';
export 'package:fe_pos/model/cost_detail.dart';

class PurchaseOrder extends Model with SaveNDestroyModel, Tagable {
  String code;
  Supplier? supplier;
  Location? location;
  Date? transactionDate;
  List<DiscountDetail>? discountDetails;
  List<CostDetail> costDetails = [];
  Money discountAmount;
  String? description;
  Money subtotal;
  Money grandtotal;
  double? productTotal;
  Money discountTotal;
  Money costTotal;
  TaxType taxType;
  Money taxAmount;
  Percentage? taxValue;
  List<FileAttachment>? documents;

  List<PurchaseOrderDetail> purchaseOrderDetails = [];
  PurchaseOrder({
    this.code = '',
    this.supplier,
    this.location,
    this.taxType = .non,
    this.taxValue,
    this.transactionDate,
    this.discountDetails,
    this.description,
    super.id,
    super.createdAt,
    super.updatedAt,
    this.documents,
    this.discountAmount = const Money(0),
    this.taxAmount = const Money(0),
    this.subtotal = const Money(0),
    this.grandtotal = const Money(0),
    this.discountTotal = const Money(0),
    this.costTotal = const Money(0),
    this.productTotal,
    List<PurchaseOrderDetail>? purchaseOrderDetails,
    List<CostDetail>? costDetails,
  }) : purchaseOrderDetails = purchaseOrderDetails ?? [],
       costDetails = costDetails ?? [];

  @override
  Map<String, dynamic> toMap() => {
    'code': code,
    'transaction_date': transactionDate,
    'description': description,
    'product_total': productTotal,
    'subtotal': subtotal,
    'supplier': supplier,
    'supplier_id': supplier?.id,
    'location': location,
    'location_id': location?.id,
    'location_name': location?.name,
    'grandtotal': grandtotal,
    'discount_detail': discountDetails,
    'cost_total': costTotal,
    'sub_total': subtotal,
    'discount_total': discountTotal,
    'discount_amount': discountAmount,
    'supplier_name': supplierName,
    'tax_amount': taxAmount,
    'tax_type': taxType,
    'tax_value': taxValue,
    'documents': documents,
    'taggings_attributes': taggings,
    'cost_details_attributes': costDetails,
    'purchase_order_details_attributes': purchaseOrderDetails,
  };

  String? get supplierName => supplier?.name;

  @override
  String get path => 'purchase_orders';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    if (included.isNotEmpty) {
      purchaseOrderDetails = PurchaseOrderDetailClass().findRelationsData(
        included: included,
        relation: json['relationships']['purchase_order_details'],
      );
      supplier = SupplierClass().findRelationData(
        included: included,
        relation: json['relationships']['supplier'],
      );
      location = LocationClass().findRelationData(
        included: included,
        relation: json['relationships']['location'],
      );
      costDetails = CostDetailClass().findRelationsData(
        included: included,
        relation: json['relationships']['cost_details'],
      );
      documents = FileAttachmentClass().findRelationsData(
        included: included,
        relation: json['relationships']['documents'],
      );
      setTaggingsFromJson(json, included: included);
    }
    code = attributes['code'] ?? '';
    transactionDate = Date.tryParse(attributes['transaction_date'] ?? '');
    description = attributes['description'];
    productTotal = double.tryParse(attributes['product_total'].toString());
    subtotal = Money.tryParse(attributes['subtotal']) ?? const Money(0);
    grandtotal = Money.tryParse(attributes['grandtotal']) ?? const Money(0);
    discountAmount =
        Money.tryParse(attributes['discount_amount']) ?? const Money(0);
    costTotal = Money.tryParse(attributes['cost_total']) ?? const Money(0);
    discountTotal =
        Money.tryParse(attributes['discount_total']) ?? const Money(0);
    final klass = DiscountDetailClass();
    discountDetails = ((attributes['discount_detail'] ?? []) as List)
        .map<DiscountDetail>(
          (e) => klass.fromJson({'attributes': e}, included: included),
        )
        .toList();
    taxType = TaxType.fromString(attributes['tax_type'] ?? 'non');
    taxValue = Percentage.tryParse(attributes['tax_value']);
    taxAmount = Money.tryParse(attributes['tax_amount']) ?? const Money(0);
  }

  @override
  String get modelValue => code;
}

class PurchaseOrderClass extends ModelClass<PurchaseOrder> {
  @override
  PurchaseOrder initModel() => PurchaseOrder();
}
