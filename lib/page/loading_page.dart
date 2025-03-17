import 'package:fe_pos/tool/default_response.dart';
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

class _LoadingPageState extends State<LoadingPage>
    with DefaultResponse, SessionState {
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
    final navigator = Navigator.of(context);
    server.get('settings').then((response) {
      // try {
      if (response.statusCode == 200) {
        setting.setTableColumns(response.data['table_columns']);

        response.data['menus'].forEach((String key, value) {
          setting.menus[key] = value.map<String>((e) => e.toString()).toList();
        });
      }
      // } catch (error) {
      //   AlertDialog(
      //     title: const Text('Error'),
      //     content: Text(error.toString()),
      //     actions: [
      //       ElevatedButton(
      //           onPressed: () => navigator.pop(), child: const Text('close'))
      //     ],
      //   );
      // }
    }).whenComplete(() {
      navigator.pushReplacement(
          MaterialPageRoute(builder: (context) => const FrameworkLayout()));
    });
  }

  Future<void> checkPermission() async {
    try {
      List<Permission> permissions = [];
      if (defaultTargetPlatform == TargetPlatform.android) {
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        permissions.addAll([
          Permission.requestInstallPackages,
        ]);
        if (androidInfo.version.sdkInt <= 32) {
          permissions.add(Permission.storage);
        } else {
          // permissions.add(Permission.photos);
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        permissions.addAll([Permission.mediaLibrary, Permission.photos]);
      }
      for (Permission permission in permissions) {
        _requestPermission(permission);
      }
    } catch (error) {
      AlertDialog(
        title: const Text('Error'),
        content: Text(error.toString()),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('close'))
        ],
      );
    }
  }

  Future _requestPermission(Permission permission) async {
    debugPrint('===cek permission ${permission.toString()}');
    final status = await permission.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      await permission.request().isGranted;
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
      Server server = context.read<Server>();
      final navigator = Navigator.of(context);
      fetchServerData(server).then((isLogin) {
        try {
          if (isLogin) {
            fetchSetting(server);
          } else {
            navigator.pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()));
          }
        } catch (error) {
          AlertDialog(
            title: const Text('Error'),
            content: Text(error.toString()),
            actions: [
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('close'))
            ],
          );
        }
      }, onError: (error) => defaultErrorResponse(error: error));
    } catch (error) {
      AlertDialog(
        title: const Text('Error'),
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
