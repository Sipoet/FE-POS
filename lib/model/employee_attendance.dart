import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/employee.dart';
import 'package:flutter/material.dart';
export 'package:fe_pos/model/employee.dart';

export 'package:fe_pos/tool/custom_type.dart';

class EmployeeAttendance extends Model {
  DateTime startTime;
  DateTime endTime;
  Employee employee;
  int? id;
  EmployeeAttendance(
      {required this.startTime,
      required this.endTime,
      required this.employee,
      this.id});

  @override
  Map<String, dynamic> toMap() => {
        'start_time': startTime,
        'end_time': endTime,
        'employee_name': employee.name,
        'employee_id': employee.id,
        'date': date,
        'start_work': startWork,
        'end_work': endWork,
      };

  TimeOfDay get startWork => TimeOfDay.fromDateTime(startTime);
  TimeOfDay get endWork => TimeOfDay.fromDateTime(endTime);
  Date get date => Date.parsingDateTime(startTime);
  @override
  factory EmployeeAttendance.fromJson(Map<String, dynamic> json,
      {EmployeeAttendance? model, List included = const []}) {
    var attributes = json['attributes'];
    Employee employee = Employee(
        code: '',
        name: '',
        role: Role(name: ''),
        startWorkingDate: Date.today());
    final employeeRelated = json['relationships']['employee'];
    if (included.isNotEmpty && employeeRelated != null) {
      final employeeData = included.firstWhere((row) =>
          row['type'] == employeeRelated['data']['type'] &&
          row['id'] == employeeRelated['data']['id']);
      employee = Employee.fromJson(employeeData);
    }
    model ??= EmployeeAttendance(
        startTime: DateTime.now(), endTime: DateTime.now(), employee: employee);
    model.id = int.parse(json['id']);
    model.startTime = DateTime.parse(attributes['start_time']);
    model.endTime = DateTime.parse(attributes['end_time']);
    model.employee = employee;
    return model;
  }
}
