import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/framework_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _host = '';
  String _username = '';
  String _password = '';
  late Flash flash;

  @override
  void initState() {
    flash = Flash(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SessionState sessionState = context.read<SessionState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
          child: Container(
        alignment: Alignment.topLeft,
        width: 300,
        padding: const EdgeInsets.all(8.0),
        child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!kIsWeb)
                  TextFormField(
                    initialValue: sessionState.server.host,
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
                  onChanged: ((value) {}),
                  validator: (value) {
                    if (value == null || value.toString().trim().isEmpty) {
                      return 'password belum diisi';
                    } else if (value.toString().contains(' ')) {
                      return 'password tidak boleh ada spasi';
                    }
                    return null;
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
                          flash.show(const Text('Loading'), MessageType.info);
                          _submit(sessionState);
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

  void _submit(sessionState) async {
    _formKey.currentState?.save();
    try {
      sessionState.login(
          host: _host,
          context: context,
          username: _username,
          password: _password,
          onSuccess: (response) {
            fetchSetting(sessionState.server);
            flash.hide();
            var body = response.data;
            flash.showBanner(
                title: body['message'], messageType: MessageType.success);
          },
          onFailed: (response) {
            flash.hide();
            if (response.statusCode == 308) {
              flash.show(const Text('status 308'), MessageType.warning);
              return;
            }
            String body = response?.data?['error'] ?? '';
            flash.show(
                Text(
                  body,
                ),
                MessageType.failed);
          });
    } catch (error) {
      flash.show(
          Text(
            error.toString(),
          ),
          MessageType.failed);
    }
  }

  void fetchSetting(Server server) async {
    Setting setting = context.read<Setting>();
    server.get('settings').then((response) {
      if (response.statusCode == 200) {
        setting.tableColumns = response.data['data']['table_columns'];
      }
    }).whenComplete(() {
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
