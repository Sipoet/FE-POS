import 'package:fe_pos/model/model.dart';

class PayrollReport extends Model {
  Money salaryTotal;
  int employeeId;
  String employeeName;
  Date startWorkingDate;
  Map<String, Money> amountBasedPayrollType;
  PayrollReport(
      {this.salaryTotal = const Money(0),
      this.employeeId = 0,
      Date? startWorkingDate,
      this.employeeName = '',
      this.amountBasedPayrollType = const {}})
      : startWorkingDate = startWorkingDate ?? Date.today();
  @override
  Map<String, dynamic> toMap() {
    var result = {
      'employee_id': employeeId,
      'employee_name': employeeName,
      'salary_total': salaryTotal,
      'start_working_date': startWorkingDate,
    };
    for (MapEntry<String, Money> val in amountBasedPayrollType.entries) {
      result[val.key] = val.value;
    }
    return result;
  }

  @override
  factory PayrollReport.fromJson(Map<String, dynamic> json,
      {PayrollReport? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= PayrollReport();
    model.employeeId = attributes['employee_id'];
    model.employeeName = attributes['employee_name'];
    model.salaryTotal = Money.parse(attributes['salary_total']);
    model.startWorkingDate = Date.parse(attributes['start_working_date']);
    model.amountBasedPayrollType = {};
    for (MapEntry<String, dynamic> val
        in attributes['payroll_type_amount'].entries) {
      model.amountBasedPayrollType[val.key] = Money.parse(val.value ?? '0');
    }
    return model;
  }

  @override
  String get modelValue => employeeName;
}
