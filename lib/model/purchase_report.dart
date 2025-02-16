import 'package:fe_pos/model/supplier.dart';
import 'package:fe_pos/model/model.dart';

class PurchaseReport extends Model {
  String code;
  String supplierCode;
  DateTime purchaseDate;
  Date dueDate;
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
  factory PurchaseReport.fromJson(Map<String, dynamic> json,
      {PurchaseReport? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= PurchaseReport();
    if (included.isNotEmpty) {
      model.supplier = Model.findRelationData<Supplier>(
              included: included,
              relation: json['relationships']['supplier'],
              convert: Supplier.fromJson) ??
          model.supplier;
    }
    model.id = json['id'];
    model.code = attributes['code'];
    model.supplierCode = attributes['supplier_code'];
    model.purchaseItemTotal =
        double.tryParse(attributes['purchase_item_total']) ??
            model.purchaseItemTotal;
    model.returnItemTotal = double.tryParse(attributes['return_item_total']) ??
        model.returnItemTotal;
    model.orderItemTotal =
        double.tryParse(attributes['order_item_total']) ?? model.orderItemTotal;
    model.purchaseSubtotal = Money.tryParse(attributes['purchase_subtotal']) ??
        model.purchaseSubtotal;
    model.headerDiscountAmount =
        Money.tryParse(attributes['header_discount_amount']) ??
            model.headerDiscountAmount;
    model.purchaseOtherCost =
        Money.tryParse(attributes['purchase_other_cost']) ??
            model.purchaseOtherCost;
    model.purchaseGrandTotal =
        Money.tryParse(attributes['purchase_grand_total']) ??
            model.purchaseGrandTotal;
    model.orderGrandTotal = Money.tryParse(attributes['order_grand_total']) ??
        model.orderGrandTotal;
    model.returnAmountTotal =
        Money.tryParse(attributes['return_amount_total']) ??
            model.returnAmountTotal;
    model.grandtotal =
        Money.tryParse(attributes['grandtotal']) ?? model.grandtotal;
    model.paidAmount =
        Money.tryParse(attributes['paid_amount']) ?? model.paidAmount;
    model.debtAmount =
        Money.tryParse(attributes['debt_amount']) ?? model.debtAmount;
    model.purchaseDate = DateTime.tryParse(attributes['purchase_date'] ?? '') ??
        model.purchaseDate;
    model.dueDate = Date.tryParse(attributes['due_date']) ?? model.dueDate;
    model.shippingDate = DateTime.tryParse(attributes['shipping_date'] ?? '') ??
        model.shippingDate;
    model.orderDate =
        DateTime.tryParse(attributes['order_date'] ?? '') ?? model.orderDate;
    model.lastPaidDate = DateTime.tryParse(attributes['last_paid_date'] ?? '');
    return model;
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
        'debt_amount': debtAmount
      };
}
