import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/employee_day_off.dart';
export 'package:fe_pos/model/employee_day_off.dart';
import 'package:fe_pos/model/role.dart';
export 'package:fe_pos/model/role.dart';
import 'package:fe_pos/model/payroll.dart';
export 'package:fe_pos/model/payroll.dart';
export 'package:fe_pos/tool/custom_type.dart';
import 'package:fe_pos/model/work_schedule.dart';
import 'package:fe_pos/tool/table_decorator.dart';
export 'package:fe_pos/model/work_schedule.dart';

enum EmployeeStatus {
  active,
  inactive;

  @override
  String toString() {
    if (this == active) {
      return 'active';
    } else if (this == inactive) {
      return 'inactive';
    }
    return '';
  }

  factory EmployeeStatus.convertFromString(String value) {
    if (value == 'active') {
      return active;
    } else if (value == 'inactive') {
      return inactive;
    }
    throw '$value is not valid employee status';
  }

  String humanize() {
    if (this == active) {
      return 'Aktif';
    } else if (this == inactive) {
      return 'Tidak Aktif';
    }
    return '';
  }
}

enum EmployeeMaritalStatus {
  single,
  married,
  married1Child,
  married2Child,
  married3OrMoreChild;

  @override
  String toString() {
    if (this == single) {
      return 'single';
    } else if (this == married) {
      return 'married';
    } else if (this == married1Child) {
      return 'married_1_child';
    } else if (this == married2Child) {
      return 'married_2_child';
    } else if (this == married3OrMoreChild) {
      return 'married_3_or_more_child';
    }
    return '';
  }

  factory EmployeeMaritalStatus.convertFromString(String value) {
    if (value == 'single') {
      return single;
    } else if (value == 'married') {
      return married;
    } else if (value == 'married_1_child') {
      return married1Child;
    } else if (value == 'married_2_child') {
      return married2Child;
    } else if (value == 'married_3_or_more_child') {
      return married3OrMoreChild;
    }
    throw '$value is not valid employee marital status';
  }

  String humanize() {
    if (this == single) {
      return 'single';
    } else if (this == married) {
      return 'Menikah tanpa anak';
    } else if (this == married1Child) {
      return 'Menikah tanggungan 1 anak';
    } else if (this == married2Child) {
      return 'Menikah tanggungan 2 anak';
    } else if (this == married3OrMoreChild) {
      return 'Menikah tanggungan 3 atau lebih anak';
    }
    return '';
  }
}

class Employee extends Model {
  String name;
  Role role;
  Payroll? payroll;
  EmployeeStatus status;
  Date startWorkingDate;
  Money debt;
  Date? endWorkingDate;
  String? idNumber;
  String? contactNumber;
  String? address;
  String? bank;
  String? bankAccount;
  String? description;
  String? bankRegisterName;
  String? taxNumber;

  String? imageCode;
  String code;
  int shift;
  List<WorkSchedule> schedules;
  List<EmployeeDayOff> employeeDayOffs;
  EmployeeMaritalStatus maritalStatus;
  Employee(
      {super.id,
      this.code = '',
      this.name = '',
      Role? role,
      this.payroll,
      this.debt = const Money(0),
      Date? startWorkingDate,
      this.endWorkingDate,
      this.description,
      this.idNumber,
      this.contactNumber,
      this.address,
      this.bank,
      this.shift = 1,
      this.imageCode,
      this.taxNumber,
      this.bankAccount,
      this.bankRegisterName,
      this.maritalStatus = EmployeeMaritalStatus.single,
      super.createdAt,
      super.updatedAt,
      List<WorkSchedule>? schedules,
      List<EmployeeDayOff>? employeeDayOffs,
      this.status = EmployeeStatus.inactive})
      : schedules = schedules ?? <WorkSchedule>[],
        startWorkingDate = startWorkingDate ?? Date.today(),
        role = role ?? Role(),
        employeeDayOffs = employeeDayOffs ?? <EmployeeDayOff>[];

  @override
  factory Employee.fromJson(Map<String, dynamic> json,
      {List included = const [], Employee? model}) {
    final attributes = json['attributes'];

    model ??= Employee();

    model.payroll = Model.findRelationData<Payroll>(
        included: included,
        relation: json['relationships']['payroll'],
        convert: Payroll.fromJson);
    model.role = Model.findRelationData<Role>(
            included: included,
            relation: json['relationships']['role'],
            convert: Role.fromJson) ??
        Role();

    Model.fromModel(model, attributes);
    model.employeeDayOffs = Model.findRelationsData<EmployeeDayOff>(
        relation: json['relationships']['employee_day_offs'],
        included: included,
        convert: EmployeeDayOff.fromJson);
    model.schedules = Model.findRelationsData<WorkSchedule>(
        relation: json['relationships']['schedules'],
        included: included,
        convert: WorkSchedule.fromJson);
    model.id = int.parse(json['id']);
    model.code = attributes['code']?.trim();
    model.name = attributes['name']?.trim();
    model.maritalStatus = EmployeeMaritalStatus.convertFromString(
        attributes['marital_status'] ??
            EmployeeMaritalStatus.single.toString());
    model.taxNumber = attributes['tax_number'];
    model.status =
        EmployeeStatus.convertFromString(attributes['status'].toString());
    model.startWorkingDate = Date.parse(attributes['start_working_date']);
    model.endWorkingDate = Date.tryParse(attributes['end_working_date'] ?? '');
    model.debt = Money.parse(attributes['debt'] ?? 0);
    model.idNumber = attributes['id_number'];
    model.contactNumber = attributes['contact_number'];
    model.address = attributes['address'];
    model.bank = attributes['bank'];
    model.bankAccount = attributes['bank_account'];
    model.description = attributes['description'];
    model.imageCode = attributes['image_code'];
    model.shift = attributes['shift'];
    model.bankRegisterName = attributes['bank_register_name'];
    return model;
  }

  @override
  Map<String, dynamic> toMap() => {
        'code': code.trim(),
        'name': name,
        'role': role,
        'payroll': payroll,
        'role.name': role.name,
        'role_id': role.id,
        'status': status,
        'description': description,
        'start_working_date': startWorkingDate,
        'debt': debt,
        'end_working_date': endWorkingDate,
        'id_number': idNumber,
        'contact_number': contactNumber,
        'address': address,
        'bank': bank,
        'image_code': imageCode,
        'bank_account': bankAccount,
        'payroll_id': payroll?.id,
        'shift': shift,
        'payroll.name': payroll?.name,
        'marital_status': maritalStatus,
        'tax_number': taxNumber,
        'bank_register_name': bankRegisterName,
      };

  @override
  String get modelValue => "$code - $name";
}
