import 'package:fe_pos/model/employee.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/payslip.dart';

class PayslipReport extends Model {
  String employeeName;
  String? bank;
  String? bankAccount;
  String? bankRegisterName;
  Date? employeeStartWorkingDate;
  int employeeId;
  Date startDate;
  Date endDate;
  Money nettSalary;
  Map<String, Money> amountBasedPayrollType;
  int totalDay;
  int sickLeave;
  int knownAbsence;
  int unknownAbsence;
  double overtimeHour;
  double workDays;
  Payslip? payslip;
  Employee? employee;
  int late;
  String? description;
  int? payslipId;
  PayslipReport(
      {required this.startDate,
      required this.endDate,
      required this.employeeId,
      required this.employeeName,
      this.employeeStartWorkingDate,
      this.payslipId,
      this.employee,
      this.payslip,
      this.totalDay = 0,
      this.sickLeave = 0,
      this.knownAbsence = 0,
      this.unknownAbsence = 0,
      this.overtimeHour = 0,
      this.late = 0,
      this.nettSalary = const Money(0),
      this.workDays = 0,
      this.amountBasedPayrollType = const {},
      this.description,
      super.id});

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {
      'employee_name': employeeName,
      'employee_id': employeeId,
      'employee': employee,
      'payslip': payslip,
      'start_date': startDate,
      'end_date': endDate,
      'employee_start_working_date': employeeStartWorkingDate,
      'total_day': totalDay,
      'sick_leave': sickLeave,
      'known_absence': knownAbsence,
      'unknown_absence': unknownAbsence,
      'overtime_hour': overtimeHour,
      'work_days': workDays,
      'late': late,
      'bank': bank,
      'nett_salary': nettSalary,
      'bank_register_name': bankRegisterName,
      'bank_account': bankAccount,
      'description': description,
    };
    for (MapEntry<String, Money> val in amountBasedPayrollType.entries) {
      result[val.key] = val.value;
    }
    return result;
  }

  @override
  factory PayslipReport.fromJson(Map<String, dynamic> json,
      {PayslipReport? model, List included = const []}) {
    var attributes = json['attributes'];

    model ??= PayslipReport(
        employeeId: 0,
        employeeName: '',
        startDate: Date.today(),
        endDate: Date.today());
    model.id = int.parse(json['id']);

    model.startDate = Date.parse(attributes['start_date']);
    model.endDate = Date.parse(attributes['end_date']);

    model.employeeId = attributes['employee_id'];
    model.employeeName = attributes['employee_name'];
    model.employee = Employee(id: model.employeeId, name: model.employeeName);
    model.payslip = Payslip(id: model.payslipId);
    model.bank = attributes['bank'];
    model.bankAccount = attributes['bank_account'];
    model.bankRegisterName = attributes['bank_register_name'];

    model.sickLeave = attributes['sick_leave'];
    model.knownAbsence = attributes['known_absence'];
    model.unknownAbsence = attributes['unknown_absence'];
    model.overtimeHour =
        double.tryParse(attributes['overtime_hour'].toString()) ?? 0;
    model.late = attributes['late'] ?? model.late;
    model.workDays = double.tryParse(attributes['work_days'].toString()) ?? 0;

    model.totalDay = attributes['total_day'];
    model.description = attributes['description'];
    model.employeeStartWorkingDate =
        Date.parse(attributes['employee_start_working_date']);
    model.amountBasedPayrollType = {};
    model.nettSalary =
        Money.tryParse(attributes['nett_salary'] ?? '') ?? const Money(0);
    for (MapEntry<String, dynamic> val
        in attributes['payroll_type_amounts'].entries) {
      model.amountBasedPayrollType[val.key] =
          Money.tryParse(val.value ?? '0') ?? const Money(0);
    }
    return model;
  }

  @override
  String get modelValue => payslip?.id.toString() ?? '';
}
