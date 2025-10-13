import 'package:fe_pos/model/employee.dart';
export 'package:fe_pos/model/employee.dart';
import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';
export 'package:fe_pos/model/payroll.dart';
export 'package:fe_pos/model/payroll_type.dart';

class BookEmployeeAttendance extends Model {
  String? description;
  Employee? employee;
  Date startDate;
  Date endDate;
  bool? allowOvertime;
  bool? isLate;
  bool? isFlexible;
  BookEmployeeAttendance({
    super.id,
    super.createdAt,
    super.updatedAt,
    this.allowOvertime,
    this.isFlexible,
    this.isLate,
    Date? startDate,
    Date? endDate,
    this.description,
    Employee? employee,
  })  : startDate = startDate ?? Date.today(),
        employee = employee ?? Employee(),
        endDate = endDate ?? Date.today();

  @override
  String get modelName => 'book_employee_attendance';

  @override
  Map<String, dynamic> toMap() => {
        'employee': employee,
        'employee_id': employee?.id,
        'employee_name': employee?.name,
        'is_late': isLate,
        'is_flexible': isFlexible,
        'allow_overtime': allowOvertime,
        'description': description,
        'start_date': startDate,
        'end_date': endDate,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];

    super.setFromJson(json, included: included);

    employee = EmployeeClass().findRelationData(
          included: included,
          relation: json['relationships']?['employee'],
        ) ??
        employee;
    isFlexible = attributes['is_flexible'];
    isLate = attributes['is_late'];
    allowOvertime = attributes['allow_overtime'];
    description = attributes['description'];
    startDate = Date.parse(attributes['start_date']);
    endDate = Date.parse(attributes['end_date']);
  }

  @override
  String get modelValue =>
      description ??
      '${employee?.modelValue} ${startDate.format()} ${endDate.format()}';
}

class BookEmployeeAttendanceClass extends ModelClass<BookEmployeeAttendance> {
  @override
  BookEmployeeAttendance initModel() => BookEmployeeAttendance();
}
