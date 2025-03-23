import 'package:fe_pos/page/loading_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:toastification/toastification.dart';

void main() {
  runApp(const AllegraPos());
}

class AllegraPos extends StatelessWidget {
  const AllegraPos({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<Server>(create: (_) => Server()),
          ChangeNotifierProvider<Setting>(create: (_) => Setting()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Allegra POS',
          theme: ThemeData(
            fontFamily: 'Lato',
            textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Lato'),
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 135, 239, 154)),
            dividerTheme: const DividerThemeData(
              space: 20,
              color: Colors.grey,
              thickness: 1,
              indent: 10,
              endIndent: 10,
            ),
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (_, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: MediaQuery.of(context)
                  .textScaler
                  .clamp(minScaleFactor: 0.8, maxScaleFactor: 1.2),
            ),
            child: child!,
          ),
          supportedLocales: const [
            Locale('en'),
            Locale('id'),
          ],
          locale: const Locale('id'),
          home: const LoadingPage(),
        ),
      ),
    );
  }
}
