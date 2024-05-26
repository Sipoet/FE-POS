import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

enum PayslipGroup {
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

  String humanize() {
    if (this == earning) {
      return 'penghasilan';
    } else if (this == deduction) {
      return 'potongan';
    }
    return '';
  }

  static PayslipGroup fromString(value) {
    if (value == 'earning') {
      return earning;
    }
    if (value == 'deduction') {
      return deduction;
    }
    throw 'invalid Payslip group';
  }
}

enum PayslipType {
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

  static PayslipType fromString(value) {
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
        throw 'invalid Payslip type';
    }
  }
}

class PayslipLine extends Model {
  PayslipGroup group;
  PayslipType? payslipType;
  double amount;
  String description;
  PayslipLine({
    super.id,
    required this.group,
    this.payslipType,
    this.description = '',
    required this.amount,
  });

  @override
  Map<String, dynamic> toMap() => {
        'group': group,
        'payslip_type': payslipType,
        'amount': amount,
        'description': description,
      };

  @override
  factory PayslipLine.fromJson(Map<String, dynamic> json,
      {PayslipLine? model}) {
    var attributes = json['attributes'];
    model ??= PayslipLine(group: PayslipGroup.earning, amount: 0);
    model.id = int.parse(json['id']);
    model.group = PayslipGroup.fromString(attributes['group']);
    model.payslipType = PayslipType.fromString(attributes['payslip_type']);
    model.amount = double.parse(attributes['amount']);

    model.description = attributes['description'];
    return model;
  }
}
