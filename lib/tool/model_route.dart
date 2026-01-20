import 'package:fe_pos/page/menu_page.dart';
import 'package:fe_pos/page/form_page.dart';
import 'package:fe_pos/model/all_model.dart';
import 'package:flutter/material.dart';

class ModelRoute {
  const ModelRoute();

  static const Map<String, Widget> _tablePages = {
    'Supplier': SupplierPage(),
    'Item': ItemPage(),
    'Brand': BrandPage(),
    'ItemType': ItemTypePage(),
    'Employee': EmployeePage(),
    'Payroll': PayrollPage(),
    'Payslip': PayslipPage(),
    'Role': RolePage(),
    'Discount': DiscountPage(),
    'EmployeeAttendance': EmployeeAttendancePage(),
    'User': UserPage(),
    'Holiday': HolidayPage(),
    'EmployeeLeave': EmployeeLeavePage(),
    'PaymentProvider': PaymentProviderPage(),
    'PaymentType': PaymentTypePage(),
    'PayrollType': PayrollTypePage(),
  };

  static const Map<String, Type> _modelList = {
    'Ipos::Supplier': Supplier,
    'Ipos::Item': Item,
    'Ipos::Brand': Brand,
    'Ipos::ItemType': ItemType,
    'Employee': Employee,
    'Payroll': Payroll,
    'Payslip': Payslip,
    'Role': Role,
    'Discount': Discount,
    'EmployeeAttendance': EmployeeAttendance,
    'User': User,
    'Holiday': Holiday,
    'EmployeeLeave': EmployeeLeave,
    'PaymentProvider': PaymentProvider,
    'PaymentType': PaymentType,
    'PayrollType': PayrollType,
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
      key: ObjectKey(model),
      employeeAttendance: model as EmployeeAttendance,
    ),
    'EmployeeLeave': (model) => EmployeeLeaveFormPage(
      key: ObjectKey(model),
      employeeLeave: model as EmployeeLeave,
    ),
    'Holiday': (model) =>
        HolidayFormPage(key: ObjectKey(model), holiday: model as Holiday),
    'User': (model) => UserFormPage(key: ObjectKey(model), user: model as User),
    'PaymentType': (model) => PaymentTypeFormPage(
      key: ObjectKey(model),
      paymentType: model as PaymentType,
    ),
    'PaymentProvider': (model) => PaymentProviderFormPage(
      key: ObjectKey(model),
      paymentProvider: model as PaymentProvider,
    ),
    'PayrollType': (model) => PayrollTypeFormPage(
      key: ObjectKey(model),
      payrollType: model as PayrollType,
    ),
    'Purchase': (model) =>
        PurchaseFormPage(key: ObjectKey(model), purchase: model as Purchase),
    'PurchaseOrder': (model) => PurchaseOrderFormPage(
      key: ObjectKey(model),
      purchaseOrder: model as PurchaseOrder,
    ),
    'PurchaseReturn': (model) => PurchaseReturnFormPage(
      key: ObjectKey(model),
      purchaseReturn: model as PurchaseReturn,
    ),
    'Transfer': (model) =>
        TransferFormPage(key: ObjectKey(model), transfer: model as Transfer),
    'Sale': (model) => SaleFormPage(key: ObjectKey(model), sale: model as Sale),
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

  ModelClass modelClassOf(String className) {
    return _modelClasses[className]!;
  }

  static final Map<String, ModelClass> _modelClasses = Map.unmodifiable({
    'Ipos::Item': ItemClass(),
    'Ipos::Account': AccountClass(),
    'PayrollType': PayrollTypeClass(),
    'Ipos::CustomerGroup': CustomerGroupClass(),
    'Ipos::Supplier': SupplierClass(),
    'Ipos::Brand': BrandClass(),
    'Ipos::ItemType': ItemTypeClass(),
    'Payroll': PayrollClass(),
    'Payslip': PayslipClass(),
    'Employee': EmployeeClass(),
    'EmployeeLeave': EmployeeLeaveClass(),
    'EmployeeAttendance': EmployeeAttendanceClass(),
    'Role': RoleClass(),
    'Discount': DiscountClass(),
    'Holiday': HolidayClass(),
    'User': UserClass(),
    'PaymentProvider': PaymentProviderClass(),
    'PaymentType': PaymentTypeClass(),
    'BookEmployeeAttendance': BookEmployeeAttendanceClass(),
    'BookPayslipLine': BookPayslipLineClass(),
    'Ipos::Purchase': PurchaseClass(),
    'Ipos::PurchaseOrder': PurchaseOrderClass(),
    'Ipos::PurchaseItem': PurchaseItemClass(),
    'Ipos::PurchaseReturn': PurchaseReturnClass(),
    'Ipos::Sale': SaleClass(),
    'Ipos::SaleItem': SaleItemClass(),
    'Ipos::Transfer': TransferClass(),
    'Ipos::TransferItem': TransferItemClass(),
  });
}
