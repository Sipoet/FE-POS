import 'package:fe_pos/model/account.dart';
import 'package:fe_pos/model/model.dart';

enum CashTransactionType implements EnumTranslation {
  cashIn,
  out,
  transfer;

  @override
  String toString() {
    switch (this) {
      case cashIn:
        return 'cash_in';
      case out:
        return 'out';
      case transfer:
        return 'transfer';
    }
  }

  factory CashTransactionType.fromString(String value) {
    switch (value) {
      case 'cash_in':
        return cashIn;
      case 'cash_out':
        return out;
      case 'cash_transfer':
        return transfer;
      default:
        throw '$value is not valid cash transaction type';
    }
  }
  @override
  String humanize() {
    switch (this) {
      case cashIn:
        return 'Masuk';
      case out:
        return 'Keluar';
      case transfer:
        return 'Transfer';
    }
  }
}

class CashTransactionReport extends Model {
  DateTime transactionAt;
  String? description;
  String code;
  CashTransactionType transactionType;
  Money paymentAmount;
  Account paymentAccount;
  Account detailAccount;

  CashTransactionReport({
    super.id,
    super.updatedAt,
    this.code = '',
    this.description,
    this.transactionType = CashTransactionType.cashIn,
    Account? paymentAccount,
    Account? detailAccount,
    String? paymentAccountCode,
    String? detailAccountCode,
    DateTime? transactionAt,
    this.paymentAmount = const Money(0),
  }) : transactionAt = transactionAt ?? DateTime.now(),
       paymentAccount =
           paymentAccount ?? Account(code: paymentAccountCode ?? ''),
       detailAccount = detailAccount ?? Account(code: detailAccountCode ?? '');
  @override
  Map<String, dynamic> toMap() => {
    'transaction_at': transactionAt,
    'transaction_type': transactionType,
    'description': description,
    'payment_account': "${paymentAccount.code} - ${paymentAccount.name}",
    'detail_account': "${detailAccount.code} - ${detailAccount.name}",
    'payment_account_code': paymentAccount.code,
    'detail_account_code': detailAccount.code,
    'payment_amount': paymentAmount,
    'code': code,
  };

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];

    if (included.isNotEmpty) {
      paymentAccount =
          AccountClass().findRelationData(
            included: included,
            relation: json['relationships']?['payment_account'],
          ) ??
          paymentAccount;
      detailAccount =
          AccountClass().findRelationData(
            included: included,
            relation: json['relationships']?['detail_account'],
          ) ??
          detailAccount;
    }
    super.setFromJson(json, included: included);
    transactionAt = DateTime.parse(attributes['transaction_at'] ?? '');
    description = attributes['description'];
    paymentAmount = Money.parse(attributes['payment_amount'] ?? '0');
    if (attributes['transaction_type'] != null) {
      transactionType = CashTransactionType.fromString(
        attributes['transaction_type'],
      );
    }

    code = attributes['code'];
  }
}

class CashTransactionReportClass extends ModelClass<CashTransactionReport> {
  @override
  CashTransactionReport initModel() => CashTransactionReport();
}
