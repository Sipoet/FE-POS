import 'package:flutter/material.dart';
import 'package:fe_pos/components/framework_layout.dart';
import 'package:fe_pos/pages/login.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/session_state.dart';

class Loading extends StatefulWidget {
  const Loading({super.key});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  void reroute() async {
    SessionState sessionState = context.read<SessionState>();
    sessionState.fetchServerData().then((isLogin) => {
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

  @override
  Widget build(BuildContext context) {
    reroute();
    return const Placeholder();
  }
}
