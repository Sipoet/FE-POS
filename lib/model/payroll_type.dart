import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';

class PayrollType extends Model {
  String name;
  String initial;
  int order;
  bool isShowOnPayslipDesc;
  PayrollType({
    this.name = '',
    this.initial = '',
    this.order = 1,
    super.id,
    this.isShowOnPayslipDesc = false,
    super.createdAt,
    super.updatedAt,
  });

  @override
  String get modelName => 'payroll_type';

  @override
  Map<String, dynamic> toMap() => {
        'name': name,
        'initial': initial,
        'order': order,
        'is_show_on_payslip_desc': isShowOnPayslipDesc,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];
    super.setFromJson(json, included: included);
    name = attributes['name'];
    order = attributes['order'];
    isShowOnPayslipDesc = attributes['is_show_on_payslip_desc'] ?? false;
    initial = attributes['initial'] ?? '';
  }

  @override
  String get modelValue => name;
}

class PayrollTypeClass extends ModelClass<PayrollType> {
  @override
  PayrollType initModel() => PayrollType();
}
