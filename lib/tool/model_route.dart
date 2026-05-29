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
    'Ipos::Brand': IposBrand,
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
    'PurchaseInvoice': (model) => PurchaseInvoiceFormPage(
      key: ObjectKey(model),
      purchaseInvoice: model as PurchaseInvoice,
    ),
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
    'ConsignmentIn': (model) => ConsignmentInFormPage(
      key: ObjectKey(model),
      consignmentIn: model as ConsignmentIn,
    ),
    'ConsignmentInOrder': (model) => ConsignmentInOrderFormPage(
      key: ObjectKey(model),
      consignmentInOrder: model as ConsignmentInOrder,
    ),
  };

  Type classOf(String className) {
    return _modelList[className]!;
  }

  Widget tablePageOf(String className) {
    return _tablePages[className]!;
  }

  Widget? detailPageOf(Model model) {
    return _detailPages[model.runtimeType.toString()]?.call(model);
  }

  ModelClass? modelClassOf(String className) {
    try {
      return _modelClasses[className]!;
    } catch (e) {
      debugPrint('className: $className not found');
      return null;
    }
  }

  static final Map<String, ModelClass> _modelClasses = Map.unmodifiable({
    'Ipos::Item': ItemClass(),
    'Ipos::Account': IposAccountClass(),
    'Ipos::Purchase': IposPurchaseHeaderClass(),
    'Ipos::PurchaseOrder': IposPurchaseOrderClass(),
    'Ipos::PurchaseItem': IposPurchaseItemClass(),
    'Ipos::PurchaseReturn': PurchaseReturnClass(),
    'Ipos::Sale': SaleClass(),
    'Ipos::SaleItem': SaleItemClass(),
    'Ipos::Transfer': TransferClass(),
    'Ipos::TransferItem': TransferItemClass(),
    'Ipos::ConsignmentIn': ConsignmentInClass(),
    'Ipos::ConsignmentInOrder': ConsignmentInOrderClass(),
    'Ipos::StockLocation': StockLocationClass(),
    'Ipos::Location': IposLocationClass(),
    'Ipos::CustomerGroup': CustomerGroupClass(),
    'Ipos::Supplier': IposSupplierClass(),
    'Ipos::Brand': IposBrandClass(),
    'Ipos::ItemType': ItemTypeClass(),
    'PayrollType': PayrollTypeClass(),
    'Payroll': PayrollClass(),
    'Product': ProductClass(),
    'Tagging': TaggingClass(),
    'Supplier': SupplierClass(),
    'ProductCategory': ProductCategoryClass(),
    'Account': AccountClass(),
    'Location': LocationClass(),
    'StockKeepingUnit': StockKeepingUnitClass(),
    'CostDetail': CostDetailClass(),
    'Payslip': PayslipClass(),
    'Employee': EmployeeClass(),
    'EmployeeLeave': EmployeeLeaveClass(),
    'EmployeeAttendance': EmployeeAttendanceClass(),
    'Brand': IposBrandClass(),
    'Tag': TagClass(),
    'TagKey': TagKeyClass(),
    'Role': RoleClass(),
    'Discount': DiscountClass(),
    'Holiday': HolidayClass(),
    'PurchaseOrder': PurchaseOrderClass(),
    'PurchaseOrderDetail': PurchaseOrderDetailClass(),
    'PurchaseInvoice': PurchaseInvoiceClass(),
    'PurchaseInvoiceDetail': PurchaseInvoiceDetailClass(),
    'User': UserClass(),
    'PaymentProvider': PaymentProviderClass(),
    'PaymentType': PaymentTypeClass(),
    'BookEmployeeAttendance': BookEmployeeAttendanceClass(),
    'BookPayslipLine': BookPayslipLineClass(),
    'Document': TagClass(),
    'Company': TagClass(),
    'PurchaseShipment': TagClass(),
    'PurchaseShipmentDetail': TagClass(),
  });
}
