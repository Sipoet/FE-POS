import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/payroll_line.dart';
export 'package:fe_pos/model/payroll_line.dart';
export 'package:fe_pos/tool/custom_type.dart';

class Payroll extends Model {
  String name;
  int paidTimeOff;
  String? description;
  List<PayrollLine> lines;
  Payroll({
    required this.name,
    super.id,
    this.paidTimeOff = 0,
    this.description,
    List<PayrollLine>? lines,
  }) : lines = lines ?? <PayrollLine>[];

  @override
  Map<String, dynamic> toMap() => {
    'name': name,
    'paid_time_off': paidTimeOff,
    'description': description,
  };

  @override
  String get modelName => 'payroll';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    name = attributes['name'];
    paidTimeOff = attributes['paid_time_off'] ?? paidTimeOff;
    description = attributes['description'];
    lines = PayrollLineClass().findRelationsData(
      included: included,
      relation: json['relationships']?['payroll_lines'],
    );
  }

  @override
  String get modelValue => name;
}

class PayrollClass extends ModelClass<Payroll> {
  @override
  Payroll initModel() => Payroll(name: '');
}
