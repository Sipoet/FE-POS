import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/bank.dart';

enum PaymentType {
  debitCard,
  creditCard,
  qris,
  transfer,
  other,
  emoney,
  tap;

  @override
  String toString() {
    if (this == debitCard) {
      return 'debitCard';
    } else if (this == creditCard) {
      return 'creditCard';
    } else if (this == qris) {
      return 'qris';
    } else if (this == transfer) {
      return 'transfer';
    } else if (this == other) {
      return 'other';
    } else if (this == emoney) {
      return 'emoney';
    } else if (this == tap) {
      return 'tap';
    }
    return '';
  }

  factory PaymentType.convertFromString(String value) {
    if (value == 'qris') {
      return qris;
    } else if (value == 'transfer') {
      return transfer;
    } else if (value == 'debit_card') {
      return debitCard;
    } else if (value == 'credit_card') {
      return creditCard;
    } else if (value == 'other') {
      return other;
    } else if (value == 'emoney') {
      return emoney;
    } else if (value == 'tap') {
      return tap;
    }
    throw '$value is not valid employee marital status';
  }

  String humanize() {
    if (this == debitCard) {
      return 'Kartu Debit';
    } else if (this == creditCard) {
      return 'Kartu Kredit';
    } else if (this == qris) {
      return 'QRIS';
    } else if (this == transfer) {
      return 'Transfer';
    } else if (this == other) {
      return 'yang lain';
    } else if (this == emoney) {
      return 'E-Money';
    } else if (this == tap) {
      return 'Tap';
    }
    return '';
  }
}

class PaymentMethod extends Model {
  String name;
  String providerCode;
  Bank bank;
  PaymentType paymentType;
  PaymentMethod(
      {this.providerCode = '',
      Bank? bank,
      this.name = '',
      this.paymentType = PaymentType.other,
      super.id,
      super.createdAt,
      super.updatedAt})
      : bank = bank ?? Bank();
  @override
  factory PaymentMethod.fromJson(Map<String, dynamic> json,
      {List included = const [], PaymentMethod? model}) {
    final attributes = json['attributes'];

    model ??= PaymentMethod();
    model.id = json['id'];
    Model.fromModel(model, attributes);
    model.bank = Model.findRelationData<Bank>(
            included: included,
            relation: json['relationships']['bank'],
            convert: Bank.fromJson) ??
        Bank();
    model.providerCode = model.bank.code;
    model.paymentType =
        PaymentType.convertFromString(attributes['payment_type']);
    return model;
  }
  @override
  Map<String, dynamic> toMap() => {
        'name': name,
        'provider': providerCode,
        'payment_type': paymentType,
      };
  @override
  String get modelValue => name;
}
