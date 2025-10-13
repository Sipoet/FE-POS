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
  String get modelName => 'payroll_report';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    employeeId = attributes['employee_id'];
    employeeName = attributes['employee_name'];
    salaryTotal = Money.parse(attributes['salary_total']);
    startWorkingDate = Date.parse(attributes['start_working_date']);
    amountBasedPayrollType = {};
    for (MapEntry<String, dynamic> val
        in attributes['payroll_type_amount'].entries) {
      amountBasedPayrollType[val.key] = Money.parse(val.value ?? '0');
    }
  }

  @override
  String get modelValue => employeeName;
}

class PayrollReportClass extends ModelClass<PayrollReport> {
  @override
  PayrollReport initModel() => PayrollReport();
}
