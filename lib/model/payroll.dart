import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/payroll_line.dart';
import 'package:fe_pos/model/work_schedule.dart';
export 'package:fe_pos/model/payroll_line.dart';
export 'package:fe_pos/tool/custom_type.dart';

class Payroll extends Model {
  String name;
  int paidTimeOff;
  int? id;
  String? description;
  List<PayrollLine> lines;
  List<WorkSchedule> schedules;
  Payroll({
    required this.name,
    this.id,
    this.paidTimeOff = 0,
    this.description,
    this.lines = const <PayrollLine>[],
    this.schedules = const <WorkSchedule>[],
  });

  @override
  Map<String, dynamic> toMap() => {
        'name': name,
        'paid_time_off': paidTimeOff,
        'description': description,
      };

  @override
  factory Payroll.fromJson(Map<String, dynamic> json, {Payroll? model}) {
    var attributes = json['attributes'];
    model ??= Payroll(name: '');
    model.id = int.parse(json['id']);
    model.name = attributes['name'];
    model.paidTimeOff = attributes['paid_time_off'];
    model.description = attributes['description'];
    return model;
  }
}
