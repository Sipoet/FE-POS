export 'package:fe_pos/model/supplier.dart';
export 'package:fe_pos/model/location.dart';
import 'package:fe_pos/model/purchase_invoice_detail.dart';
export 'package:fe_pos/model/purchase_invoice_detail.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/purchase_order.dart';
export 'package:fe_pos/tool/custom_type.dart';
import 'package:fe_pos/tool/purchase_calculator.dart';
export 'package:fe_pos/tool/purchase_calculator.dart';
import 'package:fe_pos/tool/file_attachment.dart';

enum PurchaseInvoiceStatus implements EnumTranslation {
  draft,
  confirmed;

  @override
  String humanize() {
    switch (this) {
      case draft:
        return 'draft';
      case confirmed:
        return 'confirmed';
    }
  }

  @override
  String toString() {
    switch (this) {
      case draft:
        return 'draft';
      case confirmed:
        return 'confirmed';
    }
  }

  static PurchaseInvoiceStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return draft;
      case 'confirmed':
        return confirmed;
      default:
        throw 'unknow status of $value';
    }
  }
}

class PurchaseInvoice extends Model with SaveNDestroyModel, Tagable {
  String code;
  Supplier? supplier;
  Location? location;
  Date? transactionDate;
  DateTime? barcodedAt;
  DateTime? openedAt;
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
  PurchaseInvoiceStatus? status;
  Percentage? taxValue;
  PurchaseOrder? purchaseOrder;
  List<PurchaseInvoiceDetail> purchaseInvoiceDetails = [];
  List<FileAttachment>? documents;
  int? invoiceGroup;
  String? supplierTransactionNumber;
  PurchaseInvoice({
    this.code = '',
    this.supplier,
    this.location,
    this.taxType = .non,
    this.taxValue,
    this.status,
    this.transactionDate,
    this.discountDetails,
    this.description,
    super.id,
    this.barcodedAt,
    this.openedAt,
    super.createdAt,
    super.updatedAt,
    this.purchaseOrder,
    this.discountAmount = const Money(0),
    this.taxAmount = const Money(0),
    this.subtotal = const Money(0),
    this.grandtotal = const Money(0),
    this.discountTotal = const Money(0),
    this.costTotal = const Money(0),
    this.productTotal,
    this.documents,
    this.invoiceGroup,
    this.supplierTransactionNumber,
    List<Tagging>? taggings,

    List<PurchaseInvoiceDetail>? purchaseInvoiceDetails,
    List<CostDetail>? costDetails,
  }) {
    this.purchaseInvoiceDetails =
        purchaseInvoiceDetails ?? <PurchaseInvoiceDetail>[];
    this.costDetails = costDetails ?? [];
    initTaggings(taggings);
  }
  @override
  String get path => 'purchase_invoices';
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
    'barcoded_at': barcodedAt,
    'opened_at': openedAt,
    'status': status,
    'purchase_order': purchaseOrder,
    'purchase_order_id': purchaseOrder?.id,
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
    'invoice_group': invoiceGroup,
    'supplier_transaction_number': supplierTransactionNumber,
    'taggings_attributes': taggings,
    'cost_details_attributes': costDetails,
    'purchase_invoice_details_attributes': purchaseInvoiceDetails,
  };

  String? get supplierName => supplier?.name;

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    if (included.isNotEmpty) {
      purchaseInvoiceDetails = PurchaseInvoiceDetailClass().findRelationsData(
        included: included,
        relation: json['relationships']['purchase_invoice_details'],
      );
      supplier =
          SupplierClass().findRelationData(
            included: included,
            relation: json['relationships']['supplier'],
          ) ??
          Supplier(id: attributes['supplier_id']);
      location =
          LocationClass().findRelationData(
            included: included,
            relation: json['relationships']['location'],
          ) ??
          Location(id: attributes['location_id']);
      purchaseOrder = PurchaseOrderClass().findRelationData(
        included: included,
        relation: json['relationships']['purchase_order'],
      );
      costDetails = CostDetailClass().findRelationsData(
        included: included,
        relation: json['relationships']['cost_details'],
      );
      documents = FileAttachmentClass().findRelationsData(
        included: included,
        relation: json['relationships']['documents'],
      );
    }
    id = json['id'];
    code = attributes['code'] ?? '';
    transactionDate = Date.tryParse(attributes['transaction_date'] ?? '');
    barcodedAt = Date.tryParse(attributes['barcoded_at'] ?? '');
    openedAt = Date.tryParse(attributes['opened_at'] ?? '');
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
    try {
      status = PurchaseInvoiceStatus.fromString(attributes['status']);
    } catch (e) {
      debugPrint(e.toString());
    }
    invoiceGroup = int.tryParse(attributes['invoice_group'].toString());
    supplierTransactionNumber = attributes['supplier_transaction_number'];
  }

  @override
  String get modelValue => code;
}

class PurchaseInvoiceClass extends ModelClass<PurchaseInvoice> {
  @override
  PurchaseInvoice initModel() => PurchaseInvoice();
}
