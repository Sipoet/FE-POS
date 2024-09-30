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
  Map<String, dynamic> toMap() => {
        'name': name,
        'initial': initial,
        'order': order,
        'is_show_on_payslip_desc': isShowOnPayslipDesc,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  @override
  factory PayrollType.fromJson(Map<String, dynamic> json,
      {PayrollType? model, List included = const []}) {
    var attributes = json['attributes'];

    model ??= PayrollType();

    Model.fromModel(model, attributes);
    model.id = int.parse(json['id']);
    model.name = attributes['name'];
    model.order = attributes['order'];
    model.isShowOnPayslipDesc = attributes['is_show_on_payslip_desc'] ?? false;
    model.initial = attributes['initial'] ?? '';
    return model;
  }
}
