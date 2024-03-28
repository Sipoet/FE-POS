import 'package:fe_pos/model/model.dart';

class PayslipReport extends Model {
  String employeeName;
  String? bank;
  String? bankAccount;
  String? bankRegisterName;
  Date? employeeStartWorkingDate;
  int employeeId;
  Date startDate;
  Date endDate;
  double baseSalary;
  double taxAmount;
  double nettSalary;
  double positionalIncentive;
  double attendanceIncentive;
  double otherIncentive;
  double debt;
  int totalDay;
  int sickLeave;
  int knownAbsence;
  int unknownAbsence;
  int overtimeHour;
  int workDays;
  int late;
  int? id;
  PayslipReport(
      {required this.startDate,
      required this.endDate,
      this.baseSalary = 0,
      required this.employeeId,
      required this.employeeName,
      this.employeeStartWorkingDate,
      this.positionalIncentive = 0,
      this.attendanceIncentive = 0,
      this.otherIncentive = 0,
      this.totalDay = 0,
      this.taxAmount = 0,
      this.nettSalary = 0,
      this.sickLeave = 0,
      this.knownAbsence = 0,
      this.unknownAbsence = 0,
      this.overtimeHour = 0,
      this.late = 0,
      this.workDays = 0,
      this.debt = 0,
      this.id});

  @override
  Map<String, dynamic> toMap() => {
        'employee_name': employeeName,
        'employee_id': employeeId,
        'start_date': startDate,
        'end_date': endDate,
        'employee_start_working_date': employeeStartWorkingDate,
        'base_salary': baseSalary,
        'positional_incentive': positionalIncentive,
        'attendance_incentive': attendanceIncentive,
        'other_incentive': otherIncentive,
        'total_day': totalDay,
        'tax_amount': taxAmount,
        'nett_salary': nettSalary,
        'sick_leave': sickLeave,
        'known_absence': knownAbsence,
        'unknown_absence': unknownAbsence,
        'overtime_hour': overtimeHour,
        'work_days': workDays,
        'late': late,
        'debt': debt,
        'bank': bank,
        'bank_register_name': bankRegisterName,
        'bank_account': bankAccount,
      };

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

    model.baseSalary = double.parse(attributes['base_salary'].toString());
    model.nettSalary = double.parse(attributes['nett_salary']);
    model.employeeId = attributes['employee_id'];
    model.employeeName = attributes['employee_name'];
    model.bank = attributes['bank'];
    model.bankAccount = attributes['bank_account'];
    model.bankRegisterName = attributes['bank_register_name'];
    model.taxAmount = double.parse(attributes['tax_amount']);
    model.sickLeave = attributes['sick_leave'];
    model.knownAbsence = attributes['known_absence'];
    model.unknownAbsence = attributes['unknown_absence'];
    model.overtimeHour = attributes['overtime_hour'];
    model.late = attributes['late'] ?? model.late;
    model.workDays = attributes['work_days'];
    model.totalDay = attributes['total_day'];
    model.employeeStartWorkingDate =
        Date.parse(attributes['employee_start_working_date']);
    model.debt = double.parse(attributes['debt'].toString());
    model.positionalIncentive =
        double.parse(attributes['positional_incentive'].toString());
    model.attendanceIncentive =
        double.parse(attributes['attendance_incentive'].toString());
    model.otherIncentive =
        double.parse(attributes['other_incentive'].toString());
    return model;
  }
}
