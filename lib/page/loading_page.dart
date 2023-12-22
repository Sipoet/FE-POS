import 'package:fe_pos/tool/setting.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/page/login_page.dart';
import 'package:fe_pos/widget/framework_layout.dart';

import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with TickerProviderStateMixin {
  late AnimationController controller;
  late Setting setting;
  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        setState(() {});
      });
    setting = context.read<Setting>();
    reroute();
    controller.repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Text(
                'Loading',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              CircularProgressIndicator(
                value: controller.value,
                semanticsLabel: 'Circular progress indicator',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> fetchSetting() async {
    await _fetchTableColumn();
  }

  Future<void> _fetchTableColumn() async {
    var server = context.read<SessionState>().server;

    var response = await server.get('discounts/columns');
    if (response.statusCode != 200) {
      return;
    }
    Map responseBody = response.data;
    var data = responseBody['data'] ?? {'column_names': [], 'column_order': []};
    setting
      ..discountColumnOrder =
          data['column_order'].map<String>((e) => e.toString()).toList()
      ..discountColumns = data['column_names'];
  }

  void reroute() async {
    SessionState sessionState = context.read<SessionState>();
    sessionState.fetchServerData().then((isLogin) => {
          controller.stop(),
          if (isLogin)
            {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FrameworkLayout())),
            }
          else
            {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const LoginPage())),
            }
        });
  }
}
