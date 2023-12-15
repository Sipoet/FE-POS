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
      'label': 'Home',
      'page': const HomePage(),
      'children': [],
      'key': 'home'
    },
    {
      'icon': Icons.money,
      'label': 'Sales',
      'page': const Placeholder(),
      'children': [],
      'key': 'sales'
    },
    {
      'icon': Icons.pages,
      'label': 'Report',
      'key': 'report',
      'children': [
        {
          'icon': Icons.pages,
          'label': 'Penjualan persentase per item',
          'page': const SalesPercentageReportPage(),
          'key': 'salesPercentage',
          'children': []
        },
        {
          'icon': Icons.pageview,
          'label': 'report lain',
          'page': const Placeholder(),
          'key': 'otherReport',
          'children': [
            {
              'icon': Icons.pageview,
              'label': 'report lain 1',
              'page': const Placeholder(),
              'key': 'otherReport1',
              'children': []
            },
            {
              'icon': Icons.pageview,
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
      'label': 'Master Data',
      'key': 'master',
      'controller': MaterialStatesController(),
      'children': [
        {
          'icon': Icons.discount,
          'label': 'Discount',
          'key': 'discount',
          'page': const DiscountPage(),
          'children': []
        }
      ]
    },
  ];
  Widget activePage = const HomePage();
  String pageTitle = 'Home';
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width - 10;
    return LayoutBuilder(builder: (context, constraints) {
      var menus = decorateMenu(menuTree);
      menus.add(
        MenuItemButton(
          leadingIcon: const Icon(Icons.power_settings_new),
          onPressed: () {
            _logout();
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
            child: activePage,
          ),
        ),
      );
    });
  }

  List<Widget> decorateMenu(List destinations) {
    return destinations.map<Widget>((destination) {
      if (destination['children'] == null || destination['children'].isEmpty) {
        return MenuItemButton(
          leadingIcon: Icon(destination['icon']),
          onPressed: () {
            setState(() {
              activePage = destination['page'];
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
