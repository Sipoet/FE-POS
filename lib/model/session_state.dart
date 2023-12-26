import 'dart:convert';
import 'dart:io';
import 'package:fe_pos/model/server.dart';
export 'package:fe_pos/model/server.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionState extends ChangeNotifier {
  Server server = Server();

  final _storage = const FlutterSecureStorage();

  Future fetchServerData() async {
    try {
      String? sessionString = await _storage.read(key: 'server');
      if (sessionString != null) {
        var sessionData = jsonDecode(sessionString);
        server.host = sessionData['host'];
        server.jwt = sessionData['jwt'];
      }
      await server.setCert();
    } catch (e) {
      // unknown error
    }

    return await isLogin();
  }

  Future<bool> isLogin() async {
    if (server.jwt.isEmpty) {
      return false;
    }
    try {
      var response = await server.get('');
      return response.statusCode == 200;
    } catch (error) {
      return false;
    }
  }

  Future login({
    required String username,
    required String password,
    required String host,
    required Function onSuccess,
    required Function onFailed,
    required BuildContext context,
  }) async {
    String jwtBefore = server.jwt;
    server.jwt = '';
    if (host.isNotEmpty) server.host = host;
    return server.post('login', body: {
      'user': {'username': username, 'password': password}
    }).then((response) {
      if (response.statusCode == 200) {
        server.jwt = response.headers.value('Authorization');
        saveSession();
        onSuccess(response);
      } else {
        server.jwt = jwtBefore;
        onFailed(response);
      }
    }, onError: (error, stackTrace) {
      print(error);
      if (error.type == DioExceptionType.badResponse) {
        onFailed(error.response);
      } else {
        server.defaultResponse(context: context, error: error);
      }
    });
  }

  Future logout({
    required Function onSuccess,
    required Function onFailed,
    required BuildContext context,
  }) {
    return server.delete('logout').then(
        (response) => {
              if (response.statusCode == 200)
                {server.jwt = '', saveSession(), onSuccess(response)}
              else
                {onFailed(response)}
            },
        onError: (error, stackTrace) =>
            server.defaultResponse(context: context, error: error));
  }

  Future<String> sessionPath() async {
    Directory? dir = await getApplicationCacheDirectory();
    return "${dir.path}/session.yaml";
  }

  void saveSession() async {
    _storage.write(
        key: 'server',
        value: jsonEncode({'host': server.host, 'jwt': server.jwt}));
  }
}
