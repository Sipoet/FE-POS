import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/employee.dart';
export 'package:fe_pos/model/employee.dart';

export 'package:fe_pos/tool/custom_type.dart';

enum LeaveType {
  sickLeave,
  annualLeave,
  changeDay,
  maternalLeave;

  @override
  String toString() {
    if (this == sickLeave) {
      return 'sick_leave';
    }
    if (this == annualLeave) {
      return 'annual_leave';
    }
    if (this == changeDay) {
      return 'change_day';
    }
    if (this == maternalLeave) {
      return 'maternal_leave';
    }
    return '';
  }

  String humanize() {
    if (this == sickLeave) {
      return 'Cuti Sakit';
    }
    if (this == annualLeave) {
      return 'Izin';
    }
    if (this == maternalLeave) {
      return 'Cuti Hamil';
    }

    if (this == changeDay) {
      return 'Ganti Hari';
    }
    return '';
  }

  static LeaveType fromString(String value) {
    switch (value) {
      case 'sick_leave':
        return sickLeave;
      case 'annual_leave':
        return annualLeave;
      case 'change_day':
        return changeDay;
      case 'maternal_leave':
        return maternalLeave;
      default:
        throw 'invalid sick leave $value';
    }
  }
}

class EmployeeLeave extends Model {
  Date date;
  LeaveType leaveType;
  Employee employee;
  String? description;
  Date? changeDay;
  int? changeShift;
  int? id;
  EmployeeLeave(
      {required this.leaveType,
      required this.date,
      required this.employee,
      this.changeDay,
      this.changeShift,
      this.description,
      this.id});

  @override
  Map<String, dynamic> toMap() => {
        'employee.name': employee.name,
        'employee_id': employee.id,
        'date': date,
        'description': description,
        'change_day': changeDay,
        'change_shift': changeShift,
        'leave_type': leaveType.toString(),
      };

  @override
  factory EmployeeLeave.fromJson(Map<String, dynamic> json,
      {EmployeeLeave? model, List included = const []}) {
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
    model ??= EmployeeLeave(
        date: Date.today(),
        leaveType: LeaveType.annualLeave,
        employee: employee);
    model.id = int.parse(json['id']);
    model.date = Date.parse(attributes['date']);
    model.leaveType = LeaveType.fromString(attributes['leave_type'] ?? '');
    model.employee = employee;
    model.description = attributes['description'];
    model.changeDay = Date.tryParse(attributes['change_day'] ?? '');
    model.changeShift = attributes['change_shift'];
    return model;
  }
}
