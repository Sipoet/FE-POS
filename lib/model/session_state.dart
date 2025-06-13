import 'dart:convert';
import 'dart:developer';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/page/login_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
export 'package:fe_pos/model/server.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

mixin SessionState<T extends StatefulWidget> on State<T>
    implements DefaultResponse<T> {
  final _storage = const FlutterSecureStorage();
  static const storageServerKey = 'server';
  Future fetchServerData(Server server) async {
    try {
      server.setCert();
      String? sessionString = await _storage.read(key: storageServerKey);
      if (sessionString != null) {
        final sessionData = jsonDecode(sessionString);
        server.host = sessionData['host'] ?? '';
        server.jwt = sessionData['jwt'];
        server.userName = sessionData['userName'] ?? '';
      }
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
        final flash = Flash();
        flash.show(Text(error.toString()), ToastificationType.error);
      }
    }, onError: (error, stackTrace) {
      final flash = Flash();
      flash.show(
          Text(
            "${error.toString()} ${stackTrace.toString()}",
            style: const TextStyle(fontSize: 9),
          ),
          ToastificationType.error);
      if (error.type == DioExceptionType.badResponse) {
        onFailed(error.response);
      } else {
        defaultErrorResponse(error: error);
      }
    });
  }

  Future logout(Server server) {
    final navigator = Navigator.of(context);
    return server.delete('logout').then((response) {
      var body = response.data;
      final flash = Flash();
      if (response.statusCode == 200) {
        server.jwt = '';
        saveSession(server);

        flash.showBanner(
          title: body['message'],
          messageType: ToastificationType.success,
        );
        navigator.pushReplacement(MaterialPageRoute(
            builder: (BuildContext context) => const LoginPage()));
      } else {
        flash.show(
            Text(
              body['error'],
            ),
            ToastificationType.error);
      }
    }, onError: (error, stackTrace) => defaultErrorResponse(error: error));
  }

  void saveSession(Server server) async {
    _storage.write(
        key: storageServerKey,
        value: jsonEncode({
          'host': server.host,
          'jwt': server.jwt,
          'userName': server.userName
        }));
  }
}
