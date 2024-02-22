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
  int? id;
  String description;
  PayslipLine({
    this.id,
    required this.group,
    this.payslipType,
    this.description = '',
    required this.amount,
  });

  @override
  Map<String, dynamic> toMap() => {
        'group': group.toString(),
        'payslip_type': payslipType.toString(),
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
