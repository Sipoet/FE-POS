import 'package:fe_pos/page/menu_page.dart';
import 'package:fe_pos/page/form_page.dart';
import 'package:fe_pos/model/all_model.dart';
import 'package:flutter/material.dart';

class ModelRoute {
  const ModelRoute();

  static const Map<String, Widget> _tablePages = {
    'supplier': SupplierPage(),
    'item': ItemPage(),
    'brand': BrandPage(),
    'item_type': ItemTypePage(),
    'employee': EmployeePage(),
    'payroll': PayrollPage(),
    'payslip': PayslipPage(),
  };

  static const Map<String, Type> _modelList = {
    'supplier': Supplier,
    'item': Item,
    'brand': Brand,
    'item_type': ItemType,
    'employee': Employee,
    'payroll': Payroll,
    'payslip': Payslip,
    'role': Role,
    'discount': Discount,
    'employee_attendance': EmployeeAttendance,
    'user': User,
    'holiday': Holiday,
    'employee_leave': EmployeeLeave,
    'payment_provider': PaymentProvider,
    'payment_type': PaymentType,
    'payroll_type': PayrollType,
  };

  static final Map<String, Widget Function(Model model)> _detailPages = {
    'supplier': (model) => SupplierFormPage(supplier: model as Supplier),
    'Item': (model) => ItemFormPage(item: model as Item),
    'Brand': (model) => BrandFormPage(brand: model as Brand),
    'ItemType': (model) => ItemTypeFormPage(itemType: model as ItemType),
    'Payroll': (model) => PayrollFormPage(payroll: model as Payroll),
    'Payslip': (model) => PayslipFormPage(payslip: model as Payslip),
    'Employee': (model) => EmployeeFormPage(employee: model as Employee),
    'Role': (model) => RoleFormPage(role: model as Role),
    'Discount': (model) => DiscountFormPage(discount: model as Discount),
    'EmployeeAttendance': (model) => EmployeeAttendanceFormPage(
        employeeAttendance: model as EmployeeAttendance),
    'EmployeeLeave': (model) =>
        EmployeeLeaveFormPage(employeeLeave: model as EmployeeLeave),
    'Holiday': (model) => HolidayFormPage(holiday: model as Holiday),
    'User': (model) => UserFormPage(user: model as User),
    'PaymentType': (model) =>
        PaymentTypeFormPage(paymentType: model as PaymentType),
    'PaymentProvider': (model) =>
        PaymentProviderFormPage(paymentProvider: model as PaymentProvider),
    'PayrollType': (model) =>
        PayrollTypeFormPage(payrollType: model as PayrollType),
  };

  Type classOf(String className) {
    return _modelList[className]!;
  }

  Widget tablePageOf(String className) {
    return _tablePages[className]!;
  }

  Widget detailPageOf(Model model) {
    return _detailPages[model.runtimeType.toString()]!.call(model);
  }
}
