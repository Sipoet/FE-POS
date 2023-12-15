import 'dart:convert';
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
  @override
  Widget build(BuildContext context) {
    SessionState sessionState = context.read<SessionState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
          child: Container(
        alignment: Alignment.centerLeft,
        width: 300,
        padding: const EdgeInsets.all(8.0),
        child: Form(
            key: _formKey,
            child: Column(
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
                  validator: (value) {
                    if (value == null || value.toString().trim().isEmpty) {
                      return 'password belum diisi';
                    } else if (value.toString().contains(' ')) {
                      return 'username tidak boleh ada spasi';
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
                          displayFlash(const Text('Loading'));
                          _submit(sessionState, ScaffoldMessenger.of(context));
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

  void _submit(sessionState, messenger) async {
    _formKey.currentState?.save();
    try {
      sessionState.login(
          host: _host,
          username: _username,
          password: _password,
          onSuccess: (response) {
            messenger.clearSnackBars();
            _redirectToHomePage();
            var body = jsonDecode(response.body);
            displayFlash(Text(
              body['message'],
              style: const TextStyle(color: Colors.green),
            ));
          },
          onFailed: (response) {
            messenger.clearSnackBars();
            var body = jsonDecode(response.body);
            displayFlash(Text(
              body['error'],
              style: const TextStyle(color: Colors.red),
            ));
          });
    } catch (error) {
      displayFlash(Text(
        error.toString(),
        style: const TextStyle(color: Colors.red),
      ));
    }
  }

  void displayFlash(Widget content) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(child: content),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.up,
        margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 60,
            left: 50,
            right: 50),
      ),
    );
  }

  void _redirectToHomePage() {
    Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const FrameworkLayout(),
        ));
  }
}
