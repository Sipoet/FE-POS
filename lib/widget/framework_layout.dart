import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/desktop_layout.dart';
import 'package:fe_pos/widget/mobile_layout.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/page/menu_page.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/model/menu.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:tabbed_view/tabbed_view.dart';

class FrameworkLayout extends StatefulWidget {
  const FrameworkLayout({super.key});

  @override
  State<FrameworkLayout> createState() => _FrameworkLayoutState();
}

class _FrameworkLayoutState extends State<FrameworkLayout>
    with
        TickerProviderStateMixin,
        SessionState,
        DefaultResponse,
        PlatformChecker {
  List<Menu> menuTree = [];

  late TabManager tabManager;
  late Flash flash;

  @override
  void initState() {
    final setting = context.read<Setting>();
    menuTree = <Menu>[
      Menu(
        icon: Icons.home,
        isClosed: true,
        label: 'Home',
        pageFunct: () => const HomePage(),
        key: 'home',
      ),
      // Menu(
      //     icon: Icons.home,
      //     isClosed: true,
      //     label: 'TEST',
      //     pageFunct: () => const TestingPage(),
      //     key: 'test'),
      Menu(
        icon: Icons.payment_sharp,
        isClosed: true,
        label: 'HRD',
        key: 'humanResource',
        children: [
          Menu(
            icon: Icons.person,
            isClosed: true,
            label: 'Karyawan',
            isDisabled: !setting.isAuthorize('employees', 'read'),
            key: 'employee',
            pageFunct: () => const EmployeePage(),
            children: [],
          ),
          Menu(
            icon: Icons.settings,
            isClosed: true,
            label: 'Tipe Aturan Gaji',
            isDisabled: !setting.isAuthorize('payroll_types', 'read'),
            pageFunct: () => const PayrollTypePage(),
            key: 'payrollType',
          ),
          Menu(
            icon: Icons.settings,
            isClosed: true,
            label: 'Aturan Gaji',
            isDisabled: !setting.isAuthorize('payrolls', 'read'),
            pageFunct: () => const PayrollPage(),
            key: 'payroll',
          ),
          Menu(
            icon: Icons.monetization_on,
            isClosed: true,
            label: 'Slip Gaji',
            isDisabled: !setting.isAuthorize('payslips', 'read'),
            pageFunct: () => const PayslipPage(),
            key: 'payslip',
          ),
          Menu(
            icon: Icons.calendar_month,
            isClosed: true,
            label: 'Absensi Karyawan',
            isDisabled: !setting.isAuthorize('employee_attendances', 'read'),
            pageFunct: () => const EmployeeAttendancePage(),
            key: 'employeeAttendance',
          ),
          Menu(
            icon: Icons.calendar_month,
            isClosed: true,
            label: 'Cuti Karyawan',
            isDisabled: !setting.isAuthorize('employee_leaves', 'read'),
            pageFunct: () => const EmployeeLeavePage(),
            key: 'employeeLeave',
          ),
          Menu(
            icon: Icons.calendar_month,
            isClosed: true,
            label: 'Libur Karyawan',
            isDisabled: !setting.isAuthorize('holidays', 'read'),
            pageFunct: () => const HolidayPage(),
            key: 'holiday',
          ),
          Menu(
            icon: Icons.calendar_month,
            isClosed: true,
            label: 'BOOK PAYSLIP LINE',
            isDisabled: !setting.isAuthorize('book_payslip_Lines', 'read'),
            pageFunct: () => const BookPayslipLinePage(),
            key: 'bookPayslipLine',
          ),
          Menu(
            icon: Icons.calendar_month,
            isClosed: true,
            label: 'BOOK / SETTING EMPLOYEE ATTENDANCE',
            isDisabled: !setting.isAuthorize(
              'book_employee_attendances',
              'read',
            ),
            pageFunct: () => const BookEmployeeAttendancePage(),
            key: 'bookEmployeeAttendance',
          ),
        ],
      ),
      Menu(
        icon: Icons.pages,
        isClosed: true,
        label: 'Laporan',
        key: 'report',
        children: [
          Menu(
            icon: Icons.card_giftcard,
            isClosed: true,
            label: 'Laporan item',
            isDisabled: !setting.isAuthorize('item_reports', 'read'),
            pageFunct: () => const ItemReportPage(),
            key: 'salesPercentageReport',
          ),
          Menu(
            icon: Icons.shopping_bag,
            isClosed: true,
            label: 'Laporan Pembelian',
            key: 'purchaseReportGroup',
            children: [
              Menu(
                icon: Icons.pages,
                isClosed: true,
                label: 'Pembelian',
                tabTitle: 'Laporan Pembelian',
                isDisabled: !setting.isAuthorize('ipos/purchases', 'report'),
                pageFunct: () => const PurchaseReportPage(),
                key: 'purchaseReport',
              ),
              Menu(
                icon: Icons.history,
                isClosed: true,
                label: 'Riwayat Pembayaran Pembelian',
                isDisabled: !setting.isAuthorize(
                  'purchasePaymentHistory',
                  'read',
                ),
                pageFunct: () => const PurchasePaymentHistoryPage(),
                key: 'purchasePaymentHistory',
              ),
            ],
          ),
          Menu(
            icon: Icons.money,
            isClosed: true,
            label: 'Laporan Penjualan',
            key: 'salesReport',
            children: [
              Menu(
                icon: Icons.pages,
                isClosed: true,
                label: 'Transaksi Penjualan harian',
                isDisabled: !setting.isAuthorize(
                  'ipos/sales',
                  'transactionReport',
                ),
                pageFunct: () => const SalesTransactionReportPage(),
                key: 'salesTransactionReport',
              ),
              Menu(
                icon: Icons.line_axis,
                isClosed: true,
                label: 'Performa Jenis/Departemen',
                isDisabled: !setting.isAuthorize(
                  'item_sales_performance_reports',
                  'groupBy',
                ),
                pageFunct: () => const ItemTypeSalesPerformanceReportPage(),
                key: 'itemTypeSalesPerformanceReport',
              ),
              Menu(
                icon: Icons.line_axis,
                isClosed: true,
                label: 'Performa Penjualan Supplier',
                isDisabled: !setting.isAuthorize(
                  'item_sales_performance_reports',
                  'groupBy',
                ),
                pageFunct: () => const SupplierSalesPerformanceReportPage(),
                key: 'supplierSalesPerformanceReport',
              ),
              Menu(
                icon: Icons.line_axis,
                isClosed: true,
                label: 'Performa Penjualan Merek',
                isDisabled: !setting.isAuthorize(
                  'item_sales_performance_reports',
                  'groupBy',
                ),
                pageFunct: () => const BrandSalesPerformanceReportPage(),
                key: 'brandSalesPerformanceReport',
              ),
              Menu(
                icon: Icons.bar_chart,
                isClosed: true,
                label: 'Penjualan Periode',
                isDisabled: !setting.isAuthorize(
                  'item_sales_performance_reports',
                  'groupBy',
                ),
                pageFunct: () => const SalesTransactionGraphPage(),
                key: 'salesTransactionGraph',
              ),
              Menu(
                icon: Icons.table_chart,
                isClosed: true,
                label: 'Item Penjualan Periode',
                isDisabled: !setting.isAuthorize('sale_items', 'periodReport'),
                pageFunct: () => const ItemSalesPeriodReportPage(),
                key: 'itemSalesPeriodReport',
              ),
              Menu(
                icon: Icons.table_chart,
                isClosed: true,
                label: 'Laporan Grup Penjualan',
                isDisabled: !setting.isAuthorize(
                  'item_reports',
                  'groupedReport',
                ),
                pageFunct: () => const SalesGroupBySupplierReportPage(),
                key: 'salesGroupBySupplierReport',
              ),
            ],
          ),
          Menu(
            icon: Icons.balance,
            isClosed: true,
            label: 'Laporan Kas',
            key: 'cashReport',
            children: [
              Menu(
                icon: Icons.show_chart,
                isClosed: true,
                label: 'Pengeluaran Periode',
                key: 'monthlyExpenseReport',
                isDisabled: !setting.isAuthorize(
                  'monthly_expense_reports',
                  'read',
                ),
                pageFunct: () => const MonthlyExpenseReportPage(),
              ),
              Menu(
                icon: Icons.table_chart,
                isClosed: true,
                label: 'Kas masuk/keluar',
                key: 'cashTransactionReport',
                isDisabled: !setting.isAuthorize(
                  'cash_transaction_reports',
                  'read',
                ),
                pageFunct: () => const CashTransactionReportPage(),
              ),
            ],
          ),
          Menu(
            key: 'humanResourceGroup',
            icon: Icons.people,
            label: 'Laporan SDM',
            children: [
              Menu(
                icon: Icons.people,
                isClosed: true,
                label: 'Laporan Slip Gaji',
                key: 'payslipReport',
                isDisabled: !setting.isAuthorize('payslips', 'report'),
                pageFunct: () => const PayslipReportPage(),
              ),
              Menu(
                icon: Icons.people,
                isClosed: true,
                label: 'Laporan Payroll',
                key: 'payslipReport',
                isDisabled: !setting.isAuthorize('payrolls', 'report'),
                pageFunct: () => const PayrollReportPage(),
              ),
            ],
          ),
        ],
      ),
      Menu(
        icon: Icons.money,
        label: 'Keuangan',
        key: 'finance',
        children: [
          Menu(
            icon: Icons.shopping_bag,
            label: 'Tipe Pembayaran',
            key: 'payment_type',
            isDisabled: !setting.isAuthorize('payment_types', 'read'),
            pageFunct: () => const PaymentTypePage(),
          ),
          Menu(
            icon: Icons.shopping_bag,
            label: 'Payment Provider',
            key: 'payment_provider',
            isDisabled: !setting.isAuthorize('payment_providers', 'read'),
            pageFunct: () => const PaymentProviderPage(),
          ),
          Menu(
            icon: Icons.shopping_bag,
            label: 'Sesi Kasir',
            key: 'cashier_session',
            isDisabled: !setting.isAuthorize('cashier_sessions', 'read'),
            pageFunct: () => const CashierSessionPage(),
          ),
        ],
      ),
      Menu(
        icon: Icons.shopping_bag,
        label: 'Pembelian',
        key: 'purchase',
        children: [
          Menu(
            icon: Icons.shopping_bag,
            label: 'Pesanan Pembelian',
            isDisabled: !setting.isAuthorize('ipos/purchase_orders', 'read'),
            key: 'purchase_order',
            pageFunct: () => const PurchaseOrderPage(),
          ),
          Menu(
            icon: Icons.shopping_bag,
            label: 'Pembelian',
            isDisabled: !setting.isAuthorize('ipos/purchases', 'read'),
            key: 'purchase',
            pageFunct: () => const PurchasePage(),
          ),
          Menu(
            icon: Icons.shopping_bag,
            label: 'Detail Pembelian Item',
            key: 'purchase',
            isDisabled: !setting.isAuthorize('ipos/purchase_items', 'read'),
            pageFunct: () => const PurchaseItemPage(),
          ),
          Menu(
            icon: Icons.shopping_bag,
            label: 'Retur Pembelian',
            isDisabled: !setting.isAuthorize('ipos/purchase_returns', 'read'),
            key: 'purchase_return',
            pageFunct: () => const PurchaseReturnPage(),
          ),
          Menu(
            icon: Icons.shopping_bag,
            label: 'Pesanan Konsinyasi Masuk',
            isDisabled: !setting.isAuthorize(
              'ipos/consignment_in_orders',
              'read',
            ),
            key: 'consignment_in_order',
            pageFunct: () => const ConsignmentInOrderPage(),
          ),
          Menu(
            icon: Icons.shopping_bag,
            label: 'Konsinyasi Masuk',
            isDisabled: !setting.isAuthorize('ipos/consignment_ins', 'read'),
            key: 'consignment_in',
            pageFunct: () => const ConsignmentInPage(),
          ),
        ],
      ),
      Menu(
        icon: Icons.shopping_cart,
        label: 'Penjualan',
        key: 'sales',
        children: [
          // Menu(
          //     icon: Icons.card_membership_rounded,
          //     label: 'Metode Pembayaran',
          //     pageFunct: () => const PaymentMethodPage(),
          //     key: 'payment_method'),
          Menu(
            icon: Icons.shopping_cart,
            label: 'Penjualan',
            key: 'sale',
            isDisabled: !setting.isAuthorize('ipos/sales', 'read'),
            pageFunct: () => const SalePage(),
          ),
          Menu(
            icon: Icons.shopping_bag,
            label: 'Detail Penjualan Item',
            key: 'sale_item',
            isDisabled: !setting.isAuthorize('ipos/sale_items', 'read'),
            pageFunct: () => const SaleItemPage(),
          ),
          Menu(
            icon: Icons.monetization_on,
            label: 'Cek Harga',
            key: 'check_price',
            isDisabled: !setting.isAuthorize('ipos/items', 'withDiscount'),
            pageFunct: () => const CheckPricePage(),
          ),
        ],
      ),
      Menu(
        icon: Icons.inventory,
        label: 'Persediaan',
        children: [
          Menu(
            icon: Icons.shopping_bag,
            label: 'Transfer Item',
            key: 'transfer',
            isDisabled: !setting.isAuthorize('ipos/transfers', 'read'),
            pageFunct: () => const TransferPage(),
          ),
          Menu(
            icon: Icons.shopping_bag,
            label: 'Detail Transfer Item',
            key: 'transferItem',
            isDisabled: !setting.isAuthorize('ipos/transfers', 'read'),
            pageFunct: () => const TransferItemPage(),
          ),
        ],
        key: 'inventory',
      ),
      Menu(
        icon: Icons.table_chart,
        isClosed: true,
        label: 'Master Data',
        key: 'master',
        children: [
          Menu(
            icon: Icons.inventory,
            isClosed: true,
            label: 'Item',
            isDisabled: !setting.isAuthorize('ipos/items', 'read'),
            key: 'item',
            pageFunct: () => const ItemPage(),
            children: [],
          ),
          Menu(
            icon: Icons.local_shipping,
            isClosed: true,
            label: 'Supplier',
            isDisabled: !setting.isAuthorize('ipos/suppliers', 'read'),
            key: 'supplier',
            pageFunct: () => const SupplierPage(),
            children: [],
          ),
          Menu(
            icon: Icons.branding_watermark,
            isClosed: true,
            label: 'Merek',
            isDisabled: !setting.isAuthorize('ipos/brands', 'read'),
            key: 'brand',
            pageFunct: () => const BrandPage(),
            children: [],
          ),
          Menu(
            icon: Icons.abc,
            isClosed: true,
            label: 'Jenis/Departemen',
            isDisabled: !setting.isAuthorize('ipos/item_types', 'read'),
            key: 'itemType',
            pageFunct: () => const ItemTypePage(),
            children: [],
          ),
          Menu(
            icon: Icons.discount,
            isClosed: true,
            label: 'Diskon',
            isDisabled: !setting.isAuthorize('discounts', 'read'),
            key: 'discount',
            pageFunct: () => const DiscountPage(),
            children: [],
          ),
          Menu(
            icon: Icons.group,
            isClosed: true,
            label: 'Customer Group Discount',
            isDisabled: !setting.isAuthorize(
              'customer_group_discounts',
              'read',
            ),
            key: 'customerGroupDiscount',
            pageFunct: () => const CustomerGroupDiscountPage(),
          ),
          Menu(
            icon: Icons.person,
            isClosed: true,
            label: 'User',
            isDisabled: !setting.isAuthorize('users', 'read'),
            key: 'user',
            pageFunct: () => const UserPage(),
            children: [],
          ),
          Menu(
            icon: Icons.group,
            isClosed: true,
            label: 'Role',
            isDisabled: !setting.isAuthorize('roles', 'read'),
            key: 'role',
            pageFunct: () => const RolePage(),
            children: [],
          ),
        ],
      ),
      Menu(
        icon: Icons.settings,
        isClosed: true,
        label: 'Setting',
        key: 'group_setting',
        children: [
          Menu(
            icon: Icons.settings,
            isClosed: true,
            label: 'System Setting',
            key: 'setting',
            isDisabled: !setting.isAuthorize('system_settings', 'read'),
            pageFunct: () => const SystemSettingPage(),
          ),
          Menu(
            icon: Icons.settings,
            isClosed: true,
            label: 'Refresh Table Data',
            key: 'setting',
            isDisabled: !setting.isAuthorize('system_settings', 'refreshTable'),
            pageFunct: () => const RefreshTablePage(),
          ),
          Menu(
            icon: Icons.padding,
            isClosed: true,
            label: 'Background Job Management',
            key: 'background_log',
            isDisabled: !setting.isAuthorize('background_jobs', 'read'),
            pageFunct: () => const BackgroundJobPage(),
          ),
        ],
      ),
    ];
    flash = Flash();
    tabManager = TabManager(
      tabItemDetails: [
        TabData(text: 'Home', content: const HomePage(), closable: false),
      ],
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final server = context.read<Server>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TabManager>(create: (_) => tabManager),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 800.0 || constraints.maxHeight < 600.0) {
            return MobileLayout(
              menuTree: menuTree,
              userName: server.userName,
              host: server.host,
            );
          } else {
            return DesktopLayout(
              menuTree: menuTree,
              userName: server.userName,
              host: server.host,
            );
          }
        },
      ),
    );
  }
}
