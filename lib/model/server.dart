import 'dart:io';
import 'dart:typed_data';
import 'package:dio/io.dart';
import 'package:dio/dio.dart';
export 'package:dio/dio.dart';
export 'package:dio/io.dart';
export 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class Server extends ChangeNotifier {
  String host;
  String jwt;
  String userName;
  Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      validateStatus: (int? status) {
        if (status != null && status <= 308 && status >= 200) {
          return true;
        }
        return [409].contains(status);
      },
    ),
  );

  Server({this.host = 'localhost', this.jwt = '', this.userName = ''}) {
    if (kIsWeb) {
      host = Uri.base.host;
    }
  }

  void setCert() {
    if (kIsWeb) return;
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final HttpClient client = HttpClient(
          context: SecurityContext(withTrustedRoots: false),
        );
        // ignore bad certificate
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
    );
  }

  Future<Response> upload(
    String path, {
    List<int>? bytes,
    String? filename,
    String? filepath,
  }) async {
    FormData formData;
    formData = FormData.fromMap({
      "file": bytes != null
          ? MultipartFile.fromBytes(bytes, filename: filename)
          : await MultipartFile.fromFile(filepath!, filename: filename),
    });
    Uri url = generateUrl(path, {});
    return dio.postUri(
      url,
      data: formData,
      options: generateHeaders(.multipartForm, .json),
    );
  }

  Future<Response> post(
    String path, {
    Object? body,
    HttpContentType contentType = .json,
    ResponseType responseType = .json,
    HttpContentType? acceptHeader,
    CancelToken? cancelToken,
  }) async {
    Uri url = generateUrl(path, {});
    return dio.postUri(
      url,
      data: body,
      cancelToken: cancelToken,
      options: generateHeaders(
        contentType,
        responseType,
        acceptHeader: acceptHeader,
      ),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic> queryParam = const {},
    HttpContentType contentType = .json,
    ResponseType responseType = .json,
    HttpContentType? acceptHeader,
    CancelToken? cancelToken,
  }) async {
    Uri url = generateUrl(path, queryParam);
    return dio.getUri(
      url,
      cancelToken: cancelToken,
      options: generateHeaders(
        contentType,
        responseType,
        acceptHeader: acceptHeader,
      ),
    );
  }

  Future<Response> put(
    String path, {
    Object? body,
    HttpContentType contentType = .json,
    ResponseType responseType = .json,
    HttpContentType? acceptHeader,
    CancelToken? cancelToken,
  }) async {
    Uri url = generateUrl(path, {});
    return dio.putUri(
      url,
      data: body,
      cancelToken: cancelToken,
      options: generateHeaders(
        contentType,
        responseType,
        acceptHeader: acceptHeader,
      ),
    );
  }

  Future delete(
    String path, {
    Map body = const {},
    HttpContentType contentType = .json,
    CancelToken? cancelToken,
  }) async {
    Uri url = generateUrl(path, {});
    return dio.deleteUri(
      url,
      data: body,
      cancelToken: cancelToken,
      options: generateHeaders(contentType, .json),
    );
  }

  Future<Uint8List?> download({
    String? url,
    String? path,
    ResponseType responseType = .bytes,
    required HttpContentType acceptHeader,
    void Function(int, int)? onReceiveProgress,
    void Function(Response)? onSuccess,
  }) {
    if (path != null) {
      url = "https://$host/api/$path";
    }
    debugPrint('url $url');
    return dio
        .get<List<int>>(
          url!,
          onReceiveProgress: onReceiveProgress,
          options: path != null
              ? generateHeaders(.json, responseType, acceptHeader: acceptHeader)
              : Options(
                  responseType: ResponseType.bytes,
                  contentType: 'text/plain',
                ),
        )
        .then((response) {
          if (response.statusCode == 200 || response.statusCode == 201) {
            onSuccess?.call(response);
          }
          final data = response.data;
          if (data is Uint8List) {
            return data;
          } else if (data is List<int>) {
            Uint8List.fromList(data);
          }
          return null;
        });
  }

  Options generateHeaders(
    HttpContentType contentType,
    ResponseType responseType, {
    HttpContentType? acceptHeader,
  }) {
    return Options(
      headers: {
        if (jwt.isNotEmpty) 'Authorization': jwt,
        if (acceptHeader != null) Headers.acceptHeader: acceptHeader.toString(),
      },
      contentType: contentType.toString(),
      responseType: responseType,
    );
  }

  // String acceptHeader(ResponseType responseType) {
  //   switch (responseType) {
  //     case .json:
  //       return 'application/json';
  //     case .bytes:
  //       return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  //     case .plain:
  //       return 'application/pdf';
  //     default:
  //       return 'application/json';
  //   }
  // }

  Uri generateUrl(String path, Map<String, dynamic> queryParams) {
    return Uri(
      scheme: 'https',
      host: host,
      path: "api/$path",
      queryParameters: queryParams,
    );
  }
}

enum HttpContentType {
  json,
  multipartForm,
  xlsx,
  pdf,
  plain,
  windowsApp,
  androidApp,
  image,
  jpg,
  png,
  bmp,
  binary;

  @override
  String toString() {
    switch (this) {
      case json:
        return 'application/json';
      case multipartForm:
        return 'multipart/form-data';
      case xlsx:
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case pdf:
        return 'application/pdf';
      case plain:
        return 'text/plain';
      case image:
        return 'image/*';
      case jpg:
        return 'image/jpeg';
      case png:
        return 'image/png';
      case bmp:
        return 'image/bmp';
      case androidApp:
        return 'application/vnd.android.package-archive';
      case windowsApp:
        return 'application/vnd.microsoft.portable-executable';
      case binary:
        return 'application/octet-stream';
    }
  }

  static HttpContentType fromString(String? value) {
    switch (value) {
      case 'application/json':
        return json;
      case 'multipart/form-data':
        return multipartForm;
      case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        return xlsx;
      case 'application/pdf':
        return pdf;
      case 'text/plain':
        return plain;
      case 'image/*':
        return image;
      case 'image/jpeg':
        return jpg;
      case 'image/png':
        return png;
      case 'image/bmp':
        return bmp;
      case 'application/vnd.android.package-archive':
        return androidApp;
      case 'application/vnd.microsoft.portable-executable':
        return windowsApp;
      case 'application/octet-stream':
        return binary;
      default:
        throw 'not on the list';
    }
  }

  String? get extName {
    switch (this) {
      case json:
        return 'json';
      case xlsx:
        return 'xlsx';
      case pdf:
        return 'pdf';
      case plain:
        return 'txt';
      case jpg:
        return 'jpg';
      case png:
        return 'png';
      case bmp:
        return 'bmp';
      case androidApp:
        return 'apk';
      case windowsApp:
        return 'exe';
      default:
        return null;
    }
  }
}
