import 'package:fe_pos/model/account.dart';
import 'package:fe_pos/model/model.dart';

enum PurchaseType {
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
    throw '$value is not valid discount calculation type';
  }

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
  DateTime purchaseAt;
  DateTime stockArrivedAt;
  PurchaseType purchaseType;
  String code;
  Money grandTotal;
  Money paymentAmount;
  Money discountAmount;
  Account? account;
  PurchasePaymentHistory(
      {super.id,
      this.code = '',
      this.description,
      this.purchaseType = PurchaseType.payment,
      this.grandTotal = const Money(0),
      this.paymentAmount = const Money(0),
      this.discountAmount = const Money(0),
      DateTime? purchaseAt,
      DateTime? stockArrivedAt,
      DateTime? transactionAt})
      : transactionAt = transactionAt ?? DateTime.now(),
        stockArrivedAt = stockArrivedAt ?? DateTime.now(),
        purchaseAt = purchaseAt ?? DateTime.now();
  @override
  Map<String, dynamic> toMap() => {
        'transaction_at': transactionAt,
      };
}

class PurchasePaymentHistoryClass extends ModelClass<PurchasePaymentHistory> {
  @override
  PurchasePaymentHistory initModel() => PurchasePaymentHistory();
}
