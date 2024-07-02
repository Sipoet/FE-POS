import 'package:fe_pos/model/employee.dart';
import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/payroll_line.dart';
export 'package:fe_pos/model/payroll_line.dart';
export 'package:fe_pos/tool/custom_type.dart';

class PayslipLine extends Model {
  PayrollGroup group;
  PayrollType? payslipType;
  PayrollFormula formula;
  double amount;
  String description;
  PayslipLine({
    super.id,
    required this.group,
    this.payslipType,
    PayrollFormula? formula,
    this.description = '',
    required this.amount,
  }) : formula = formula ?? PayrollFormula.basic;

  @override
  Map<String, dynamic> toMap() => {
        'group': group,
        'payslip_type': payslipType,
        'amount': amount,
        'formula': formula,
        'description': description,
      };

  @override
  factory PayslipLine.fromJson(Map<String, dynamic> json,
      {PayslipLine? model}) {
    var attributes = json['attributes'];
    model ??= PayslipLine(group: PayrollGroup.earning, amount: 0);
    model.id = int.parse(json['id']);
    model.group = PayrollGroup.fromString(attributes['group']);
    model.payslipType = PayrollType.fromString(attributes['payslip_type']);
    model.formula = PayrollFormula.fromString(attributes['formula']);
    model.amount = double.parse(attributes['amount']);

    model.description = attributes['description'];
    return model;
  }
}
