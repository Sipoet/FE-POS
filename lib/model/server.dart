import 'dart:developer';
import 'dart:io';
import 'package:dio/io.dart';
import 'package:dio/dio.dart';
import 'package:fe_pos/page/loading_page.dart';
export 'package:dio/dio.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';

class Server {
  String host;
  String jwt;
  Dio dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    validateStatus: (int? status) {
      if (status != null && status <= 308 && status >= 200) {
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

  dynamic defaultErrorResponse(
      {required BuildContext context, required var error, var valueWhenError}) {
    if (error.runtimeType.toString() == '_TypeError') throw error;
    var response = error.response;
    switch (error.type) {
      case DioExceptionType.badResponse:
        if (response?.statusCode == 401) {
          Navigator.pop(context);
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const LoadingPage()));
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

  Future upload(String path, XFile file) async {
    String fileName = file.path.split('/').last;
    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(file.path, filename: fileName),
    });
    Uri url = generateUrl(path, {});
    return dio.postUri(url,
        data: formData, options: generateHeaders('file', 'json'));
  }

  Future post(String path, {Map body = const {}, String type = 'json'}) async {
    Uri url = generateUrl(path, {});
    return dio.postUri(url, data: body, options: generateHeaders(type, type));
  }

  Future get(String path,
      {Map<String, dynamic> queryParam = const {},
      String type = 'json',
      String? responseType,
      cancelToken}) async {
    Uri url = generateUrl(path, queryParam);
    return dio.getUri(url,
        cancelToken: cancelToken,
        options: generateHeaders(type, responseType ?? type));
  }

  Future put(String path, {Map body = const {}, String type = 'json'}) async {
    Uri url = generateUrl(path, {});
    return dio.putUri(url, data: body, options: generateHeaders(type, type));
  }

  Future delete(String path,
      {Map body = const {}, String type = 'json'}) async {
    Uri url = generateUrl(path, {});
    return dio.deleteUri(url, data: body, options: generateHeaders(type, type));
  }

  Future download(String path, String type, var destinationPath) async {
    return dio.download("https://$host/api/$path", destinationPath,
        options: generateHeaders('json', type));
  }

  final Map<String, ResponseType> _responseTypes = {
    'json': ResponseType.json,
    'text': ResponseType.plain,
    'xlsx': ResponseType.bytes,
    'file': ResponseType.bytes,
  };
  Options generateHeaders(String requestType, String responseType) {
    return Options(
        headers: {
          if (jwt.isNotEmpty) 'Authorization': jwt,
        },
        contentType:
            requestType == 'file' ? 'multipart/form-data' : 'application/json',
        responseType: _responseTypes[responseType]);
  }

  Uri generateUrl(String path, Map<String, dynamic> queryParams) {
    return Uri(
        scheme: 'https',
        host: host,
        path: "api/$path",
        queryParameters: queryParams);
  }
}
