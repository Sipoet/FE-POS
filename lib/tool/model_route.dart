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
    'role': RolePage(),
    'discount': DiscountPage(),
    'employee_attendance': EmployeeAttendancePage(),
    'user': UserPage(),
    'holiday': HolidayPage(),
    'employee_leave': EmployeeLeavePage(),
    'payment_provider': PaymentProviderPage(),
    'payment_type': PaymentTypePage(),
    'payroll_type': PayrollTypePage(),
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
    'Supplier': (model) =>
        SupplierFormPage(key: ObjectKey(model), supplier: model as Supplier),
    'Item': (model) => ItemFormPage(key: ObjectKey(model), item: model as Item),
    'Brand': (model) =>
        BrandFormPage(key: ObjectKey(model), brand: model as Brand),
    'ItemType': (model) =>
        ItemTypeFormPage(key: ObjectKey(model), itemType: model as ItemType),
    'Payroll': (model) =>
        PayrollFormPage(key: ObjectKey(model), payroll: model as Payroll),
    'Payslip': (model) =>
        PayslipFormPage(key: ObjectKey(model), payslip: model as Payslip),
    'Employee': (model) =>
        EmployeeFormPage(key: ObjectKey(model), employee: model as Employee),
    'Role': (model) => RoleFormPage(key: ObjectKey(model), role: model as Role),
    'Discount': (model) =>
        DiscountFormPage(key: ObjectKey(model), discount: model as Discount),
    'EmployeeAttendance': (model) => EmployeeAttendanceFormPage(
        key: ObjectKey(model), employeeAttendance: model as EmployeeAttendance),
    'EmployeeLeave': (model) => EmployeeLeaveFormPage(
        key: ObjectKey(model), employeeLeave: model as EmployeeLeave),
    'Holiday': (model) =>
        HolidayFormPage(key: ObjectKey(model), holiday: model as Holiday),
    'User': (model) => UserFormPage(key: ObjectKey(model), user: model as User),
    'PaymentType': (model) => PaymentTypeFormPage(
        key: ObjectKey(model), paymentType: model as PaymentType),
    'PaymentProvider': (model) => PaymentProviderFormPage(
        key: ObjectKey(model), paymentProvider: model as PaymentProvider),
    'PayrollType': (model) => PayrollTypeFormPage(
        key: ObjectKey(model), payrollType: model as PayrollType),
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
