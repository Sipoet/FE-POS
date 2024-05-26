import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/role.dart';
export 'package:fe_pos/model/role.dart';
import 'package:fe_pos/model/payroll.dart';
export 'package:fe_pos/model/payroll.dart';
export 'package:fe_pos/tool/custom_type.dart';
import 'package:fe_pos/model/work_schedule.dart';

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

  String? imageCode;
  String code;
  int shift;
  List<WorkSchedule> schedules;
  Employee(
      {super.id,
      required this.code,
      required this.name,
      required this.role,
      this.payroll,
      this.debt = const Money(0),
      required this.startWorkingDate,
      this.endWorkingDate,
      this.description,
      this.idNumber,
      this.contactNumber,
      this.address,
      this.bank,
      this.shift = 1,
      this.imageCode,
      this.bankAccount,
      this.bankRegisterName,
      super.createdAt,
      super.updatedAt,
      this.schedules = const <WorkSchedule>[],
      this.status = EmployeeStatus.inactive});

  @override
  factory Employee.fromJson(Map<String, dynamic> json,
      {List included = const [], Employee? model}) {
    final attributes = json['attributes'];

    Payroll? payroll;
    Role role = Role(name: '');
    model ??= Employee(
        code: '', name: '', role: role, startWorkingDate: Date.today());
    if (included.isNotEmpty) {
      model.payroll = Model.findRelationData<Payroll>(
          included: included,
          relation: json['relationships']['payroll'],
          convert: Payroll.fromJson);
      model.role = Model.findRelationData<Role>(
              included: included,
              relation: json['relationships']['role'],
              convert: Role.fromJson) ??
          role;
    }
    model.id = int.parse(json['id']);
    model.code = attributes['code']?.trim();
    model.name = attributes['name']?.trim();
    model.payroll = payroll;
    model.role = role;
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
        'bank_register_name': bankRegisterName,
      };

  void updateAttributes() {}
}
