import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/model/role.dart';
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
  int? id;
  String code;
  Employee(
      {this.id,
      required this.code,
      required this.name,
      required this.role,
      this.debt = const Money(0),
      required this.startWorkingDate,
      this.endWorkingDate,
      this.description,
      this.idNumber,
      this.contactNumber,
      this.address,
      this.bank,
      this.bankAccount,
      this.status = EmployeeStatus.inactive});

  @override
  factory Employee.fromJson(Map<String, dynamic> json) {
    var attributes = json['attributes'];
    return Employee(
      id: int.parse(json['id']),
      code: attributes['code']?.trim(),
      name: attributes['name']?.trim(),
      role: Role.fromJson(attributes['role']['data']),
      status: EmployeeStatus.convertFromString(attributes['status'].toString()),
      startWorkingDate: Date.parse(attributes['start_working_date']),
      endWorkingDate: Date.tryParse(attributes['end_working_date'] ?? ''),
      debt: Money.parse(attributes['debt'] ?? 0),
      idNumber: attributes['id_number'],
      contactNumber: attributes['contact_number'],
      address: attributes['address'],
      bank: attributes['bank'],
      bankAccount: attributes['bank_account'],
      description: attributes['description'],
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'code': code.trim(),
        'name': name,
        'role_name': role.name,
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
        'bank_account': bankAccount,
      };

  void updateAttributes() {}
}
