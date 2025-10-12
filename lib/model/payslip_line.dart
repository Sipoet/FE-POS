import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/payroll_line.dart';
export 'package:fe_pos/model/payroll_line.dart';
export 'package:fe_pos/tool/custom_type.dart';

class PayslipLine extends Model {
  PayrollGroup group;
  PayrollType? payrollType;
  PayrollFormula? formula;
  Money amount;
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
  String get modelName => 'payslip_line';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    group = PayrollGroup.fromString(attributes['group']);
    payrollType = PayrollTypeClass().findRelationData(
      included: included,
      relation: json['relationships']['payroll_type'],
    );
    try {
      formula = PayrollFormula.fromString(attributes['formula']);
    } catch (error) {
      formula = PayrollFormula.basic;
    }
    amount = Money.parse(attributes['amount']);
    variable1 = double.tryParse(attributes['variable1'] ?? '');
    variable2 = double.tryParse(attributes['variable2'] ?? '');
    variable3 = double.tryParse(attributes['variable3'] ?? '');
    variable4 = double.tryParse(attributes['variable4'] ?? '');
    variable5 = double.tryParse(attributes['variable5'] ?? '');
    description = attributes['description'];
  }

  @override
  String get modelValue => id.toString();
}

class PayslipLineClass extends ModelClass<PayslipLine> {
  @override
  PayslipLine initModel() =>
      PayslipLine(group: PayrollGroup.earning, amount: Money(0));
}
