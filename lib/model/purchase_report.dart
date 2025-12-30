import 'package:fe_pos/model/supplier.dart';
import 'package:fe_pos/model/model.dart';

enum PurchaseReportStatus implements EnumTranslation {
  noPaid,
  halfPaid,
  paid,
  overPaid;

  @override
  String toString() {
    if (this == noPaid) {
      return 'no_paid';
    } else if (this == halfPaid) {
      return 'half_paid';
    } else if (this == paid) {
      return 'paid';
    } else if (this == overPaid) {
      return 'over_paid';
    }
    return '';
  }

  factory PurchaseReportStatus.fromString(String value) {
    if (value == 'no_paid') {
      return noPaid;
    } else if (value == 'half_paid') {
      return halfPaid;
    } else if (value == 'paid') {
      return paid;
    } else if (value == 'over_paid') {
      return overPaid;
    }
    throw '$value is not valid purchase report status';
  }

  @override
  String humanize() {
    if (this == noPaid) {
      return 'Belum Bayar';
    } else if (this == halfPaid) {
      return 'Terbayar Sebagian';
    } else if (this == paid) {
      return 'Sudah Bayar';
    } else if (this == overPaid) {
      return 'Kelebihan Bayar';
    }
    return '';
  }
}

class PurchaseReport extends Model {
  String code;
  String supplierCode;
  DateTime purchaseDate;
  Date dueDate;
  PurchaseReportStatus status;
  double purchaseItemTotal;
  Money purchaseSubtotal;
  Money headerDiscountAmount;
  Money purchaseOtherCost;
  Money purchaseGrandTotal;
  DateTime orderDate;
  DateTime shippingDate;
  double orderItemTotal;
  Money orderGrandTotal;
  double returnItemTotal;
  Money returnAmountTotal;
  Money grandtotal;
  Money paidAmount;
  DateTime? lastPaidDate;
  Money debtAmount;
  Supplier supplier;
  PurchaseReport({
    super.id,
    Supplier? supplier,
    this.code = '',
    this.supplierCode = '',
    DateTime? purchaseDate,
    Date? dueDate,
    this.status = PurchaseReportStatus.noPaid,
    this.purchaseItemTotal = 0,
    this.purchaseSubtotal = const Money(0),
    this.headerDiscountAmount = const Money(0),
    this.purchaseOtherCost = const Money(0),
    this.purchaseGrandTotal = const Money(0),
    DateTime? orderDate,
    DateTime? shippingDate,
    this.orderItemTotal = 0,
    this.orderGrandTotal = const Money(0),
    this.returnItemTotal = 0,
    this.returnAmountTotal = const Money(0),
    this.grandtotal = const Money(0),
    this.paidAmount = const Money(0),
    this.lastPaidDate,
    this.debtAmount = const Money(0),
  })  : supplier = supplier ?? Supplier(),
        purchaseDate = purchaseDate ?? DateTime.now(),
        dueDate = dueDate ?? Date.today(),
        orderDate = orderDate ?? DateTime.now(),
        shippingDate = shippingDate ?? DateTime.now();
  @override
  String get modelName => 'purchase_report';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    if (included.isNotEmpty) {
      supplier = SupplierClass().findRelationData(
            included: included,
            relation: json['relationships']['supplier'],
          ) ??
          supplier;
    }
    status = PurchaseReportStatus.fromString(attributes['status']);
    code = attributes['code'];
    supplierCode = attributes['supplier_code'];
    purchaseItemTotal =
        double.tryParse(attributes['purchase_item_total']) ?? purchaseItemTotal;
    returnItemTotal =
        double.tryParse(attributes['return_item_total']) ?? returnItemTotal;
    orderItemTotal =
        double.tryParse(attributes['order_item_total']) ?? orderItemTotal;
    purchaseSubtotal =
        Money.tryParse(attributes['purchase_subtotal']) ?? purchaseSubtotal;
    headerDiscountAmount =
        Money.tryParse(attributes['header_discount_amount']) ??
            headerDiscountAmount;
    purchaseOtherCost =
        Money.tryParse(attributes['purchase_other_cost']) ?? purchaseOtherCost;
    purchaseGrandTotal = Money.tryParse(attributes['purchase_grand_total']) ??
        purchaseGrandTotal;
    orderGrandTotal =
        Money.tryParse(attributes['order_grand_total']) ?? orderGrandTotal;
    returnAmountTotal =
        Money.tryParse(attributes['return_amount_total']) ?? returnAmountTotal;
    grandtotal = Money.tryParse(attributes['grandtotal']) ?? grandtotal;
    paidAmount = Money.tryParse(attributes['paid_amount']) ?? paidAmount;
    debtAmount = Money.tryParse(attributes['debt_amount']) ?? debtAmount;
    purchaseDate =
        DateTime.tryParse(attributes['purchase_date'] ?? '') ?? purchaseDate;
    dueDate = Date.tryParse(attributes['due_date']) ?? dueDate;
    shippingDate =
        DateTime.tryParse(attributes['shipping_date'] ?? '') ?? shippingDate;
    orderDate = DateTime.tryParse(attributes['order_date'] ?? '') ?? orderDate;
    lastPaidDate = DateTime.tryParse(attributes['last_paid_date'] ?? '');
  }

  String get supplierName => supplier.name;

  @override
  Map<String, dynamic> toMap() => {
        'code': code,
        'supplier': "$supplierCode - $supplierName",
        'supplier_code': supplierCode,
        'supplier_name': supplierName,
        'purchase_date': purchaseDate,
        'due_date': dueDate,
        'purchase_item_total': purchaseItemTotal,
        'purchase_subtotal': purchaseSubtotal,
        'header_discount_amount': headerDiscountAmount,
        'purchase_other_cost': purchaseOtherCost,
        'purchase_grand_total': purchaseGrandTotal,
        'order_date': orderDate,
        'shipping_date': shippingDate,
        'order_item_total': orderItemTotal,
        'order_grand_total': orderGrandTotal,
        'return_item_total': returnItemTotal,
        'return_amount_total': returnAmountTotal,
        'grandtotal': grandtotal,
        'paid_amount': paidAmount,
        'last_paid_date': lastPaidDate,
        'debt_amount': debtAmount,
        'status': status.humanize(),
      };
  @override
  String get modelValue => code;
  @override
  String get path => '/purchases/report';
}

class PurchaseReportClass extends ModelClass<PurchaseReport> {
  @override
  PurchaseReport initModel() => PurchaseReport();
}
