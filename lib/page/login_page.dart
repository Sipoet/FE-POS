import 'package:fe_pos/tool/app_updater.dart';
import 'package:fe_pos/tool/default_response.dart';

import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/framework_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with
        AppUpdater,
        SessionState,
        LoadingPopup,
        DefaultResponse,
        PlatformChecker {
  final _formKey = GlobalKey<FormState>();
  String _host = '';
  String _username = '';
  String _password = '';
  String version = '';
  late final Flash flash;
  @override
  void initState() {
    flash = Flash();
    Server server = context.read<Server>();
    PackageInfo.fromPlatform().then((packageInfo) => setState(() {
          version = packageInfo.version;
        }));
    checkUpdate(server);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final server = context.read<Server>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Login | VERSION: $version'),
        actions: [
          IconButton(
              onPressed: () => checkUpdate(server, isManual: true),
              tooltip: 'Check Update App',
              icon: Icon(Icons.update)),
        ],
      ),
      body: Center(
          child: Container(
        alignment: Alignment.topLeft,
        width: 300,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Visibility(
                  visible: !isWeb(),
                  child: TextFormField(
                    initialValue: server.host,
                    decoration: const InputDecoration(
                      icon: Icon(Icons.screen_search_desktop),
                      labelText: 'Server',
                    ),
                    onSaved: (newValue) {
                      _host = newValue.toString().trim();
                    },
                    validator: (value) {
                      if (value == null || value.toString().trim().isEmpty) {
                        return 'server belum diisi';
                      }
                      return null;
                    },
                  ),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    icon: Icon(Icons.person),
                    labelText: 'Username',
                  ),
                  onSaved: (newValue) {
                    _username = newValue.toString().trim();
                  },
                  validator: (value) {
                    if (value == null || value.toString().trim().isEmpty) {
                      return 'username belum diisi';
                    } else if (value.toString().contains(' ')) {
                      return 'username tidak boleh ada spasi';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    icon: Icon(Icons.lock),
                    labelText: 'Password',
                  ),
                  obscureText: true,
                  enableSuggestions: false,
                  onSaved: (newValue) {
                    _password = newValue.toString().trim();
                  },
                  onChanged: ((value) {
                    _password = value.toString().trim();
                  }),
                  validator: (value) {
                    if (value == null || value.toString().trim().isEmpty) {
                      return 'password belum diisi';
                    } else if (value.toString().contains(' ')) {
                      return 'password tidak boleh ada spasi';
                    }
                    return null;
                  },
                  onFieldSubmitted: (value) {
                    // Validate returns true if the form is valid, or false otherwise.
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      _submit();
                    }
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15.0, horizontal: 0),
                    child: ElevatedButton(
                      onPressed: () {
                        // Validate returns true if the form is valid, or false otherwise.
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          _submit();
                        }
                      },
                      child: const Text('Submit'),
                    ),
                  ),
                )
              ],
            )),
      )),
    );
  }

  void _submit() async {
    showLoadingPopup();
    Server server = context.read<Server>();
    _formKey.currentState?.save();
    try {
      login(
          server: server,
          host: _host,
          username: _username,
          password: _password,
          onSuccess: (response) {
            fetchSetting(server);
            flash.hide();
            var body = response.data;
            flash.showBanner(
                title: body['message'],
                messageType: ToastificationType.success);
          },
          onFailed: (response) {
            flash.hide();
            if (response.statusCode == 308) {
              flash.show(const Text('status 308'), ToastificationType.warning);
              return;
            }
            String body = '';
            if (response?.data is Map) {
              body = response?.data?['error'] ?? '';
            } else if (response?.data is String) {
              body = response.data;
            }
            flash.show(
                Text(
                  body,
                ),
                ToastificationType.error);
          }).whenComplete(() => hideLoadingPopup());
    } catch (error) {
      flash.show(
          Text(
            error.toString(),
          ),
          ToastificationType.error);
      hideLoadingPopup();
    }
  }

  void fetchSetting(Server server) async {
    Setting setting = context.read<Setting>();
    server.get('settings').then((response) {
      if (response.statusCode == 200) {
        setting.setTableColumns(response.data['table_columns']);
        setting.menus = {};
        response.data['menus'].forEach((String key, value) {
          setting.menus[key] = value.map<String>((e) => e.toString()).toList();
        });
      }
    },
        onError: (error) => flash.show(
            Text(error.toString()), ToastificationType.error)).whenComplete(() {
      _redirectToHomePage();
    });
  }

  void _redirectToHomePage() {
    Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const FrameworkLayout(),
        ));
  }
}
