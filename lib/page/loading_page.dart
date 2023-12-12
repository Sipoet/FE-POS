import 'package:flutter/material.dart';
import 'package:fe_pos/widget/framework_layout.dart';
import 'package:fe_pos/page/login_page.dart';
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

  @override
  void initState() {
    controller = AnimationController(
      /// [AnimationController]s can be created with `vsync: this` because of
      /// [TickerProviderStateMixin].
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        setState(() {});
      });
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

  void reroute() async {
    SessionState sessionState = context.read<SessionState>();
    sessionState.fetchServerData().then((isLogin) => {
          controller.stop(),
          if (isLogin)
            {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FrameworkLayout()))
            }
          else
            {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const LoginPage()))
            }
        });
  }
}
