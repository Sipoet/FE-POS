import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/desktop_layout.dart';
import 'package:fe_pos/widget/mobile_layout.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/page/all_page.dart';
import 'package:fe_pos/page/home_page.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/model/menu.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/tool/tab_manager.dart';

class FrameworkLayout extends StatefulWidget {
  const FrameworkLayout({super.key});

  @override
  State<FrameworkLayout> createState() => _FrameworkLayoutState();
}

class _FrameworkLayoutState extends State<FrameworkLayout>
    with TickerProviderStateMixin {
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
          key: 'home'),
      Menu(
          icon: Icons.payment_sharp,
          isClosed: true,
          label: 'HRD',
          key: 'humanResource',
          children: [
            Menu(
                icon: Icons.settings,
                isClosed: true,
                label: 'Aturan Gaji',
                isDisabled: !setting.isAuthorize('payroll', 'index'),
                pageFunct: () => const PayrollPage(),
                key: 'payroll'),
            Menu(
                icon: Icons.monetization_on,
                isClosed: true,
                label: 'Slip Gaji',
                isDisabled: !setting.isAuthorize('payslip', 'index'),
                pageFunct: () => const PayslipPage(),
                key: 'payslip'),
            Menu(
                icon: Icons.calendar_month,
                isClosed: true,
                label: 'Absensi Karyawan',
                isDisabled: !setting.isAuthorize('employeeAttendance', 'index'),
                pageFunct: () => const EmployeeAttendancePage(),
                key: 'employeeAttendance'),
            Menu(
                icon: Icons.calendar_month,
                isClosed: true,
                label: 'Cuti Karyawan',
                isDisabled: !setting.isAuthorize('employeeLeave', 'index'),
                pageFunct: () => const EmployeeLeavePage(),
                key: 'employeeLeave'),
          ]),
      Menu(
          icon: Icons.pages,
          isClosed: true,
          label: 'Laporan',
          key: 'report',
          children: [
            Menu(
                icon: Icons.money,
                isClosed: true,
                label: 'Laporan Penjualan',
                key: 'salesReport',
                children: [
                  Menu(
                    icon: Icons.pages,
                    isClosed: true,
                    label: 'Penjualan persentase per item',
                    isDisabled: !setting.isAuthorize(
                        'itemSalesPercentageReport', 'index'),
                    pageFunct: () => const SalesPercentageReportPage(),
                    key: 'salesPercentageReport',
                  ),
                  Menu(
                    icon: Icons.pages,
                    isClosed: true,
                    label: 'Transaksi Penjualan harian',
                    isDisabled:
                        !setting.isAuthorize('sale', 'transactionReport'),
                    pageFunct: () => const SalesTransactionReportPage(),
                    key: 'salesTransactionReport',
                  ),
                  Menu(
                    icon: Icons.pages,
                    isClosed: true,
                    label: 'Item Penjualan Periode',
                    isDisabled:
                        !setting.isAuthorize('itemSale', 'periodReport'),
                    pageFunct: () => const ItemSalesPeriodReportPage(),
                    key: 'itemSalesPeriodReport',
                  ),
                  Menu(
                    icon: Icons.pages,
                    isClosed: true,
                    label: 'Penjualan Per Supplier',
                    isDisabled: !setting.isAuthorize(
                        'itemSalesPercentageReport', 'groupBySupplier'),
                    pageFunct: () => const SalesGroupBySupplierReportPage(),
                    key: 'salesGroupBySupplierReport',
                  ),
                ]),
            Menu(
              icon: Icons.money,
              isClosed: true,
              label: 'Laporan Slip Gaji',
              key: 'payslipReport',
              pageFunct: () => const PayslipReportPage(),
            ),
          ]),
      Menu(
          icon: Icons.table_chart,
          isClosed: true,
          label: 'Master Data',
          key: 'master',
          pageFunct: () => const Placeholder(),
          children: [
            Menu(
                icon: Icons.inventory,
                isClosed: true,
                label: 'Item',
                isDisabled: !setting.isAuthorize('item', 'index'),
                key: 'item',
                pageFunct: () => const ItemPage(),
                children: []),
            Menu(
                icon: Icons.local_shipping,
                isClosed: true,
                label: 'Supplier',
                isDisabled: !setting.isAuthorize('supplier', 'index'),
                key: 'supplier',
                pageFunct: () => const SupplierPage(),
                children: []),
            Menu(
                icon: Icons.branding_watermark,
                isClosed: true,
                label: 'Merek',
                isDisabled: !setting.isAuthorize('brand', 'index'),
                key: 'brand',
                pageFunct: () => const BrandPage(),
                children: []),
            Menu(
                icon: Icons.abc,
                isClosed: true,
                label: 'Jenis/Departemen',
                isDisabled: !setting.isAuthorize('itemType', 'index'),
                key: 'itemType',
                pageFunct: () => const ItemTypePage(),
                children: []),
            Menu(
                icon: Icons.discount,
                isClosed: true,
                label: 'Diskon',
                isDisabled: !setting.isAuthorize('discount', 'index'),
                key: 'discount',
                pageFunct: () => const DiscountPage(),
                children: []),
            Menu(
                icon: Icons.person,
                isClosed: true,
                label: 'Karyawan',
                isDisabled: !setting.isAuthorize('employee', 'index'),
                key: 'employee',
                pageFunct: () => const EmployeePage(),
                children: []),
            Menu(
                icon: Icons.person,
                isClosed: true,
                label: 'User',
                isDisabled: !setting.isAuthorize('user', 'index'),
                key: 'user',
                pageFunct: () => const UserPage(),
                children: []),
            Menu(
                icon: Icons.person,
                isClosed: true,
                label: 'Role',
                isDisabled: !setting.isAuthorize('role', 'index'),
                key: 'role',
                pageFunct: () => const RolePage(),
                children: []),
          ]),
    ];
    flash = Flash(context);
    tabManager = TabManager(this);
    tabManager.addTab('Home', const HomePage());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<TabManager>(create: (_) => tabManager),
        ],
        child: LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth < 800.0 || constraints.maxHeight < 600.0) {
            return MobileLayout(menuTree: menuTree, logout: _logout);
          } else {
            return DesktopLayout(menuTree: menuTree, logout: _logout);
          }
        }));
  }

  void _logout() {
    SessionState sessionState = context.read<SessionState>();
    Server server = context.read<Server>();
    try {
      sessionState.logout(
          server: server,
          context: context,
          onSuccess: (response) {
            var body = response.data;
            flash.showBanner(
              title: body['message'],
              messageType: MessageType.success,
            );
            // Navigator.pop(context);
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => const LoginPage()));
          },
          onFailed: (response) {
            var body = response.data;
            flash.show(
                Text(
                  body['error'],
                ),
                MessageType.failed);
          });
    } catch (error) {
      flash.show(
          Text(
            error.toString(),
          ),
          MessageType.failed);
    }
  }
}
