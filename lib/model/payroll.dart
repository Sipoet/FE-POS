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
    this.lines = const <PayrollLine>[],
  });

  @override
  Map<String, dynamic> toMap() => {
        'name': name,
        'paid_time_off': paidTimeOff,
        'description': description,
      };

  @override
  factory Payroll.fromJson(Map<String, dynamic> json,
      {Payroll? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= Payroll(name: '');
    model.id = int.parse(json['id']);
    model.name = attributes['name'];
    model.paidTimeOff = attributes['paid_time_off'];
    model.description = attributes['description'];
    return model;
  }
}
