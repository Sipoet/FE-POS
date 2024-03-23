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

  String humanize() {
    if (this == LeaveType.sickLeave) {
      return 'Cuti Sakit';
    }
    if (this == LeaveType.annualLeave) {
      return 'Izin';
    }
    if (this == LeaveType.maternalLeave) {
      return 'Cuti Hamil';
    }

    if (this == LeaveType.changeDay) {
      return 'Ganti Hari';
    }
    return '';
  }
}

class EmployeeLeave extends Model {
  Date date;
  LeaveType leaveType;
  Employee employee;
  String? description;
  Date? changeDate;
  int? changeShift;
  int? id;
  EmployeeLeave(
      {required this.leaveType,
      required this.date,
      required this.employee,
      this.changeDate,
      this.changeShift,
      this.description,
      this.id});

  @override
  Map<String, dynamic> toMap() => {
        'employee.name': employee.name,
        'employee_id': employee.id,
        'date': date,
        'description': description,
        'change_date': changeDate,
        'change_shift': changeShift,
        'leave_type': leaveType,
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
      employee = Model.findRelationData<Employee>(
              included: included,
              relation: employeeRelated,
              convert: Employee.fromJson) ??
          employee;
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
    model.changeDate = Date.tryParse(attributes['change_date'] ?? '');
    model.changeShift = attributes['change_shift'];
    return model;
  }
}
