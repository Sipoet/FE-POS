import 'package:fe_pos/page/loading_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

void main() {
  runApp(const AllegraPos());
}

class AllegraPos extends StatelessWidget {
  const AllegraPos({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionState sessionState = SessionState();

    return ChangeNotifierProvider(
      create: (context) => sessionState,
      child: MaterialApp(
        title: 'Allegra POS',
        theme: ThemeData(
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            showCloseIcon: true,
          ),
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
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
