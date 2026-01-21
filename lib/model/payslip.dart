import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/employee.dart';
import 'package:fe_pos/model/payslip_line.dart';
export 'package:fe_pos/model/payslip_line.dart';
export 'package:fe_pos/tool/custom_type.dart';

enum PayslipStatus implements EnumTranslation {
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

  @override
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
  int totalWorkDays;
  int late;
  List<PayslipLine> lines;
  Payslip({
    Employee? employee,
    Payroll? payroll,
    this.status = PayslipStatus.draft,
    Date? startDate,
    Date? endDate,
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
    this.totalWorkDays = 0,
    this.lines = const [],
    super.createdAt,
    super.updatedAt,
    super.id,
  }) : employee = employee ?? Employee(),
       payroll = payroll ?? Payroll(name: ''),
       startDate = startDate ?? Date.today(),
       endDate = endDate ?? Date.today();

  @override
  Map<String, dynamic> toMap() => {
    'employee_name': employee.name,
    'employee_id': employee.id,
    'payroll_id': payroll.id,
    'payroll': payroll,
    'employee': employee,
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
    'created_at': createdAt,
    'updated_at': updatedAt,
    'late': late,
    'total_day': totalWorkDays,
  };

  @override
  String get modelName => 'payslip';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];

    super.setFromJson(json, included: included);
    startDate = Date.parse(attributes['start_date']);
    endDate = Date.parse(attributes['end_date']);
    if (attributes['status'] != null) {
      status = PayslipStatus.fromString(attributes['status']);
    }

    paymentTime = DateTime.tryParse(attributes['payment_time'] ?? '');
    grossSalary = double.parse(attributes['gross_salary']);
    nettSalary = double.parse(attributes['nett_salary']);
    notes = attributes['notes'];
    taxAmount = double.parse(attributes['tax_amount']);
    sickLeave = attributes['sick_leave'];
    knownAbsence = attributes['known_absence'];
    unknownAbsence = attributes['unknown_absence'];
    paidTimeOff = attributes['paid_time_off'];
    overtimeHour = double.parse(attributes['overtime_hour']);
    late = attributes['late'];
    workDays = double.parse(attributes['work_days']);
    totalWorkDays = attributes['total_day'];
    if (included.isNotEmpty) {
      payroll =
          PayrollClass().findRelationData(
            included: included,
            relation: json['relationships']['payroll'],
          ) ??
          payroll;
      employee =
          EmployeeClass().findRelationData(
            included: included,
            relation: json['relationships']['employee'],
          ) ??
          employee;
      lines = PayslipLineClass().findRelationsData(
        relation: json['relationships']['payslip_lines'],
        included: included,
      );
    }
  }

  @override
  String get modelValue =>
      '${employee.code} - ${startDate.format(pattern: 'MMMM y')}';
}

class PayslipClass extends ModelClass<Payslip> {
  @override
  Payslip initModel() => Payslip();
}
