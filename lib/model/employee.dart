import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/role.dart';
export 'package:fe_pos/model/role.dart';
import 'package:fe_pos/model/payroll.dart';
export 'package:fe_pos/model/payroll.dart';
export 'package:fe_pos/tool/custom_type.dart';

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
  int? id;
  String? imageCode;
  String code;
  int shift;
  Employee(
      {this.id,
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
      this.status = EmployeeStatus.inactive});

  @override
  factory Employee.fromJson(Map<String, dynamic> json,
      {List included = const []}) {
    final attributes = json['attributes'];
    Payroll? payroll;
    Role role = Role(name: '');
    if (included.isNotEmpty) {
      final payrollRelated = json['relationships']['payroll'];
      final roleRelated = json['relationships']['role'];
      if (payrollRelated != null) {
        final payrollData = included.firstWhere((row) =>
            row['type'] == payrollRelated['data']['type'] &&
            row['id'] == payrollRelated['data']['id']);
        payroll = Payroll.fromJson(payrollData);
      }

      if (roleRelated != null) {
        final roleData = included.firstWhere((row) =>
            row['type'] == roleRelated['data']['type'] &&
            row['id'] == roleRelated['data']['id']);
        role = Role.fromJson(roleData);
      }
    }
    return Employee(
        id: int.parse(json['id']),
        code: attributes['code']?.trim(),
        name: attributes['name']?.trim(),
        payroll: payroll,
        role: role,
        status:
            EmployeeStatus.convertFromString(attributes['status'].toString()),
        startWorkingDate: Date.parse(attributes['start_working_date']),
        endWorkingDate: Date.tryParse(attributes['end_working_date'] ?? ''),
        debt: Money.parse(attributes['debt'] ?? 0),
        idNumber: attributes['id_number'],
        contactNumber: attributes['contact_number'],
        address: attributes['address'],
        bank: attributes['bank'],
        bankAccount: attributes['bank_account'],
        description: attributes['description'],
        imageCode: attributes['image_code'],
        shift: attributes['shift'],
        bankRegisterName: attributes['bank_register_name']);
  }

  @override
  Map<String, dynamic> toMap() => {
        'code': code.trim(),
        'name': name,
        'role.name': role.name,
        'role_id': role.id,
        'status': status.toString(),
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
