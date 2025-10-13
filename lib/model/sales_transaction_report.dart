import 'package:fe_pos/model/model.dart';
import 'package:flutter/material.dart';

class SalesTransactionReport extends Model {
  DateTimeRange range;
  Money totalSales;
  Money totalDebit;
  Money totalCash;
  Money totalCredit;
  Money totalQRIS;
  Money totalOnline;
  Money totalDiscount;
  int totalTransaction;
  Money grossProfit;
  List debitDetails = [];
  List creditDetails = [];
  SalesTransactionReport(
      {required this.range,
      this.totalSales = const Money(0.0),
      this.totalDebit = const Money(0.0),
      this.totalCash = const Money(0.0),
      this.totalCredit = const Money(0.0),
      this.totalQRIS = const Money(0.0),
      this.totalOnline = const Money(0.0),
      this.totalDiscount = const Money(0.0),
      this.grossProfit = const Money(0.0),
      this.totalTransaction = 0,
      this.debitDetails = const [],
      this.creditDetails = const [],
      super.id});

  @override
  String get modelName => 'sales_transaction_report';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    id = "${attributes['start_time']}-${attributes['end_time']}";
    range = DateTimeRange(
      start: DateTime.parse(attributes['start_time']).toLocal(),
      end: DateTime.parse(attributes['end_time']).toLocal(),
    );
    totalSales = Money.tryParse(attributes['sales_total']) ?? const Money(0);
    totalDebit = Money.tryParse(attributes['debit_total']) ?? const Money(0);
    totalCredit = Money.tryParse(attributes['credit_total']) ?? const Money(0);
    totalCash = Money.tryParse(attributes['cash_total']) ?? const Money(0);
    totalOnline = Money.tryParse(attributes['online_total']) ?? const Money(0);
    totalQRIS = Money.tryParse(attributes['qris_total']) ?? const Money(0);
    totalDiscount =
        Money.tryParse(attributes['discount_total']) ?? const Money(0);
    totalTransaction = attributes['num_of_transaction'] ?? 0;
    grossProfit = Money.tryParse(attributes['gross_profit']) ?? const Money(0);
  }

  DateTime get startDate => range.start;
  DateTime get endDate => range.end;

  @override
  Map<String, dynamic> toMap() => {
        'sales_total': totalSales,
        'debit_total': totalDebit,
        'credit_total': totalCredit,
        'cash_total': totalCash,
        'online_total': totalOnline,
        'qris_total': totalQRIS,
        'discount_total': totalDiscount,
        'num_of_transaction': totalTransaction,
        'gross_profit': grossProfit,
        'start_time': range.start,
        'end_time': range.end,
      };

  @override
  String get modelValue => id.toString();
}

class SalesTransactionReportClass extends ModelClass<SalesTransactionReport> {
  @override
  SalesTransactionReport initModel() => SalesTransactionReport(
      range: DateTimeRange(start: DateTime.now(), end: DateTime.now()));
}
