import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/payroll_line.dart';
export 'package:fe_pos/model/payroll_line.dart';
export 'package:fe_pos/tool/custom_type.dart';

class PayslipLine extends Model {
  PayrollGroup group;
  PayrollType? payrollType;
  PayrollFormula? formula;
  double amount;
  double? variable1;
  double? variable2;
  double? variable3;
  double? variable4;
  double? variable5;
  String description;
  PayslipLine({
    super.id,
    required this.group,
    this.payrollType,
    this.formula,
    this.description = '',
    required this.amount,
    this.variable1,
    this.variable2,
    this.variable3,
    this.variable4,
    this.variable5,
  });

  @override
  Map<String, dynamic> toMap() => {
        'group': group,
        'payroll_type': payrollType,
        'payroll_type_id': payrollType?.id,
        'amount': amount,
        'formula': formula,
        'description': description,
      };

  @override
  factory PayslipLine.fromJson(Map<String, dynamic> json,
      {PayslipLine? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= PayslipLine(group: PayrollGroup.earning, amount: 0);
    model.id = int.parse(json['id']);
    model.group = PayrollGroup.fromString(attributes['group']);
    model.payrollType = Model.findRelationData<PayrollType>(
        included: included,
        relation: json['relationships']['payroll_type'],
        convert: PayrollType.fromJson);
    try {
      model.formula = PayrollFormula.fromString(attributes['formula']);
    } catch (error) {
      model.formula = PayrollFormula.basic;
    }
    model.amount = double.parse(attributes['amount']);
    model.variable1 = double.tryParse(attributes['variable1'] ?? '');
    model.variable2 = double.tryParse(attributes['variable2'] ?? '');
    model.variable3 = double.tryParse(attributes['variable3'] ?? '');
    model.variable4 = double.tryParse(attributes['variable4'] ?? '');
    model.variable5 = double.tryParse(attributes['variable5'] ?? '');

    model.description = attributes['description'];
    return model;
  }
}
