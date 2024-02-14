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
  factory Employee.fromJson(Map<String, dynamic> json, {Employee? model}) {
    var attributes = json['attributes'];
    model ??= Employee(
        code: '',
        name: '',
        startWorkingDate: Date.today(),
        role: Role(name: ''));
    model.id = int.parse(json['id']);
    model.code = attributes['code']?.trim();
    model.name = attributes['name']?.trim();
    model.role = Role.fromJson(attributes['role']['data']);
    model.status =
        EmployeeStatus.convertFromString(attributes['status'].toString());
    model.startWorkingDate = Date.parse(attributes['start_working_date']);
    model.endWorkingDate = Date.tryParse(attributes['end_working_date'] ?? '');
    model.debt = Money.parse(attributes['debt'] ?? 0);
    model.idNumber = attributes['id_number'];
    model.contactNumber = attributes['contact_number'];
    model.address = attributes['address'];
    model.bank = attributes['bank'];
    model.bankAccount = attributes['start_time'];
    model.description = attributes['description'];

    return model;
  }

  @override
  Map<String, dynamic> toMap() => {
        'code': code.trim(),
        'name': name,
        'role_name': role.name,
        'status': status.toString(),
        'description': description,
        'start_working_date': startWorkingDate,
        'debt': debt,
        'end_working_date': endWorkingDate,
        'id_number': idNumber,
        'contact_Number': contactNumber,
        'address': address,
        'bank': bank,
        'bank_account': bankAccount,
      };

  void updateAttributes() {}
}
