import 'dart:developer';
import 'dart:io';
import 'package:dio/io.dart';
import 'package:dio/dio.dart';
export 'package:dio/dio.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fe_pos/page/login_page.dart';
import 'package:flutter/services.dart' show rootBundle;

class Server {
  String host;
  String jwt;
  Dio dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    validateStatus: (status) {
      if (status is int && status <= 308 && status >= 200) {
        return true;
      }
      return [409].contains(status);
    },
  ));

  Server({this.host = '192.168.1.11', this.jwt = ''}) {
    if (kIsWeb) {
      host = Uri.base.host;
    }
  }

  Future setCert() async {
    if (kIsWeb) return;
    var certificate = await rootBundle.load('assets/certs/192.168.1.11.pem');

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final SecurityContext context = SecurityContext.defaultContext;
        context.setTrustedCertificatesBytes(certificate.buffer.asUint8List(),
            password: 'allegrakss123456789');
        final HttpClient client = HttpClient(context: context);
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );
  }

  dynamic defaultResponse(
      {required BuildContext context, required var error, var valueWhenError}) {
    if (error.runtimeType.toString() == '_TypeError') throw error;
    var response = error.response;
    switch (error.type) {
      case DioExceptionType.badResponse:
        if (response?.statusCode == 401) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const LoginPage()));
        } else if (response?.statusCode == 500) {
          Flash flash = Flash(context);
          flash.showBanner(
              title: 'Gagal',
              description: 'Terjadi kesalahan server. hubungi IT support',
              messageType: MessageType.failed);
          log(response.data.toString(), time: DateTime.now());
        }
        break;
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        Flash flash = Flash(context);
        flash.showBanner(
            title: 'koneksi terputus',
            description:
                'Pastikan sudah nyalakan VPN atau berada di satu network dengan server',
            messageType: MessageType.failed);
        break;
    }
    log(error.toString(), time: DateTime.now());
    if (valueWhenError == null) {
      return response ?? error;
    } else {
      return valueWhenError;
    }
  }

  Future post(String path, {Map body = const {}, String type = 'json'}) async {
    Uri url = _generateUrl(path, {});
    return dio.postUri(url,
        data: body, options: Options(headers: generateHeaders(type)));
  }

  Future get(String path,
      {Map<String, dynamic> queryParam = const {},
      String type = 'json',
      cancelToken}) async {
    Uri url = _generateUrl(path, queryParam);
    return dio.getUri(url,
        cancelToken: cancelToken,
        options: Options(headers: generateHeaders(type)));
  }

  Future put(String path, {Map body = const {}, String type = 'json'}) async {
    Uri url = _generateUrl(path, {});
    return dio.putUri(url,
        data: body, options: Options(headers: generateHeaders(type)));
  }

  Future delete(String path,
      {Map body = const {}, String type = 'json'}) async {
    Uri url = _generateUrl(path, {});
    return dio.deleteUri(url,
        data: body, options: Options(headers: generateHeaders(type)));
  }

  final Map _contentTypes = {
    'json': 'application/json',
    'text': 'application/text',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  };
  Map<String, String> generateHeaders(String type) {
    return {
      if (jwt.isNotEmpty) 'Authorization': jwt,
      'Accept': 'application/json',
      'Content-Type': _contentTypes[type]
    };
  }

  Uri _generateUrl(String path, Map<String, dynamic> queryParams) {
    return Uri(
        scheme: 'https',
        host: host,
        path: "api/$path",
        queryParameters: queryParams);
  }
}
