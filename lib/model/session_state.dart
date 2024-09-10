import 'dart:convert';
import 'dart:developer';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/flash.dart';
export 'package:fe_pos/model/server.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionState extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();

  Future fetchServerData(Server server) async {
    try {
      String? sessionString = await _storage.read(key: 'server');
      if (sessionString != null) {
        final sessionData = jsonDecode(sessionString);
        server.host = sessionData['host'] ?? '';
        server.jwt = sessionData['jwt'];
        server.userName = sessionData['userName'] ?? '';
      }
      await server.setCert();
    } catch (error) {
      log(error.toString());
    }

    return await isLogin(server);
  }

  Future<bool> isLogin(Server server) async {
    if (server.jwt.isEmpty) {
      return false;
    }
    try {
      var response = await server.get('settings');
      return response.statusCode == 200;
    } catch (error) {
      return false;
    }
  }

  Future login({
    required Server server,
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
      try {
        if (response.statusCode == 200) {
          server.jwt = response.headers.value('Authorization');
          server.userName = username;

          saveSession(server);
          onSuccess(response);
        } else {
          server.jwt = jwtBefore;
          onFailed(response);
        }
      } catch (error) {
        final flash = Flash(context);
        flash.show(Text(error.toString()), MessageType.failed);
      }
    }, onError: (error, stackTrace) {
      final flash = Flash(context);
      flash.show(Text("${error.toString()} ${stackTrace.toString()}"),
          MessageType.failed);
      if (error.type == DioExceptionType.badResponse) {
        onFailed(error.response);
      } else {
        server.defaultErrorResponse(context: context, error: error);
      }
    });
  }

  Future logout({
    required Server server,
    required Function onSuccess,
    required Function onFailed,
    required BuildContext context,
  }) {
    return server.delete('logout').then(
        (response) => {
              if (response.statusCode == 200)
                {server.jwt = '', saveSession(server), onSuccess(response)}
              else
                {onFailed(response)}
            },
        onError: (error, stackTrace) =>
            server.defaultErrorResponse(context: context, error: error));
  }

  void saveSession(Server server) async {
    _storage.write(
        key: 'server',
        value: jsonEncode({
          'host': server.host,
          'jwt': server.jwt,
          'userName': server.userName
        }));
  }
}
