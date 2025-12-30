import 'package:fe_pos/model/account.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/purchase.dart';
import 'package:fe_pos/model/purchase_order.dart';

enum PurchaseType implements EnumTranslation {
  payment,
  returned,
  dp;

  @override
  String toString() {
    switch (this) {
      case payment:
        return 'payment';
      case returned:
        return 'return';
      case dp:
        return 'down_payment';
    }
  }

  factory PurchaseType.fromString(String value) {
    if (value == 'payment') {
      return payment;
    } else if (value == 'return') {
      return returned;
    } else if (value == 'down_payment') {
      return dp;
    }
    throw '$value is not valid purchase type';
  }

  @override
  String humanize() {
    switch (this) {
      case payment:
        return 'Payment';
      case returned:
        return 'Return';
      case dp:
        return 'DP';
    }
  }
}

class PurchasePaymentHistory extends Model {
  DateTime transactionAt;
  String? description;
  String? purchaseCode;
  String? purchaseOrderCode;
  DateTime? invoicedAt;
  DateTime stockArrivedAt;
  String code;
  Money grandTotal;
  Money paymentAmount;
  Money discountAmount;
  Money debtTotal;
  Money debtLeft;
  Account paymentAccount;
  PurchaseOrder? purchaseOrder;

  Supplier supplier;
  Purchase? purchase;
  PurchasePaymentHistory(
      {super.id,
      this.code = '',
      Supplier? supplier,
      String? supplierCode,
      this.description,
      Account? paymentAccount,
      String? paymentAccountCode,
      this.purchaseCode,
      this.purchase,
      this.purchaseOrder,
      this.purchaseOrderCode,
      this.grandTotal = const Money(0),
      this.paymentAmount = const Money(0),
      this.discountAmount = const Money(0),
      this.debtLeft = const Money(0),
      this.debtTotal = const Money(0),
      this.invoicedAt,
      DateTime? stockArrivedAt,
      DateTime? transactionAt})
      : transactionAt = transactionAt ?? DateTime.now(),
        stockArrivedAt = stockArrivedAt ?? DateTime.now(),
        supplier = supplier ?? Supplier(code: supplierCode ?? ''),
        paymentAccount =
            paymentAccount ?? Account(code: paymentAccountCode ?? '');
  @override
  Map<String, dynamic> toMap() => {
        'transaction_at': transactionAt,
        'invoiced_at': invoicedAt,
        'stock_arrived_at': stockArrivedAt,
        'description': description,
        'payment_account_code': paymentAccountCode,
        'payment_account': "${paymentAccount.code} - ${paymentAccount.name}",
        'discount_amount': discountAmount,
        'grand_total': grandTotal,
        'payment_amount': paymentAmount,
        'purchase_code': purchaseCode,
        'purchase_order_code': purchaseOrderCode,
        'code': code,
        'supplier_code': supplierCode,
        'supplier': "${supplier.code} - ${supplier.name}",
        'debt_left': debtLeft,
        'debt_total': debtTotal,
      };

  String get supplierCode => supplier.code;
  String get paymentAccountCode => paymentAccount.code;

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];

    if (included.isNotEmpty) {
      supplier = SupplierClass().findRelationData(
            included: included,
            relation: json['relationships']?['supplier'],
          ) ??
          Supplier(code: attributes['supplier_code'] ?? '');
      paymentAccount = AccountClass().findRelationData(
            included: included,
            relation: json['relationships']?['payment_account'],
          ) ??
          Account(code: attributes['payment_account_code'] ?? '');
      purchase = PurchaseClass().findRelationData(
        included: included,
        relation: json['relationships']?['purchase'],
      );
      purchaseOrder = PurchaseOrderClass().findRelationData(
        included: included,
        relation: json['relationships']?['purchase_order'],
      );
    }
    super.setFromJson(json, included: included);
    transactionAt = DateTime.parse(attributes['transaction_at'] ?? '');
    invoicedAt = DateTime.tryParse(attributes['invoiced_at'] ?? '');
    stockArrivedAt = DateTime.parse(attributes['stock_arrived_at'] ?? '');
    description = attributes['description'];
    discountAmount = Money.parse(attributes['discount_amount'] ?? '0');
    paymentAmount = Money.parse(attributes['payment_amount'] ?? '0');
    grandTotal = Money.parse(attributes['grand_total'] ?? '0');
    debtTotal = Money.parse(attributes['debt_total'] ?? '0');
    debtLeft = Money.parse(attributes['debt_left'] ?? '0');
    purchaseCode = attributes['purchase_code'];
    purchaseOrderCode = attributes['purchase_order_code'];
    code = attributes['code'];
  }
}

class PurchasePaymentHistoryClass extends ModelClass<PurchasePaymentHistory> {
  @override
  PurchasePaymentHistory initModel() => PurchasePaymentHistory();
}
