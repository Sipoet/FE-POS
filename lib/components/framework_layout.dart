import 'package:flutter/material.dart';
import 'package:fe_pos/pages/generator.dart';
import 'package:fe_pos/pages/report.dart';
import 'package:fe_pos/pages/home.dart';

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
      'page': Home(),
      'children': {},
      'key': 'home'
    },
    'sales': {
      'icon': Icons.money,
      'label': 'Sales',
      'page': Placeholder(),
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
          'page': SalesPercentageReportPage(),
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
    'purchase': {
      'icon': Icons.money,
      'label': 'Purchase',
      'page': const Placeholder(),
      'key': 'purchase',
      'children': {
        'purchase1': {
          'icon': Icons.pageview,
          'label': 'Purchase lain 1',
          'page': const Placeholder(),
          'key': 'purchase1',
          'children': {}
        },
        'purchase2': {
          'icon': Icons.pageview,
          'label': 'Purchase lain 2',
          'page': const Placeholder(),
          'key': 'purchase2',
          'children': {}
        }
      },
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
                      // selectedIndex = 0;
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
}
