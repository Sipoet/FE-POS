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
  @override
  Widget build(BuildContext context) {
    var sessionState = context.watch<SessionState>();
    double width = MediaQuery.of(context).size.width - 10;
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            sessionState.pageTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          actions: [
            Container(
              constraints: BoxConstraints(maxWidth: width),
              child: MenuBar(
                  children: decorateMenu(menuTree) +
                      [
                        MenuItemButton(
                          leadingIcon: const Icon(Icons.power_settings_new),
                          onPressed: () {
                            _logout();
                          },
                          child: const Text('Log Out'),
                        ),
                      ]),
            ),
          ],
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
    var sessionState = context.watch<SessionState>();
    return [
      for (var destination in destinations)
        if (destination['children'].isEmpty)
          MenuItemButton(
              leadingIcon: Icon(destination['icon']),
              child: Text(destination['label']),
              onPressed: () {
                setState(() {
                  activePage = destination['page'];
                  sessionState.pageTitle = destination['label'];
                });
              })
        else
          SubmenuButton(
            leadingIcon: Icon(destination['icon']),
            menuChildren: decorateMenu(destination['children']),
            child: Text(destination['label']),
          )
    ];
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
