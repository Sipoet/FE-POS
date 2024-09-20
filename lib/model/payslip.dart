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

  String humanize() {
    switch (this) {
      case draft:
        return 'draft';
      case confirmed:
        return 'dikonfirm';
      case paid:
        return 'terbayar';
      case cancelled:
        return 'dibatalkan';
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
  double overtimeHour;
  double workDays;
  int late;
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
      super.id});

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
    model.overtimeHour = double.parse(attributes['overtime_hour']);
    model.late = attributes['late'];
    model.workDays = double.parse(attributes['work_days']);
    if (included.isNotEmpty) {
      model.payroll = Model.findRelationData<Payroll>(
              included: included,
              relation: json['relationships']['payroll'],
              convert: Payroll.fromJson) ??
          model.payroll;
      model.employee = Model.findRelationData<Employee>(
              included: included,
              relation: json['relationships']['employee'],
              convert: Employee.fromJson) ??
          model.employee;
      model.lines = Model.findRelationsData<PayslipLine>(
          relation: json['relationships']['payslip_lines'],
          included: included,
          convert: PayslipLine.fromJson);
    }
    return model;
  }
}
