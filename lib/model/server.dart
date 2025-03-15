import 'dart:developer';
import 'dart:io';
import 'package:dio/io.dart';
import 'package:dio/dio.dart';
import 'package:fe_pos/page/loading_page.dart';
export 'package:dio/dio.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Server extends ChangeNotifier {
  String host;
  String jwt;
  String userName;
  Dio dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    validateStatus: (int? status) {
      if (status != null && status <= 308 && status >= 200) {
        return true;
      }
      return [409].contains(status);
    },
  ));

  Server({this.host = 'localhost', this.jwt = '', this.userName = ''}) {
    if (kIsWeb) {
      host = Uri.base.host;
    }
  }

  void setCert() {
    if (kIsWeb) return;
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final HttpClient client =
            HttpClient(context: SecurityContext(withTrustedRoots: false));
        // ignore bad certificate
        client.badCertificateCallback = (cert, host, port) => true;
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
          Flash flash = Flash();
          flash.showBanner(
              title: 'Gagal',
              description: 'Terjadi kesalahan server. hubungi IT support',
              messageType: ToastificationType.error);
          log(response.data.toString(), time: DateTime.now());
        }
        break;
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        Flash flash = Flash();
        flash.showBanner(
            title: 'koneksi terputus',
            description:
                'Pastikan IP/domain server sudah benar dan server online',
            messageType: ToastificationType.error);
        break;
    }
    log(error.toString(), time: DateTime.now());
    if (valueWhenError == null) {
      return response ?? error;
    } else {
      return valueWhenError;
    }
  }

  Future upload(String path,
      {List<int>? bytes, String? filename, XFile? file}) async {
    FormData formData;
    formData = FormData.fromMap({
      "file": bytes != null
          ? MultipartFile.fromBytes(bytes, filename: filename)
          : await MultipartFile.fromFile(file!.path, filename: filename),
    });
    Uri url = generateUrl(path, {});
    return dio.postUri(url,
        data: formData, options: generateHeaders('file', 'json'));
  }

  Future post(String path,
      {Map body = const {},
      String type = 'json',
      CancelToken? cancelToken}) async {
    Uri url = generateUrl(path, {});
    return dio.postUri(url,
        data: body,
        cancelToken: cancelToken,
        options: generateHeaders(type, type));
  }

  Future get(String path,
      {Map<String, dynamic> queryParam = const {},
      String type = 'json',
      String? responseType,
      CancelToken? cancelToken}) async {
    Uri url = generateUrl(path, queryParam);
    return dio.getUri(url,
        cancelToken: cancelToken,
        options: generateHeaders(type, responseType ?? type));
  }

  Future put(String path,
      {Map body = const {},
      String type = 'json',
      CancelToken? cancelToken}) async {
    Uri url = generateUrl(path, {});
    return dio.putUri(url,
        data: body,
        cancelToken: cancelToken,
        options: generateHeaders(type, type));
  }

  Future delete(String path,
      {Map body = const {},
      String type = 'json',
      CancelToken? cancelToken}) async {
    Uri url = generateUrl(path, {});
    return dio.deleteUri(url,
        data: body,
        cancelToken: cancelToken,
        options: generateHeaders(type, type));
  }

  Future download(String urlPath, String type, var destinationPath) async {
    return dio.download("https://$host/api/$urlPath", destinationPath,
        options: generateHeaders('json', type));
  }

  final Map<String, ResponseType> _responseTypes = {
    'json': ResponseType.json,
    'text': ResponseType.plain,
    'xlsx': ResponseType.bytes,
    'pdf': ResponseType.bytes,
    'file': ResponseType.bytes,
  };
  Options generateHeaders(String requestType, String responseType) {
    return Options(
        headers: {
          if (jwt.isNotEmpty) 'Authorization': jwt,
          Headers.acceptHeader: acceptHeader(responseType),
        },
        contentType:
            requestType == 'file' ? 'multipart/form-data' : 'application/json',
        responseType: _responseTypes[responseType]);
  }

  String acceptHeader(String responseType) {
    switch (responseType) {
      case 'json':
        return 'application/json';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/json';
    }
  }

  Uri generateUrl(String path, Map<String, dynamic> queryParams) {
    return Uri(
        scheme: 'https',
        host: host,
        path: "api/$path",
        queryParameters: queryParams);
  }
}
