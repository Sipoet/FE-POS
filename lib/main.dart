import 'package:fe_pos/page/loading_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/setting.dart';

void main() {
  runApp(const AllegraPos());
}

class AllegraPos extends StatelessWidget {
  const AllegraPos({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<Server>(create: (_) => Server()),
        ChangeNotifierProvider<SessionState>(create: (_) => SessionState()),
        ChangeNotifierProvider<Setting>(create: (_) => Setting()),
      ],
      child: MaterialApp(
        title: 'Allegra POS',
        theme: ThemeData(
          fontFamily: 'Lato',
          textTheme: Theme.of(context).textTheme.apply(
              fontSizeFactor: 1.1, fontSizeDelta: 2.0, fontFamily: 'Lato'),
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 135, 239, 154)),
          dividerTheme: const DividerThemeData(
              space: 20,
              color: Colors.grey,
              thickness: 1,
              indent: 10,
              endIndent: 10),
        ),
        home: const LoadingPage(),
      ),
    );
  }
}
