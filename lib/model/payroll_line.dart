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
    throw 'invalid Payroll group';
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
        throw 'invalid Payroll type';
    }
  }
}

enum PayrollFormula {
  basic,
  fulltime,
  overtimeHour,
  periodProportional;

  @override
  String toString() {
    if (this == overtimeHour) {
      return 'overtime_hour';
    }
    if (this == periodProportional) {
      return 'period_proportional';
    }
    return super.toString().split('.').last;
  }

  static PayrollFormula fromString(value) {
    switch (value) {
      case 'basic':
        return basic;
      case 'overtime_hour':
        return overtimeHour;
      case 'fulltime':
        return fulltime;
      case 'period_proportional':
        return periodProportional;
      default:
        throw 'invalid Payroll formula';
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
  int? id;
  String description;
  PayrollLine(
      {this.id,
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
        'group': group.toString(),
        'payroll_type': payrollType.toString(),
        'formula': formula.toString(),
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
