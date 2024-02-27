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
          page: const HomePage(),
          key: 'home'),
      Menu(
          icon: Icons.payment_sharp,
          isClosed: true,
          label: 'Human Resource',
          key: 'humanResource',
          children: [
            Menu(
                icon: Icons.settings,
                isClosed: true,
                label: 'Aturan Gaji',
                isDisabled: !setting.isAuthorize('payroll', 'index'),
                page: const PayrollPage(),
                key: 'payroll'),
            Menu(
                icon: Icons.monetization_on,
                isClosed: true,
                label: 'Slip Gaji',
                isDisabled: !setting.isAuthorize('payslip', 'index'),
                page: const PayslipPage(),
                key: 'payslip'),
            Menu(
                icon: Icons.calendar_month,
                isClosed: true,
                label: 'Absensi Karyawan',
                isDisabled: !setting.isAuthorize('employeeAttendance', 'index'),
                page: const EmployeeAttendancePage(),
                key: 'employeeAttendance'),
            Menu(
                icon: Icons.calendar_month,
                isClosed: true,
                label: 'Cuti Karyawan',
                isDisabled: !setting.isAuthorize('employeeLeave', 'index'),
                page: const EmployeeLeavePage(),
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
                    page: const SalesPercentageReportPage(),
                    key: 'salesPercentageReport',
                  ),
                  Menu(
                    icon: Icons.pages,
                    isClosed: true,
                    label: 'Transaksi Penjualan harian',
                    isDisabled:
                        !setting.isAuthorize('sale', 'transactionReport'),
                    page: const SalesTransactionReportPage(),
                    key: 'salesTransactionReport',
                  ),
                  Menu(
                    icon: Icons.pages,
                    isClosed: true,
                    label: 'Item Penjualan Periode',
                    isDisabled:
                        !setting.isAuthorize('itemSale', 'periodReport'),
                    page: const ItemSalesPeriodReportPage(),
                    key: 'itemSalesPeriodReport',
                  ),
                  Menu(
                    icon: Icons.pages,
                    isClosed: true,
                    label: 'Penjualan Per Supplier',
                    isDisabled: !setting.isAuthorize(
                        'itemSalesPercentageReport', 'groupBySupplier'),
                    page: const SalesGroupBySupplierReportPage(),
                    key: 'salesGroupBySupplierReport',
                  ),
                ])
          ]),
      Menu(
          icon: Icons.table_chart,
          isClosed: true,
          label: 'Master Data',
          key: 'master',
          page: const Placeholder(),
          children: [
            Menu(
                icon: Icons.discount,
                isClosed: true,
                label: 'Diskon',
                isDisabled: !setting.isAuthorize('discount', 'index'),
                key: 'discount',
                page: const DiscountPage(),
                children: []),
            Menu(
                icon: Icons.person,
                isClosed: true,
                label: 'Karyawan',
                isDisabled: !setting.isAuthorize('employee', 'index'),
                key: 'employee',
                page: const EmployeePage(),
                children: []),
            Menu(
                icon: Icons.person,
                isClosed: true,
                label: 'User',
                isDisabled: !setting.isAuthorize('user', 'index'),
                key: 'user',
                page: const UserPage(),
                children: []),
            Menu(
                icon: Icons.person,
                isClosed: true,
                label: 'Role',
                isDisabled: !setting.isAuthorize('role', 'index'),
                key: 'role',
                page: const RolePage(),
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
    try {
      sessionState.logout(
          context: context,
          onSuccess: (response) {
            var body = response.data;
            flash.showBanner(
              title: body['message'],
              messageType: MessageType.success,
            );

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
