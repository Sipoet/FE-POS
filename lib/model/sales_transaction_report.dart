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
      this.totalTransaction = 0,
      this.debitDetails = const [],
      this.creditDetails = const []});

  @override
  factory SalesTransactionReport.fromJson(Map<String, dynamic> json) {
    return SalesTransactionReport(
      range: DateTimeRange(
          start: DateTime.parse(json['start_time']),
          end: DateTime.parse(json['end_time'])),
      totalSales: Money.tryParse(json['sales_total']) ?? const Money(0),
      totalDebit: Money.tryParse(json['debit_total']) ?? const Money(0),
      totalCredit: Money.tryParse(json['credit_total']) ?? const Money(0),
      totalCash: Money.tryParse(json['cash_total']) ?? const Money(0),
      totalOnline: Money.tryParse(json['online_total']) ?? const Money(0),
      totalQRIS: Money.tryParse(json['qris_total']) ?? const Money(0),
      totalDiscount: Money.tryParse(json['discount_total']) ?? const Money(0),
      totalTransaction: json['num_of_transaction'] ?? 0,
    );
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
        'start_time': Date.parse(startDate.toIso8601String()),
        'end_time': Date.parse(endDate.toIso8601String()),
      };

  @override
  Map<String, dynamic> toJson() {
    var json = toMap();
    json['start_time'] = startDate.toIso8601String();
    json['end_time'] = endDate.toIso8601String();
    return json;
  }
}
