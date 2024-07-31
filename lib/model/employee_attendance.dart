import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/employee.dart';
export 'package:fe_pos/model/employee.dart';

export 'package:fe_pos/tool/custom_type.dart';

class EmployeeAttendance extends Model {
  DateTime startTime;
  DateTime endTime;
  Employee employee;
  bool isLate;
  bool allowOvertime;
  int shift;
  EmployeeAttendance(
      {required this.startTime,
      required this.endTime,
      required this.employee,
      this.shift = 1,
      this.isLate = false,
      super.createdAt,
      super.updatedAt,
      this.allowOvertime = false,
      super.id});

  @override
  Map<String, dynamic> toMap() => {
        'start_time': startTime,
        'end_time': endTime,
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

  TimeDay get startWork => TimeDay.fromDateTime(startTime);
  TimeDay get endWork => TimeDay.fromDateTime(endTime);
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
      employee = Model.findRelationData<Employee>(
              included: included,
              relation: employeeRelated,
              convert: Employee.fromJson) ??
          employee;
    }
    model ??= EmployeeAttendance(
        startTime: DateTime.now(), endTime: DateTime.now(), employee: employee);
    model.id = int.parse(json['id']);
    model.startTime = DateTime.parse(attributes['start_time']);
    model.endTime = DateTime.parse(attributes['end_time']);
    Model.fromModel(model, attributes);
    model.employee = employee;
    model.isLate = attributes['is_late'] ?? false;
    model.allowOvertime = attributes['allow_overtime'] ?? false;
    model.shift = attributes['shift'];
    return model;
  }
}
