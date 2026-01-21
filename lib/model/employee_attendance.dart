import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/employee.dart';
export 'package:fe_pos/model/employee.dart';
import 'package:flutter/material.dart' show TimeOfDay;
export 'package:fe_pos/tool/custom_type.dart';

class EmployeeAttendance extends Model {
  DateTime startTime;
  DateTime endTime;
  Date date;
  Employee employee;
  bool isLate;
  bool allowOvertime;
  int shift;
  EmployeeAttendance({
    DateTime? startTime,
    DateTime? endTime,
    Date? date,
    Employee? employee,
    this.shift = 1,
    this.isLate = false,
    super.createdAt,
    super.updatedAt,
    this.allowOvertime = false,
    super.id,
  }) : startTime = startTime ?? DateTime.now(),
       endTime = endTime ?? DateTime.now(),
       employee = employee ?? EmployeeClass().initModel(),
       date = date ?? Date.today();

  @override
  Map<String, dynamic> toMap() => {
    'start_time': startTime,
    'end_time': endTime,
    'employee': employee,
    'employee.name': employee.name,
    'employee_id': employee.id,
    'date': date,
    'start_work': startWork,
    'end_work': endWork,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'is_late': isLate,
    'shift': shift,
    'allow_overtime': allowOvertime,
  };

  TimeOfDay get startWork => TimeOfDay.fromDateTime(startTime.toLocal());
  TimeOfDay get endWork => TimeOfDay.fromDateTime(endTime.toLocal());
  @override
  String get modelName => 'employee_attendance';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    final employeeRelated = json['relationships']['employee'];
    if (included.isNotEmpty && employeeRelated != null) {
      employee =
          EmployeeClass().findRelationData(
            included: included,
            relation: employeeRelated,
          ) ??
          employee;
    }
    startTime = DateTime.parse(attributes['start_time']).toLocal();
    endTime = DateTime.parse(attributes['end_time']).toLocal();
    date = Date.parse(attributes['date']);
    employee = employee;
    isLate = attributes['is_late'] ?? false;
    allowOvertime = attributes['allow_overtime'] ?? false;
    shift = attributes['shift'] ?? shift;
  }

  @override
  String get modelValue => "${employee.modelValue} (${date.format()})";
}

class EmployeeAttendanceClass extends ModelClass<EmployeeAttendance> {
  @override
  EmployeeAttendance initModel() => EmployeeAttendance();
}
