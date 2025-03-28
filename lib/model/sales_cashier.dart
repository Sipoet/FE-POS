import 'package:fe_pos/model/customer.dart';
export 'package:fe_pos/model/customer.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/sales_cashier_item.dart';
import 'package:fe_pos/model/sales_payment.dart';
export 'package:fe_pos/model/sales_cashier_item.dart';
export 'package:fe_pos/model/sales_payment.dart';

enum SalesTaxType {
  non,
  include,
  exclude;

  @override
  String toString() {
    switch (this) {
      case non:
        return 'non';
      case include:
        return 'include';
      case exclude:
        return 'exclude';
    }
  }
}

class SalesCashier extends Model {
  String code;
  DateTime transactionDate;
  String description;
  String location;
  int totalItem;
  Percentage? headerDiscountPercentage;
  Percentage? taxPercentage;
  Money headerDiscountAmount;
  List<SalesCashierItem> salesCashierItems = [];
  List<SalesPayment> salesPayments = [];
  Customer? customer;
  SalesTaxType taxType;
  Money taxAmount;
  Money otherCost;
  Money roundAmount;
  SalesCashier(
      {this.code = '',
      this.description = '',
      DateTime? transactionDate,
      this.location = '',
      this.headerDiscountAmount = const Money(0),
      this.otherCost = const Money(0),
      this.taxAmount = const Money(0),
      this.roundAmount = const Money(0),
      this.taxPercentage,
      this.headerDiscountPercentage,
      this.customer,
      this.totalItem = 0,
      this.taxType = SalesTaxType.non,
      this.salesCashierItems = const <SalesCashierItem>[],
      this.salesPayments = const <SalesPayment>[],
      super.id,
      super.createdAt,
      super.updatedAt})
      : transactionDate = transactionDate ?? DateTime.now();

  @override
  Map<String, dynamic> toMap() => {
        'code': code,
        'transaction_date': transactionDate,
        'description': description,
        'location': location,
        // 'totalitem': totalItem,
        // 'subtotal': subtotal,
        // 'totalakhir': grandtotal,
        // 'potnomfaktur': discountAmount,
        // 'biayalain': otherCost,
        // 'jmltunai': cashAmount,
        // 'jmldebit': debitCardAmount,
        // 'jmlkk': creditCardAmount,
        // 'jmlemoney': emoneyAmount,
        // 'payment_type': paymentMethodType,
        // 'ppn': taxType,
        // 'pajak': taxAmount,
        // 'bank_code': bankCode,
        // 'notransaksi': code,
      };

  Money get subtotal => salesCashierItems
      .map<Money>((line) => line.total)
      .toList()
      .fold(const Money(0), (a, b) => a + b);

  Money get grandTotal => _calculateGrandTotal();

  _calculateGrandTotal() {
    Money total = subtotal - headerDiscountAmount + otherCost + roundAmount;
    if (total < 0) {
      return const Money(0);
    } else {
      return total;
    }
  }

  Money get payAmount => salesPayments
      .map<Money>((line) => line.amount)
      .fold(const Money(0), (a, b) => a + b);

  @override
  factory SalesCashier.fromJson(Map<String, dynamic> json,
      {SalesCashier? model, List included = const []}) {
    var attributes = json['attributes'];

    model ??= SalesCashier();
    model.code = attributes['code'];
    model.description = attributes['description'];
    model.location = attributes['location'];
    model.transactionDate = DateTime.parse(attributes['transaction_date']);
    if (included.isNotEmpty) {
      model.salesCashierItems = Model.findRelationsData<SalesCashierItem>(
          included: included,
          relation: json['relationships']['sales_cashier_items'],
          convert: SalesCashierItem.fromJson);
      model.salesPayments = Model.findRelationsData<SalesPayment>(
          included: included,
          relation: json['relationships']['sales_payments'],
          convert: SalesPayment.fromJson);
      model.customer = Model.findRelationData<Customer>(
          included: included,
          relation: json['relationships']['customer'],
          convert: Customer.fromJson);
    }
    Model.fromModel(model, attributes);
    model.id = json['id'];
    // model.userName = attributes['user1'];
    // model.datetime = DateTime.parse(attributes['tanggal']);
    // model.description = attributes['keterangan'];
    // model.totalItem = double.parse(attributes['totalitem']);
    // model.subtotal = Money.tryParse(attributes['subtotal']) ?? const Money(0);
    // model.grandtotal =
    //     Money.tryParse(attributes['totalakhir']) ?? const Money(0);
    // model.discountAmount =
    //     Money.tryParse(attributes['potnomfaktur']) ?? const Money(0);
    // model.otherCost = Money.tryParse(attributes['biayalain']) ?? const Money(0);
    // model.cashAmount = Money.tryParse(attributes['jmltunai']) ?? const Money(0);
    // model.debitCardAmount =
    //     Money.tryParse(attributes['jmldebit']) ?? const Money(0);
    // model.creditCardAmount =
    //     Money.tryParse(attributes['jmlkk']) ?? const Money(0);
    // model.emoneyAmount =
    //     Money.tryParse(attributes['jmlemoney']) ?? const Money(0);
    // model.paymentMethodType = attributes['payment_type'] ?? '';
    // model.taxType = attributes['ppn'];
    // model.taxAmount = Money.tryParse(attributes['pajak']) ?? const Money(0);
    // model.code = attributes['notransaksi'];
    // model.bankCode = attributes['bank_code'] ?? '';
    return model;
  }

  @override
  String get modelValue => id;
}
