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

class EmployeeLeave extends Model with SaveNDestroyModel {
  Date date;
  LeaveType leaveType;
  Employee employee;
  String? description;
  Date? changeDate;
  int? changeShift;

  EmployeeLeave(
      {this.leaveType = LeaveType.annualLeave,
      Date? date,
      Employee? employee,
      super.createdAt,
      super.updatedAt,
      this.changeDate,
      this.changeShift,
      this.description,
      super.id})
      : employee = employee ?? EmployeeClass().initModel(),
        date = date ?? Date.today();

  @override
  Map<String, dynamic> toMap() => {
        'employee.name': employee.name,
        'employee_id': employee.id,
        'employee': employee,
        'date': date,
        'description': description,
        'change_date': changeDate,
        'change_shift': changeShift,
        'leave_type': leaveType,
      };

  @override
  String get modelName => 'employee_leave';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];

    employee = EmployeeClass().findRelationData(
          included: included,
          relation: json['relationships']['employee'],
        ) ??
        employee;

    id = int.parse(json['id']);
    date = Date.parse(attributes['date']);
    leaveType = LeaveType.fromString(attributes['leave_type'] ?? '');
    employee = employee;
    description = attributes['description'];
    changeDate = Date.tryParse(attributes['change_date'] ?? '');
    changeShift = attributes['change_shift'];
  }

  @override
  String get modelValue =>
      description ?? "${employee.modelValue} (${date.format()})";
}

class EmployeeLeaveClass extends ModelClass<EmployeeLeave> {
  @override
  EmployeeLeave initModel() => EmployeeLeave();
}
