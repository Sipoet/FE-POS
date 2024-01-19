import 'dart:io';

import 'package:fe_pos/tool/setting.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/page/login_page.dart';
import 'package:fe_pos/widget/framework_layout.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
    controller.repeat(reverse: true);
    checkPermission().then((_) {
      reroute();
    });
    super.initState();
  }

  void fetchSetting(Server server) async {
    setting = context.read<Setting>();
    server.get('settings').then((response) {
      if (response.statusCode == 200) {
        setting.tableColumns = response.data['data']['table_columns'];
      }
    }).whenComplete(() {
      controller.stop();
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const FrameworkLayout()));
    });
  }

  Future<void> checkPermission() async {
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 30) {
        return;
      }
      var status = await Permission.storage.status;
      if (status.isDenied) {
        await Permission.storage.request().isGranted;
      }
    }
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

  void reroute() {
    initializeDateFormatting('id_ID', null);
    SessionState sessionState = context.read<SessionState>();
    sessionState.fetchServerData().then((isLogin) {
      if (isLogin) {
        fetchSetting(sessionState.server);
      } else {
        controller.stop();
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const LoginPage()));
      }
    });
  }
}
