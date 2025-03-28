import 'package:fe_pos/model/employee.dart';
export 'package:fe_pos/model/employee.dart';
import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';
export 'package:fe_pos/model/payroll.dart';
export 'package:fe_pos/model/payroll_type.dart';

class BookPayslipLine extends Model {
  PayrollGroup group;
  PayrollType payrollType;
  Money amount;
  String? description;
  Employee employee;
  Date transactionDate;
  String? status;
  BookPayslipLine({
    super.id,
    super.createdAt,
    super.updatedAt,
    this.status,
    Date? transactionDate,
    this.group = PayrollGroup.deduction,
    PayrollType? payrollType,
    this.description,
    Employee? employee,
    this.amount = const Money(0),
  })  : payrollType = payrollType ?? PayrollType(),
        employee = employee ?? Employee(),
        transactionDate = transactionDate ?? Date.today();

  @override
  Map<String, dynamic> toMap() => {
        'group': group,
        'payroll_type_name': payrollType.name,
        'payroll_type_id': payrollType.id,
        'payroll_type': payrollType,
        'employee': employee,
        'employee_id': employee.id,
        'employee_name': employee.name,
        'amount': amount,
        'status': status,
        'description': description,
        'transaction_date': transactionDate,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  @override
  factory BookPayslipLine.fromJson(Map<String, dynamic> json,
      {BookPayslipLine? model, List included = const []}) {
    var attributes = json['attributes'];
    model ??= BookPayslipLine();
    model.id = int.parse(json['id']);
    Model.fromModel(model, attributes);
    model.group = PayrollGroup.fromString(attributes['group']);
    model.payrollType = Model.findRelationData<PayrollType>(
            included: included,
            relation: json['relationships']['payroll_type'],
            convert: PayrollType.fromJson) ??
        model.payrollType;
    model.employee = Model.findRelationData<Employee>(
            included: included,
            relation: json['relationships']['employee'],
            convert: Employee.fromJson) ??
        model.employee;
    model.amount = Money.parse(attributes['amount']);
    model.status = attributes['status'];
    model.description = attributes['description'];
    model.transactionDate = Date.parse(attributes['transaction_date']);
    return model;
  }

  @override
  String get modelValue =>
      description ??
      '${group.toString()} ${payrollType.modelValue} ${id.toString()}';
}
