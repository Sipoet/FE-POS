import 'package:fe_pos/page/loading_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var sessionState = SessionState();

    return ChangeNotifierProvider(
      create: (context) => sessionState,
      child: MaterialApp(
        title: 'Allegra POS',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
          dividerTheme: const DividerThemeData(
              space: 20,
              color: Colors.grey,
              thickness: 1,
              indent: 10,
              endIndent: 10),
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isLoading = true;
  @override
  Widget build(BuildContext context) {
    return const LoadingPage();
  }
}
