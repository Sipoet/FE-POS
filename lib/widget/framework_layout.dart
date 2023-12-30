import 'package:fe_pos/tool/flash.dart';
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
          Menu(
            icon: Icons.pages,
            isClosed: true,
            label: 'Penjualan persentase per item',
            page: const SalesPercentageReportPage(),
            key: 'salesPercentage',
          ),
          // Menu(
          //     icon: Icons.pageview,
          //     isClosed: true,
          //     label: 'report lain',
          //     key: 'otherReport',
          //     children: [
          //       Menu(
          //         icon: Icons.pageview,
          //         isClosed: true,
          //         label: 'report lain 1',
          //         page: const Placeholder(
          //           child: Text('report lain 1'),
          //         ),
          //         key: 'otherReport1',
          //       ),
          //       Menu(
          //           icon: Icons.pageview,
          //           isClosed: true,
          //           label: 'report lain 2',
          //           page: const Placeholder(
          //             child: Text('report lain 2'),
          //           ),
          //           key: 'otherReport2',
          //           children: [])
          //     ])
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

class DesktopLayout extends StatefulWidget {
  const DesktopLayout(
      {super.key, required this.menuTree, required this.logout});

  final List<Menu> menuTree;
  final Function logout;

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout>
    with TickerProviderStateMixin {
  final List<String> disableClosedTabs = ['Home'];
  @override
  Widget build(BuildContext context) {
    var tabManager = context.read<TabManager>();
    var menus = decorateMenus(widget.menuTree);
    menus.add(
      MenuItemButton(
        leadingIcon: const Icon(Icons.power_settings_new),
        onPressed: () {
          widget.logout();
        },
        child: const Text('Log Out'),
      ),
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TabManager>(create: (_) => tabManager),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Allegra POS',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          actions: menus,
          bottom: TabBar(
            isScrollable: true,
            controller: tabManager.controller,
            onTap: (index) {
              var controller = tabManager.controller;
              if (controller.indexIsChanging &&
                  tabManager.emptyIndex <= index) {
                controller.index = controller.previousIndex;
              } else {
                return;
              }
            },
            tabs: tabManager.tabs
                .map<Widget>((header) => Row(
                      children: [
                        Text(
                          header,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (header.isNotEmpty &&
                            !disableClosedTabs.contains(header))
                          IconButton(
                              onPressed: () => setState(() {
                                    tabManager.removeTab(header);
                                  }),
                              icon: const Icon(Icons.close))
                      ],
                    ))
                .toList(),
          ),
        ),
        body: bodyWidget(),
      ),
    );
  }

  Widget bodyWidget() {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: tabWidget(),
    );
  }

  Widget tabWidget() {
    var tabManager = context.read<TabManager>();
    return TabBarView(
      controller: tabManager.controller,
      children: tabManager.tabViews,
    );
    // return TabBar(tabs: tabs);
  }

  List<Widget> decorateMenus(List<Menu> fromMenus) {
    var tabManager = context.watch<TabManager>();
    return fromMenus.map<Widget>((menu) {
      if (menu.children.isEmpty) {
        return MenuItemButton(
          leadingIcon: Icon(menu.icon),
          onPressed: () {
            setState(() {
              tabManager.addTab(menu.label, menu.page);
            });
          },
          child: Text(menu.label),
        );
      } else {
        return SubmenuButton(
          leadingIcon: Icon(menu.icon),
          menuChildren: decorateMenus(menu.children),
          child: Text(menu.label),
        );
      }
    }).toList();
  }
}

class MobileLayout extends StatefulWidget {
  const MobileLayout({super.key, required this.menuTree, required this.logout});

  final List<Menu> menuTree;
  final Function logout;

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  List<Widget> _menus = [];
  final List<String> disableClosedTabs = ['Home'];

  @override
  void initState() {
    _menus = widget.menuTree.toList().map<Widget>((menu) {
      return decorateMenu(menu);
    }).toList();
    _menus.add(
      ListTile(
        leading: const Icon(Icons.power_settings_new),
        onTap: () {
          widget.logout();
        },
        title: const Text('Log Out'),
      ),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var tabManager = context.read<TabManager>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Allegra POS',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          isScrollable: true,
          controller: tabManager.controller,
          onTap: (index) {
            var controller = tabManager.controller;
            if (controller.indexIsChanging && tabManager.emptyIndex <= index) {
              controller.index = controller.previousIndex;
            } else {
              return;
            }
          },
          tabs: tabManager.tabs
              .map<Widget>((header) => Row(
                    children: [
                      Text(
                        header,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (header.isNotEmpty &&
                          !disableClosedTabs.contains(header))
                        IconButton(
                            onPressed: () => setState(() {
                                  tabManager.removeTab(header);
                                }),
                            icon: const Icon(Icons.close))
                    ],
                  ))
              .toList(),
        ),
      ),
      drawer: Drawer(
          child: ListView.builder(
        itemBuilder: (context, index) => _menus[index],
        itemCount: _menus.length,
      )),
      body: TabBarView(
        controller: tabManager.controller,
        children: tabManager.tabViews,
      ),
    );
  }

  Widget decorateMenu(Menu menu) {
    if (menu.children.isEmpty) {
      return ListTile(
        key: ValueKey(menu.key),
        leading: Icon(menu.icon),
        onTap: () {
          setState(() {
            Navigator.pop(context);
            var tabManager = context.read<TabManager>();
            tabManager.addTab(menu.label, menu.page);
          });
        },
        title: Text(menu.label),
      );
    } else {
      return ListTile(
        key: ValueKey(menu.key),
        leading: Icon(menu.icon),
        title: Text(menu.label),
        onTap: () {
          setState(() {
            menu.isClosed = !menu.isClosed;
            int index = _menus.indexWhere((tile) {
              return tile.key == ValueKey(menu.key);
            });
            if (menu.isClosed) {
              int childrenCount = menu.children.length;
              _menus.removeRange(index + 1, index + childrenCount + 1);
            } else {
              _menus.insertAll(index + 1,
                  menu.children.map<Widget>((childMenu) {
                return decorateMenu(childMenu);
              }));
            }
          });
        },
        trailing:
            Icon(menu.isClosed ? Icons.arrow_drop_down : Icons.arrow_drop_up),
      );
    }
  }
}
