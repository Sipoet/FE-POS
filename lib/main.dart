// import 'package:flutter/material.dart';
// import 'package:fe_pos/pages/home.dart';
// import 'package:fe_pos/pages/loading.dart';

// void main() {
//   runApp(MaterialApp(initialRoute: '/', routes: {
//     // '/': (context) => const Loading(),
//     '/': (context) => const Home(),
//     '/home': (context) => const Home(),
//     '/report': (context) => const Report(),
//   }));
// }

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/pages/report.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];
  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }

  void resetFavorite() {
    favorites.clear();
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  int level = 1;
  Map menuTree = {
    'sales': {
      'icon': Icons.money,
      'label': 'Sales',
      'page': GeneratorPage(),
      'children': {},
      'key': 'sales'
    },
    'report': {
      'icon': Icons.pages,
      'label': 'Report',
      'page': Placeholder(),
      'parentTraces': [],
      'key': 'report',
      'children': {
        'percentageSales': {
          'icon': Icons.pages,
          'label': 'Penjualan persentase per item',
          'page': ReportPage(),
          'key': 'percentageSales',
          'children': {}
        },
        'otherReport': {
          'icon': Icons.pageview,
          'label': 'report lain',
          'page': Placeholder(),
          'key': 'otherReport',
          'children': {
            'otherReport1': {
              'icon': Icons.pageview,
              'label': 'report lain 1',
              'page': Placeholder(),
              'key': 'otherReport1',
              'children': {}
            },
            'otherReport2': {
              'icon': Icons.pageview,
              'label': 'report lain 2',
              'page': Placeholder(),
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
      'page': Placeholder(),
      'key': 'purchase',
      'children': {
        'purchase1': {
          'icon': Icons.pageview,
          'label': 'Purchase lain 1',
          'page': Placeholder(),
          'key': 'purchase1',
          'children': {}
        },
        'purchase2': {
          'icon': Icons.pageview,
          'label': 'Purchase lain 2',
          'page': Placeholder(),
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
    var leadingWidgets = <Widget>[
      IconButton.filledTonal(
        icon: Icon(Icons.home),
        onPressed: () {
          setState(() {
            selectedIndex = 0;
            parentTraces = [];
          });
        },
      )
    ];
    destinations = menuTree;
    for (var trace in parentTraces) {
      destinations = destinations[trace]['children'];
    }
    if (parentTraces.length > 0) {
      leadingWidgets.add(SizedBox(width: 10));
      leadingWidgets.add(ElevatedButton.icon(
          label: Text('Back'),
          onPressed: () {
            setState(() {
              selectedIndex = 0;
              parentTraces.removeLast();
            });
          },
          icon: Icon(Icons.arrow_back)));
    }
    var arrDestination = [];
    destinations
        .forEach((label, destination) => arrDestination.add(destination));
    print(arrDestination.toString());
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
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.resetFavorite();
                },
                child: Text('reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!
        .copyWith(color: theme.colorScheme.onPrimary);
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(pair.asLowerCase,
            style: style, semanticsLabel: "${pair.first} ${pair.second}"),
      ),
    );
  }
}
