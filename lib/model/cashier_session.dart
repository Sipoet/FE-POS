import 'package:fe_pos/model/edc_settlement.dart';
import 'package:fe_pos/model/model.dart';

class CashierSession extends Model {
  Date date;
  Money totalIn;
  Money totalOut;
  List<EdcSettlement> edcSettlements;
  CashierSession({
    Date? date,
    DateTime? endTime,
    super.id,
    this.totalIn = const Money(0),
    this.totalOut = const Money(0),
    List<EdcSettlement>? edcSettlements,
    super.createdAt,
    super.updatedAt,
  }) : date = date ?? Date.today(),
       edcSettlements = edcSettlements ?? <EdcSettlement>[];

  @override
  Map<String, dynamic> toMap() => {
    'date': date,
    'total_in': totalIn,
    'total_out': totalOut,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
  @override
  String get modelName => 'cashier_session';
  @override
  String get modelValue => date.format();

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];
    super.setFromJson(json, included: included);
    date = Date.parse(attributes['date']);
    if (attributes['total_in'] != null) {
      totalIn = Money.parse(attributes['total_in']);
    }
    if (attributes['total_in'] != null) {
      totalOut = Money.parse(attributes['total_out']);
    }
  }
}

class CashierSessionClass extends ModelClass<CashierSession> {
  @override
  CashierSession initModel() => CashierSession();
}
