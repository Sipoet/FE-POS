import 'package:fe_pos/model/employee.dart';
import 'package:fe_pos/model/model.dart';

class EmployeeAttendanceReport extends Model {
  String employeeName;
  int employeeId;
  int totalDay;
  double overtimeHour;
  int workDays;

  Employee? employee;
  List<AttendanceDetail> details = [];

  int? payslipId;
  EmployeeAttendanceReport({
    required this.employeeId,
    required this.employeeName,
    this.payslipId,
    this.employee,
    this.totalDay = 0,
    this.overtimeHour = 0,
    this.workDays = 0,
    super.id,
  });

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> result = {
      'employee_name': employeeName,
      'employee_id': employeeId,
      'employee': employee,
      'total_day': totalDay,
      'sick_leave': sickLeave,
      'known_absence': knownAbsence,
      'unknown_absence': unknownAbsence,
      'overtime_hour': overtimeHour,
      'work_days': workDays,
      'start_date': startDate,
      'end_date': endDate,
      'late': late,
    };
    return result;
  }

  @override
  String get modelName => 'payslip_report';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    var attributes = json['attributes'];
    employeeId = attributes['employee_id'];
    employeeName = attributes['employee_name'];
    employee = Employee(id: employeeId, name: employeeName);
    overtimeHour = double.tryParse(attributes['overtime_hour'].toString()) ?? 0;

    totalDay = attributes['total_day'];
    details = (attributes['details'] as List)
        .map<AttendanceDetail>(
          (detail) => AttendanceDetail(
            date: Date.parse(detail['date']),
            isLate: detail['is_late'],
            workHours: double.parse(detail['work_hours'].toString()),
            isSick: detail['is_sick'],
            isKnownLeave: detail['is_known_leave'],
            isUnknownLeave: detail['is_unknown_leave'],
            isAllowOvertime: detail['is_allow_overtime'],
            isPaidLeave: detail['is_paid_leave'],
            shift: detail['shift'],
          ),
        )
        .toList();
    workDays = details.where((e) => e.workHours > 0).length;
  }

  int get sickLeave => details.where((e) => e.isSick).length;
  int get knownAbsence => details.where((e) => e.isKnownLeave).length;
  int get unknownAbsence => details.where((e) => e.isUnknownLeave).length;
  int get late => details.where((e) => e.isLate).length;

  List<Date> get sickLeaveDates =>
      details.where((e) => e.isSick).map((e) => e.date).toList();
  List<Date> get knownAbsenceDates =>
      details.where((e) => e.isKnownLeave).map((e) => e.date).toList();
  List<Date> get unknownAbsenceDates =>
      details.where((e) => e.isUnknownLeave).map((e) => e.date).toList();
  List<Date> get lateDates =>
      details.where((e) => e.isLate).map((e) => e.date).toList();
  List<String> get workHourDetails => details
      .where((e) => e.workHours > 0)
      .map<String>((e) => "${e.date.format()}: ${e.workHours.format()}")
      .toList();
  Date? get startDate => details.firstOrNull?.date;
  Date? get endDate => details.lastOrNull?.date;

  @override
  String get modelValue => employee?.id.toString() ?? '';
}

class AttendanceDetail {
  Date date;
  bool isLate;
  bool isSick;
  bool isAllowOvertime;
  bool isPaidLeave;
  int shift;
  double workHours;
  bool isKnownLeave;
  bool isUnknownLeave;
  AttendanceDetail({
    required this.date,
    this.isPaidLeave = false,
    this.workHours = 0,
    this.shift = 0,
    this.isLate = false,
    this.isKnownLeave = false,
    this.isUnknownLeave = false,
    this.isSick = false,
    this.isAllowOvertime = false,
  });
}

class EmployeeAttendanceReportClass
    extends ModelClass<EmployeeAttendanceReport> {
  @override
  EmployeeAttendanceReport initModel() =>
      EmployeeAttendanceReport(employeeId: 0, employeeName: '');
}
