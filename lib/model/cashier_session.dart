import 'package:fe_pos/model/edc_settlement.dart';
import 'package:fe_pos/model/model.dart';

class CashierSession extends Model {
  DateTime startTime;
  DateTime endTime;
  Money totalCashIn;
  Money totalCashOut;
  Money totalDebit;
  Money totalCredit;
  Money totalQris;
  Money totalEmoney;
  Money totalTransfer;
  Money totalOtherIn;
  List<EdcSettlement> edcSettlements;
  CashierSession(
      {DateTime? startTime,
      DateTime? endTime,
      super.id,
      this.totalCashIn = const Money(0),
      this.totalCashOut = const Money(0),
      this.totalDebit = const Money(0),
      this.totalCredit = const Money(0),
      this.totalQris = const Money(0),
      this.totalEmoney = const Money(0),
      this.totalTransfer = const Money(0),
      this.totalOtherIn = const Money(0),
      List<EdcSettlement>? edcSettlements,
      super.createdAt,
      super.updatedAt})
      : startTime = startTime ?? DateTime.now(),
        endTime = endTime ?? DateTime.now(),
        edcSettlements = edcSettlements ?? <EdcSettlement>[];

  @override
  Map<String, dynamic> toMap() => {
        'start_time': startTime,
        'end_time': endTime,
        'total_cash_in': totalCashIn,
        'total_cash_out': totalCashOut,
        'total_debit': totalDebit,
        'total_credit': totalCredit,
        'total_qris': totalQris,
        'total_emoney': totalEmoney,
        'total_transfer': totalTransfer,
        'total_other_in': totalOtherIn,
      };

  @override
  factory CashierSession.fromJson(Map<String, dynamic> json,
      {CashierSession? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= CashierSession();
    model.id = json['id'];
    Model.fromModel(model, attributes);
    model.startTime = DateTime.parse(attributes['start_time']);
    model.endTime = DateTime.parse(attributes['end_time']);
    model.totalCashIn = Money.parse(attributes['total_cash_in']);
    model.totalCashOut = Money.parse(attributes['total_cash_out']);
    model.totalDebit = Money.parse(attributes['total_debit']);
    model.totalCredit = Money.parse(attributes['total_credit']);
    model.totalQris = Money.parse(attributes['total_qris']);
    model.totalEmoney = Money.parse(attributes['total_emoney']);
    model.totalTransfer = Money.parse(attributes['total_transfer']);
    model.totalOtherIn = Money.parse(attributes['total_other_in']);
    return model;
  }
}
