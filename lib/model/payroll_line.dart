import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

enum PayrollGroup {
  earning,
  deduction;

  @override
  String toString() {
    if (this == earning) {
      return 'earning';
    }
    if (this == deduction) {
      return 'deduction';
    }
    return '';
  }

  static PayrollGroup fromString(value) {
    if (value == 'earning') {
      return earning;
    }
    if (value == 'deduction') {
      return deduction;
    }
    throw 'invalid Payroll group $value';
  }

  String humanize() {
    if (this == earning) {
      return 'penghasilan';
    } else if (this == deduction) {
      return 'potongan';
    }
    return '';
  }
}

enum PayrollType {
  baseSalary,
  incentive,
  insurance,
  debt,
  commission,
  tax;

  @override
  String toString() {
    if (this == baseSalary) {
      return 'base_salary';
    }
    return super.toString().split('.').last;
  }

  String humanize() {
    switch (this) {
      case baseSalary:
        return "gaji pokok";
      case incentive:
        return "tunjangan";
      case insurance:
        return "asuransi";
      case debt:
        return "hutang";
      case commission:
        return "komisi";
      case tax:
        return "pajak";
      default:
        throw 'invalid Payroll type';
    }
  }

  static PayrollType fromString(value) {
    switch (value) {
      case 'base_salary':
        return baseSalary;
      case 'incentive':
        return incentive;
      case 'insurance':
        return insurance;
      case 'debt':
        return debt;
      case 'commission':
        return commission;
      case 'tax':
        return tax;
      default:
        throw 'invalid Payroll type $value';
    }
  }
}

enum PayrollFormula {
  basic,
  fulltimeSchedule,
  overtimeHour,
  sickLeaveCut,
  annualLeaveCut,
  unscheduledOvertimeHour,
  hourlyDaily,
  fulltimeHourPerDay,
  periodProportional;

  @override
  String toString() {
    if (this == overtimeHour) {
      return 'overtime_hour';
    }
    if (this == periodProportional) {
      return 'period_proportional';
    }
    if (this == sickLeaveCut) {
      return 'sick_leave_cut';
    }
    if (this == annualLeaveCut) {
      return 'annual_leave_cut';
    }
    if (this == hourlyDaily) {
      return 'hourly_daily';
    }
    if (this == fulltimeSchedule) {
      return 'fulltime_schedule';
    }
    if (this == fulltimeHourPerDay) {
      return 'fulltime_hour_per_day';
    }
    return super.toString().split('.').last;
  }

  String humanize() {
    switch (this) {
      case basic:
        return "basic";
      case fulltimeSchedule:
        return "Fulltime Schedule";
      case overtimeHour:
        return "Overtime";
      case sickLeaveCut:
        return "berdasarkan jumlah sakit";
      case annualLeaveCut:
        return "berdasarkan jumlah cuti";
      case periodProportional:
        return "periode proportional";
      case hourlyDaily:
        return 'jam dalam hari per periode';
      case fulltimeHourPerDay:
        return 'fulltime_hour_per_day';
      default:
        throw 'invalid Payroll formula';
    }
  }

  static PayrollFormula fromString(value) {
    switch (value) {
      case 'basic':
        return basic;
      case 'overtime_hour':
        return overtimeHour;
      case 'fulltime_schedule':
        return fulltimeSchedule;
      case 'period_proportional':
        return periodProportional;
      case 'annual_leave_cut':
        return annualLeaveCut;
      case 'sick_leave_cut':
        return sickLeaveCut;
      case 'hourly_daily':
        return hourlyDaily;
      case 'fulltime_hour_per_day':
        return fulltimeHourPerDay;
      default:
        throw 'invalid Payroll formula $value';
    }
  }
}

class PayrollLine extends Model {
  PayrollGroup group;
  PayrollType? payrollType;
  PayrollFormula formula;
  double? variable1;
  double? variable2;
  double? variable3;
  double? variable4;
  double? variable5;
  int row;
  String description;
  PayrollLine(
      {super.id,
      this.row = 0,
      required this.group,
      this.payrollType,
      required this.formula,
      this.description = '',
      this.variable2,
      this.variable3,
      this.variable4,
      this.variable5,
      this.variable1});

  @override
  Map<String, dynamic> toMap() => {
        'row': row,
        'group': group,
        'payroll_type': payrollType,
        'formula': formula,
        'variable1': variable1,
        'variable2': variable2,
        'variable3': variable3,
        'variable4': variable4,
        'variable5': variable5,
        'description': description,
      };

  @override
  factory PayrollLine.fromJson(Map<String, dynamic> json,
      {PayrollLine? model}) {
    var attributes = json['attributes'];
    model ??=
        PayrollLine(group: PayrollGroup.earning, formula: PayrollFormula.basic);
    model.id = int.parse(json['id']);
    model.row = attributes['row'];
    model.group = PayrollGroup.fromString(attributes['group']);
    model.payrollType = PayrollType.fromString(attributes['payroll_type']);
    model.formula = PayrollFormula.fromString(attributes['formula']);
    model.variable1 = double.tryParse(attributes['variable1'] ?? '');
    model.variable2 = double.tryParse(attributes['variable2'] ?? '');
    model.variable3 = double.tryParse(attributes['variable3'] ?? '');
    model.variable4 = double.tryParse(attributes['variable4'] ?? '');
    model.variable5 = double.tryParse(attributes['variable5'] ?? '');
    model.description = attributes['description'];
    return model;
  }
}
