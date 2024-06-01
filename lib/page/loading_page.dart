import 'package:fe_pos/tool/setting.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/page/login_page.dart';
import 'package:fe_pos/widget/framework_layout.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  late Setting setting;
  @override
  void initState() {
    checkPermission().then((_) {
      reroute();
    });
    super.initState();
  }

  void fetchSetting(Server server) async {
    setting = context.read<Setting>();
    server.get('settings').then((response) {
      try {
        if (response.statusCode == 200) {
          setting.setTableColumns(response.data['data']['table_columns']);

          response.data['data']['menus'].forEach((String key, value) {
            setting.menus[key] =
                value.map<String>((e) => e.toString()).toList();
          });
        }
      } catch (error) {
        AlertDialog(
          title: const Text('error'),
          content: Text(error.toString()),
          actions: [
            ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('close'))
          ],
        );
      }
    }).whenComplete(() {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const FrameworkLayout()));
    });
  }

  Future<void> checkPermission() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
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
    } catch (error) {
      AlertDialog(
        title: const Text('error'),
        content: Text(error.toString()),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('close'))
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  color: colorScheme.primary,
                  backgroundColor: colorScheme.primaryContainer,
                  semanticsLabel: 'Loading data',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void reroute() {
    try {
      initializeDateFormatting('id_ID', null);
      SessionState sessionState = context.read<SessionState>();
      Server server = context.read<Server>();
      sessionState.fetchServerData(server).then((isLogin) {
        if (isLogin) {
          fetchSetting(server);
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const LoginPage()));
        }
      });
    } catch (error) {
      AlertDialog(
        title: const Text('error'),
        content: Text(error.toString()),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('close'))
        ],
      );
    }
  }
}
