import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/server.dart';
import 'package:flutter/material.dart';
export 'package:fe_pos/model/model.dart';

class MonthlyExpenseReport extends Model {
  int year;
  int month;
  Date datePk;
  Money total;
  MonthlyExpenseReport({
    super.id,
    this.year = 0,
    this.month = 1,
    required this.datePk,
    this.total = const Money(0),
  });

  @override
  String get modelName => 'monthly_expense_report';
  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    final attributes = json['attributes'];
    year = attributes['year'] ?? year;
    month = attributes['month'] ?? month;
    datePk = Date.tryParse(attributes['date_pk'] ?? '') ?? Date(year, month);
    total = Money.parse(attributes['total']);
  }

  @override
  Map<String, dynamic> toMap() => {
        'year': year,
        'month': month,
        'date_pk': datePk,
        'total': total,
      };

  @override
  String get modelValue => datePk.format(pattern: 'MMMM yyyy');
}

class MonthlyExpenseReportClass extends ModelClass<MonthlyExpenseReport> {
  @override
  MonthlyExpenseReport initModel() =>
      MonthlyExpenseReport(datePk: Date.today());

  Future<List<MonthlyExpenseReport>?> groupBy(
      {required Server server,
      required DateTimeRange range,
      required String groupPeriod}) {
    Map<String, dynamic> params = {
      'start_date': range.start.toIso8601String(),
      'end_date': range.end.toIso8601String(),
      'group_period': groupPeriod,
    };

    return server
        .get('monthly_expense_reports/group_by', queryParam: params)
        .then((response) {
      if (response.statusCode == 200) {
        return response.data['data']
            .map<MonthlyExpenseReport>((json) =>
                fromJson(json, included: response.data['included'] ?? []))
            .toList();
      }
      return null;
    }, onError: (error) {
      debugPrint(error.toString());
      return null;
    });
  }
}
