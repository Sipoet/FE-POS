import 'dart:convert';
import 'dart:io';
import 'package:fe_pos/components/server.dart';
export 'package:fe_pos/components/server.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionState extends ChangeNotifier {
  Server server = Server();

  final _storage = const FlutterSecureStorage();

  Future fetchServerData() async {
    String? sessionString = await _storage.read(key: 'server');
    if (sessionString != null) {
      var sessionData = jsonDecode(sessionString);
      server.host = sessionData['host'];
      server.port = sessionData['port'];
      server.jwt = sessionData['jwt'];
    }
    return isLogin();
  }
  // Server(host: 'allegra-pos.net', port: 3000, jwt: '');

  bool isLogin() {
    return server.jwt.isNotEmpty;
  }

  Future login({
    required String username,
    required String password,
    required String host,
    required Function onSuccess,
    required Function onFailed,
  }) {
    String jwtBefore = server.jwt;
    server.jwt = '';
    server.host = host;
    return server.post('login', {
      'user': {'username': username, 'password': password}
    }).then((response) => {
          if (response.statusCode == 200)
            {
              server.jwt = response.headers['authorization'],
              saveSession(),
              onSuccess(response)
            }
          else
            {server.jwt = jwtBefore, onFailed(response)}
        });
  }

  Future logout({
    required Function onSuccess,
    required Function onFailed,
  }) {
    return server.delete('logout', {}).then((response) => {
          if (response.statusCode == 200)
            {server.jwt = '', saveSession(), onSuccess(response)}
          else
            {onFailed(response)}
        });
  }

  Future<String> sessionPath() async {
    Directory? dir = await getApplicationCacheDirectory();
    return "${dir.path}/session.yaml";
  }

  void saveSession() async {
    _storage.write(
        key: 'server',
        value: jsonEncode(
            {'host': server.host, 'port': server.port, 'jwt': server.jwt}));
  }
}
