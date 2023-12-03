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

// import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fe_pos/pages/login.dart';
import 'package:fe_pos/components/framework_layout.dart';
import 'package:fe_pos/components/server.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Allegra POS',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    if (isLogin()) {
      return FrameworkLayout();
    } else {
      return LoginPage();
    }
  }

  bool isLogin() {
    return true;
  }
}

class MyAppState extends ChangeNotifier {
  Server server =
      // Server(host: 'allegra-pos.net', port: 3000, jwt: '', session: '');
      Server(host: 'localhost', port: 3000, jwt: '', session: '');
  // void getNext() {
  //   current = WordPair.random();
  //   notifyListeners();
  // }

  // var favorites = <WordPair>[];
  // void toggleFavorite() {
  //   if (favorites.contains(current)) {
  //     favorites.remove(current);
  //   } else {
  //     favorites.add(current);
  //   }
  //   notifyListeners();
  // }

  // void resetFavorite() {
  //   favorites.clear();
  //   notifyListeners();
  // }
}
