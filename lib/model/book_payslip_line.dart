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
  String get modelName => 'book_payslip_line';
  @override
  void setFromJson(Map<String, dynamic> json, {List included = const []}) {
    var attributes = json['attributes'];
    super.setFromJson(json, included: included);
    group = PayrollGroup.fromString(attributes['group']);
    payrollType = PayrollTypeClass().findRelationData(
          included: included,
          relation: json['relationships']['payroll_type'],
        ) ??
        payrollType;
    employee = EmployeeClass().findRelationData(
          included: included,
          relation: json['relationships']['employee'],
        ) ??
        employee;
    amount = Money.parse(attributes['amount']);
    status = attributes['status'];
    description = attributes['description'];
    transactionDate = Date.parse(attributes['transaction_date']);
  }

  @override
  String get modelValue =>
      description ??
      '${group.toString()} ${payrollType.modelValue} ${id.toString()}';
}

class BookPayslipLineClass extends ModelClass<BookPayslipLine> {
  @override
  BookPayslipLine initModel() => BookPayslipLine();
}
