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
  int selectedIndex = 0;
  int level = 1;
  Map menuTree = {
    'home': {
      'icon': Icons.home,
      'label': 'Home',
      'page': const HomePage(),
      'children': {},
      'key': 'home'
    },
    'sales': {
      'icon': Icons.money,
      'label': 'Sales',
      'page': const Placeholder(),
      'children': {},
      'key': 'sales'
    },
    'report': {
      'icon': Icons.pages,
      'label': 'Report',
      'page': const Placeholder(),
      'parentTraces': [],
      'key': 'report',
      'children': {
        'salesPercentage': {
          'icon': Icons.pages,
          'label': 'Penjualan persentase per item',
          'page': const SalesPercentageReportPage(),
          'key': 'salesPercentage',
          'children': {}
        },
        'otherReport': {
          'icon': Icons.pageview,
          'label': 'report lain',
          'page': const Placeholder(),
          'key': 'otherReport',
          'children': {
            'otherReport1': {
              'icon': Icons.pageview,
              'label': 'report lain 1',
              'page': const Placeholder(),
              'key': 'otherReport1',
              'children': {}
            },
            'otherReport2': {
              'icon': Icons.pageview,
              'label': 'report lain 2',
              'page': const Placeholder(),
              'key': 'otherReport2',
              'children': {}
            }
          }
        }
      }
    },
    'master': {
      'icon': Icons.table_chart,
      'label': 'Master Data',
      'key': 'purchase',
      'children': {
        'discount': {
          'icon': Icons.discount,
          'label': 'Discount',
          'key': 'children',
          'page': const DiscountPage(),
        }
      }
    },
  };

  var destinations = {};
  List parentTraces = [];
  @override
  Widget build(BuildContext context) {
    destinations = menuTree;
    for (var trace in parentTraces) {
      destinations = destinations[trace]['children'];
    }
    List<Widget> leadingWidgets = <Widget>[];
    if (parentTraces.isNotEmpty) {
      leadingWidgets.add(const SizedBox(width: 10));
      leadingWidgets.add(ElevatedButton.icon(
          label: const Text('Back'),
          onPressed: () {
            setState(() {
              selectedIndex = 0;
              parentTraces.removeLast();
            });
          },
          icon: const Icon(Icons.arrow_back)));
    }
    var arrDestination = [];
    destinations
        .forEach((label, destination) => arrDestination.add(destination));
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                leading: Row(
                  children: leadingWidgets,
                ),
                trailing: ElevatedButton.icon(
                  label: const Text('Log Out'),
                  icon: const Icon(Icons.power_settings_new),
                  onPressed: () {
                    _logout();
                  },
                ),
                destinations: [
                  for (var destination in arrDestination)
                    NavigationRailDestination(
                      icon: Icon(destination['icon']),
                      label: Text(destination['label']),
                    )
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    var destination = arrDestination[value];
                    if (destination['children'].isEmpty) {
                      selectedIndex = value;
                    } else {
                      parentTraces.add(destination['key']);
                      selectedIndex = 0;
                      destinations = destination['children'];
                    }
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: arrDestination[selectedIndex]['page'],
              ),
            ),
          ],
        ),
      );
    });
  }

  void _logout() {
    SessionState sessionState = context.read<SessionState>();
    var messenger = ScaffoldMessenger.of(context);
    try {
      sessionState.logout(onSuccess: (response) {
        var body = jsonDecode(response.body);
        messenger.showSnackBar(
          SnackBar(
              content: Text(
            body['message'],
            style: const TextStyle(color: Colors.green),
          )),
        );
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (BuildContext context) => const LoginPage()));
      }, onFailed: (response) {
        var body = jsonDecode(response.body);
        messenger.showSnackBar(
          SnackBar(
              content: Text(
            body['error'],
            style: const TextStyle(color: Colors.red),
          )),
        );
      });
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
            content: Text(
          error.toString(),
          style: const TextStyle(color: Colors.red),
        )),
      );
    }
  }
}
