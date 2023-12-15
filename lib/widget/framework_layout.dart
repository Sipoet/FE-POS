import 'package:flutter/material.dart';
import 'package:fe_pos/page/login_page.dart';
import 'package:fe_pos/page/discount_page.dart';
import 'package:fe_pos/page/report_page.dart';
import 'package:fe_pos/page/home_page.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class FrameworkLayout extends StatefulWidget {
  const FrameworkLayout({super.key});

  @override
  State<FrameworkLayout> createState() => _FrameworkLayoutState();
}

class _FrameworkLayoutState extends State<FrameworkLayout> {
  List menuTree = [
    {
      'icon': Icons.home,
      'isClosed': true,
      'label': 'Home',
      'page': const HomePage(),
      'children': [],
      'key': 'home'
    },
    {
      'icon': Icons.money,
      'isClosed': true,
      'label': 'Sales',
      'page': const Placeholder(),
      'children': [],
      'key': 'sales'
    },
    {
      'icon': Icons.pages,
      'isClosed': true,
      'label': 'Report',
      'key': 'report',
      'children': [
        {
          'icon': Icons.pages,
          'isClosed': true,
          'label': 'Penjualan persentase per item',
          'page': const SalesPercentageReportPage(),
          'key': 'salesPercentage',
          'children': []
        },
        {
          'icon': Icons.pageview,
          'isClosed': true,
          'label': 'report lain',
          'page': const Placeholder(),
          'key': 'otherReport',
          'children': [
            {
              'icon': Icons.pageview,
              'isClosed': true,
              'label': 'report lain 1',
              'page': const Placeholder(),
              'key': 'otherReport1',
              'children': []
            },
            {
              'icon': Icons.pageview,
              'isClosed': true,
              'label': 'report lain 2',
              'page': const Placeholder(),
              'key': 'otherReport2',
              'children': []
            }
          ]
        }
      ]
    },
    {
      'icon': Icons.table_chart,
      'isClosed': true,
      'label': 'Master Data',
      'key': 'master',
      'controller': MaterialStatesController(),
      'children': [
        {
          'icon': Icons.discount,
          'isClosed': true,
          'label': 'Discount',
          'key': 'discount',
          'page': const DiscountPage(),
          'children': []
        }
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 680.0) {
        return MobileLayout(menuTree: menuTree, logout: _logout);
      } else {
        return DesktopLayout(menuTree: menuTree, logout: _logout);
      }
    });
  }

  void _logout() {
    SessionState sessionState = context.read<SessionState>();
    try {
      sessionState.logout(onSuccess: (response) {
        var body = jsonDecode(response.body);
        displayFlash(Text(
          body['message'],
          style: const TextStyle(color: Colors.green),
        ));

        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (BuildContext context) => const LoginPage()));
      }, onFailed: (response) {
        var body = jsonDecode(response.body);
        displayFlash(Text(
          body['error'],
          style: const TextStyle(color: Colors.red),
        ));
      });
    } catch (error) {
      displayFlash(Text(
        error.toString(),
        style: const TextStyle(color: Colors.red),
      ));
    }
  }

  void displayFlash(Widget content) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(child: content),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.up,
        margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 60,
            left: 50,
            right: 50),
      ),
    );
  }
}

class DesktopLayout extends StatefulWidget {
  const DesktopLayout(
      {super.key, required this.menuTree, required this.logout});

  final List menuTree;
  final Function logout;

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> {
  Widget _activePage = const HomePage();

  String pageTitle = 'Home';

  @override
  Widget build(BuildContext context) {
    var menus = decorateMenu(widget.menuTree);
    menus.add(
      MenuItemButton(
        leadingIcon: const Icon(Icons.power_settings_new),
        onPressed: () {
          widget.logout();
        },
        child: const Text('Log Out'),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          pageTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: menus,
      ),
      body: Expanded(
        child: Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: _activePage,
        ),
      ),
    );
  }

  List<Widget> decorateMenu(List destinations) {
    return destinations.map<Widget>((destination) {
      if (destination['children'] == null || destination['children'].isEmpty) {
        return MenuItemButton(
          leadingIcon: Icon(destination['icon']),
          onPressed: () {
            setState(() {
              _activePage = destination['page'];
              pageTitle = destination['label'];
            });
          },
          child: Text(destination['label']),
        );
      } else {
        return SubmenuButton(
          leadingIcon: Icon(destination['icon']),
          menuChildren: decorateMenu(destination['children']),
          child: Text(destination['label']),
        );
      }
    }).toList();
  }
}

class MobileLayout extends StatefulWidget {
  const MobileLayout({super.key, required this.menuTree, required this.logout});

  final List menuTree;
  final Function logout;

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  List<Widget> _menus = [];
  Widget _activePage = const HomePage();
  String pageTitle = 'Home';

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
    print("build ${_menus.length.toString()}");
    return Scaffold(
      appBar: AppBar(
        title: Text(
          pageTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      drawer: Drawer(
          child: ListView.builder(
        itemBuilder: (context, index) => _menus[index],
        itemCount: _menus.length,
      )),
      body: Expanded(
        child: Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: _activePage,
        ),
      ),
    );
  }

  Widget decorateMenu(destination) {
    if (destination['children'] == null || destination['children'].isEmpty) {
      return ListTile(
        key: ValueKey(destination['key']),
        leading: Icon(destination['icon']),
        onTap: () {
          setState(() {
            _activePage = destination['page'];
            pageTitle = destination['label'];
          });
        },
        title: Text(destination['label']),
      );
    } else {
      return ListTile(
        key: ValueKey(destination['key']),
        leading: Icon(destination['icon']),
        title: Text(destination['label']),
        onTap: () {
          setState(() {
            destination['isClosed'] = destination['isClosed'] ?? true;
            destination['isClosed'] = !destination['isClosed'];
            int index = _menus.indexWhere((tile) {
              return tile.key == ValueKey(destination['key']);
            });
            if (destination['isClosed']) {
              int childrenCount = destination['children'].length;
              _menus.removeRange(index + 1, index + childrenCount + 1);
            } else {
              print("before add ${_menus.length.toString()}");

              _menus.insertAll(
                  index + 1,
                  destination['children'].map<Widget>((childMenu) {
                    return decorateMenu(childMenu);
                  }));
              print("add ${_menus.length.toString()}");
            }
          });
        },
        trailing: Icon(destination['isClosed']
            ? Icons.arrow_drop_down
            : Icons.arrow_drop_up),
      );
    }
  }
}
