import 'package:fe_pos/model/employee.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/payslip.dart';

class PayslipReport extends Model {
  String employeeName;
  String? bank;
  String? bankAccount;
  String? bankRegisterName;
  EmployeeStatus employeeStatus;
  PayslipStatus payslipStatus;
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
      this.payslipStatus = PayslipStatus.draft,
      this.employeeStatus = EmployeeStatus.inactive,
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
      'employee_status': employeeStatus,
      'payslip_status': payslipStatus,
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
  String get modelName => 'payslip_report';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    startDate = Date.parse(attributes['start_date']);
    endDate = Date.parse(attributes['end_date']);

    employeeId = attributes['employee_id'];
    employeeName = attributes['employee_name'];
    employee = Employee(id: employeeId, name: employeeName);
    payslip = Payslip(id: payslipId);
    bank = attributes['bank'];
    bankAccount = attributes['bank_account'];
    bankRegisterName = attributes['bank_register_name'];
    employeeStatus = EmployeeStatus.fromString(attributes['employee_status']);
    payslipStatus = PayslipStatus.fromString(attributes['payslip_status']);
    sickLeave = attributes['sick_leave'];
    knownAbsence = attributes['known_absence'];
    unknownAbsence = attributes['unknown_absence'];
    overtimeHour = double.tryParse(attributes['overtime_hour'].toString()) ?? 0;
    late = attributes['late'] ?? late;
    workDays = double.tryParse(attributes['work_days'].toString()) ?? 0;

    totalDay = attributes['total_day'];
    description = attributes['description'];
    employeeStartWorkingDate =
        Date.parse(attributes['employee_start_working_date']);
    amountBasedPayrollType = {};
    nettSalary =
        Money.tryParse(attributes['nett_salary'] ?? '') ?? const Money(0);
    for (MapEntry<String, dynamic> val
        in attributes['payroll_type_amounts'].entries) {
      amountBasedPayrollType[val.key] =
          Money.tryParse(val.value ?? '0') ?? const Money(0);
    }
  }

  @override
  String get modelValue => payslip?.id.toString() ?? '';
}

class PayslipReportClass extends ModelClass<PayslipReport> {
  @override
  PayslipReport initModel() => PayslipReport(
      employeeId: 0,
      employeeName: '',
      startDate: Date.today(),
      endDate: Date.today());
}
