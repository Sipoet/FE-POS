import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/widget/desktop_layout.dart';
import 'package:fe_pos/widget/mobile_layout.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/page/login_page.dart';
import 'package:fe_pos/page/discount_page.dart';
import 'package:fe_pos/page/report_page.dart';
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
  List<Menu> menuTree = <Menu>[
    Menu(
        icon: Icons.home,
        isClosed: true,
        label: 'Home',
        page: const HomePage(),
        key: 'home'),
    // Menu(
    //     icon: Icons.money,
    //     isClosed: true,
    //     label: 'Penjualan',
    //     page: const Placeholder(
    //       child: Text('sales'),
    //     ),
    //     key: 'sales'),
    Menu(
        icon: Icons.pages,
        isClosed: true,
        label: 'Laporan',
        key: 'report',
        children: [
          // Menu(
          //   icon: Icons.pages,
          //   isClosed: true,
          //   label: 'Penjualan persentase per item',
          //   page: const SalesPercentageReportPage(),
          //   key: 'salesPercentage',
          // ),
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
                  page: const SalesPercentageReportPage(),
                  key: 'salesPercentageReport',
                ),
                Menu(
                  icon: Icons.pages,
                  isClosed: true,
                  label: 'Transaksi Penjualan harian',
                  page: const SalesTransactionReportPage(),
                  key: 'salesTransactionReport',
                ),
                Menu(
                  icon: Icons.pages,
                  isClosed: true,
                  label: 'Item Penjualan Periode',
                  page: const ItemSalesPeriodReportPage(),
                  key: 'itemSalesPeriodReport',
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
              key: 'discount',
              page: const DiscountPage(),
              children: [])
        ]),
  ];
  late TabManager tabManager;
  late Flash flash;
  @override
  void initState() {
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
