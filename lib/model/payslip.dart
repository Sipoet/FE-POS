import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/employee.dart';
import 'package:fe_pos/model/payslip_line.dart';
export 'package:fe_pos/model/payslip_line.dart';
export 'package:fe_pos/tool/custom_type.dart';

enum PayslipStatus {
  draft,
  confirmed,
  paid,
  cancelled;

  @override
  String toString() {
    return super.toString().split('.').last;
  }

  static PayslipStatus fromString(value) {
    switch (value) {
      case 'draft':
        return draft;
      case 'confirmed':
        return confirmed;
      case 'paid':
        return paid;
      case 'cancelled':
        return cancelled;
      default:
        throw 'not valid payslip status';
    }
  }
}

class Payslip extends Model {
  Employee employee;
  Payroll payroll;
  PayslipStatus status;
  Date startDate;
  Date endDate;
  DateTime? paymentTime;
  double grossSalary;
  String? notes;
  double taxAmount;
  double nettSalary;
  int sickLeave;
  int knownAbsence;
  int unknownAbsence;
  int paidTimeOff;
  int overtimeHour;
  int workDays;
  int late;
  int? id;
  List<PayslipLine> lines;
  Payslip(
      {required this.employee,
      required this.payroll,
      this.status = PayslipStatus.draft,
      required this.startDate,
      required this.endDate,
      this.paymentTime,
      this.grossSalary = 0,
      this.notes,
      this.taxAmount = 0,
      this.nettSalary = 0,
      this.sickLeave = 0,
      this.knownAbsence = 0,
      this.unknownAbsence = 0,
      this.paidTimeOff = 0,
      this.overtimeHour = 0,
      this.late = 0,
      this.workDays = 0,
      this.lines = const [],
      this.id});

  @override
  Map<String, dynamic> toMap() => {
        'employee.name': employee.name,
        'employee_id': employee.id,
        'payroll_id': payroll.id,
        'payroll.name': payroll.name,
        'status': status.toString(),
        'start_date': startDate,
        'end_date': endDate,
        'payment_time': paymentTime,
        'gross_salary': grossSalary,
        'notes': notes,
        'tax_amount': taxAmount,
        'nett_salary': nettSalary,
        'sick_leave': sickLeave,
        'known_absence': knownAbsence,
        'unknown_absence': unknownAbsence,
        'paid_time_off': paidTimeOff,
        'overtime_hour': overtimeHour,
        'work_days': workDays,
        'late': late,
      };

  @override
  factory Payslip.fromJson(Map<String, dynamic> json,
      {Payslip? model, List included = const []}) {
    var attributes = json['attributes'];
    Employee? employee;
    Payroll? payroll;
    if (included.isNotEmpty) {
      final payrollRelated = json['relationships']['payroll']?['data'];
      final employeeRelated = json['relationships']['employee']?['data'];
      if (payrollRelated != null) {
        final payrollData = included.firstWhere((row) =>
            row['type'] == payrollRelated['type'] &&
            row['id'] == payrollRelated['id']);
        if (payrollData != null) {
          payroll = Payroll.fromJson(payrollData);
        }
      }
      if (employeeRelated != null) {
        final employeeData = included.firstWhere((row) =>
            row['type'] == employeeRelated['type'] &&
            row['id'] == employeeRelated['id']);
        if (employeeData != null) {
          employee = Employee.fromJson(employeeData, included: included);
        }
      }
    }
    model ??= Payslip(
        employee: Employee(
            code: '',
            name: '',
            role: Role(name: ''),
            startWorkingDate: Date.today()),
        payroll: Payroll(name: ''),
        startDate: Date.today(),
        endDate: Date.today());
    model.id = int.parse(json['id']);
    model.employee = employee ?? model.employee;
    model.payroll = payroll ?? model.payroll;
    model.startDate = Date.parse(attributes['start_date']);
    model.endDate = Date.parse(attributes['end_date']);
    model.status = PayslipStatus.fromString(attributes['status']);
    model.paymentTime = DateTime.tryParse(attributes['payment_time'] ?? '');
    model.grossSalary = double.parse(attributes['gross_salary']);
    model.nettSalary = double.parse(attributes['nett_salary']);
    model.notes = attributes['notes'];
    model.taxAmount = double.parse(attributes['tax_amount']);
    model.sickLeave = attributes['sick_leave'];
    model.knownAbsence = attributes['known_absence'];
    model.unknownAbsence = attributes['unknown_absence'];
    model.paidTimeOff = attributes['paid_time_off'];
    model.overtimeHour = attributes['overtime_hour'];
    model.late = attributes['late'];
    model.workDays = attributes['work_days'];
    return model;
  }
}
