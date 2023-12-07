import 'package:http/http.dart' as http;
import 'dart:convert';

class Server {
  Server({this.host = 'localhost', this.port = 3000, this.jwt = ''});
  String host;
  int port;
  String jwt;

  String requestBodyByType(body, type) {
    switch (type) {
      case 'json':
        return jsonEncode(body);
      default:
        return body.toString();
    }
  }

  String responseBodyByType(body, type) {
    switch (type) {
      case 'json':
        return jsonDecode(body);
      default:
        return body.toString();
    }
  }

  Future post(String path, Map body, {String type = 'json'}) async {
    Uri url = _generateUrl(path, {});
    String requestBody = requestBodyByType(body, type);
    return http.post(url, body: requestBody, headers: generateHeaders(type));
  }

  Future get(String path, Map<String, dynamic> queryParam,
      {String type = 'json'}) async {
    Uri url = _generateUrl(path, queryParam);
    return http.get(url, headers: generateHeaders(type));
  }

  Future put(String path, Map body, {String type = 'json'}) async {
    Uri url = _generateUrl(path, {});
    String requestBody = requestBodyByType(body, type);
    return http.put(url, body: requestBody, headers: generateHeaders(type));
  }

  Future delete(String path, Map body, {String type = 'json'}) async {
    Uri url = _generateUrl(path, {});
    String requestBody = requestBodyByType(body, type);
    return http.delete(url, body: requestBody, headers: generateHeaders(type));
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
        scheme: 'http',
        host: host,
        port: port,
        path: path,
        queryParameters: queryParams);
  }
}
