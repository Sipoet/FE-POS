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

enum Religion {
  buddhism,
  catholic,
  christian,
  hindu,
  islam,
  khonghucu,
  other;

  @override
  String toString() {
    switch (this) {
      case catholic:
        return 'catholic';
      case christian:
        return 'christian';
      case buddhism:
        return 'buddhism';
      case hindu:
        return 'hindu';
      case khonghucu:
        return 'khonghucu';
      case islam:
        return 'islam';
      case other:
        return 'other';
    }
  }

  factory Religion.fromString(String value) {
    switch (value) {
      case 'catholic':
        return catholic;
      case 'christian':
        return christian;
      case 'buddhism':
        return buddhism;
      case 'hindu':
        return hindu;
      case 'khonghucu':
        return khonghucu;
      case 'islam':
        return islam;
      case 'other':
        return other;
      default:
        throw '$value is not valid employee status';
    }
  }

  String humanize() {
    switch (this) {
      case catholic:
        return 'Katolik';
      case christian:
        return 'Kristen';
      case buddhism:
        return 'Budha';
      case hindu:
        return 'Hindu';
      case khonghucu:
        return 'Khonghucu';
      case islam:
        return 'Islam';
      case other:
        return 'Other';
    }
  }
}

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
  String? email;
  Religion religion;
  String? imageCode;
  String code;
  int shift;
  List<WorkSchedule> schedules;
  List<EmployeeDayOff> employeeDayOffs;
  EmployeeMaritalStatus maritalStatus;
  String? userCode;
  Employee(
      {super.id,
      this.code = '',
      this.name = '',
      this.userCode,
      Role? role,
      this.payroll,
      this.email,
      this.religion = Religion.other,
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
  String get modelName => 'employee';

  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    super.setFromJson(json, included: included);
    final attributes = json['attributes'];

    payroll = PayrollClass().findRelationData(
      included: included,
      relation: json['relationships']['payroll'],
    );
    role = RoleClass().findRelationData(
          included: included,
          relation: json['relationships']['role'],
        ) ??
        Role();

    super.setFromJson(json, included: included);
    employeeDayOffs = EmployeeDayOffClass().findRelationsData(
      relation: json['relationships']['employee_day_offs'],
      included: included,
    );
    schedules = WorkScheduleClass().findRelationsData(
      relation: json['relationships']['schedules'],
      included: included,
    );
    id = int.parse(json['id']);
    code = attributes['code']?.trim();
    name = attributes['name']?.trim();
    maritalStatus = EmployeeMaritalStatus.convertFromString(
        attributes['marital_status'] ??
            EmployeeMaritalStatus.single.toString());
    taxNumber = attributes['tax_number'];
    userCode = attributes['user_code'];
    status = EmployeeStatus.convertFromString(attributes['status'].toString());
    startWorkingDate = Date.parse(attributes['start_working_date']);
    endWorkingDate = Date.tryParse(attributes['end_working_date'] ?? '');
    debt = Money.parse(attributes['debt'] ?? 0);
    idNumber = attributes['id_number'];
    contactNumber = attributes['contact_number'];
    address = attributes['address'];
    bank = attributes['bank'];
    bankAccount = attributes['bank_account'];
    description = attributes['description'];
    imageCode = attributes['image_code'];
    shift = attributes['shift'];
    bankRegisterName = attributes['bank_register_name'];
    religion = Religion.fromString(attributes['religion']);
    email = attributes['email'];
  }

  @override
  Map<String, dynamic> toMap() => {
        'code': code.trim(),
        'name': name,
        'role': role,
        'email': email,
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
        'user_code': userCode,
        'religion': religion,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'bank_register_name': bankRegisterName,
      };

  @override
  String get modelValue => "$code - $name";
}

class EmployeeClass extends ModelClass<Employee> {
  @override
  Employee initModel() => Employee();
}
