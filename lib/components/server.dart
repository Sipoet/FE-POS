import 'package:http/http.dart' as http;

class Server {
  Server(
      {required this.host,
      required this.port,
      required this.jwt,
      required this.session});
  String host;
  int port;
  String jwt;
  String session;

  Future post(String path, Map body) async {
    var client = http.Client();
    Uri url = _generateUrl(path, {});
    try {
      var response = await client.post(url, body: body);
      return response;
    } finally {
      client.close();
    }
  }

  Future get(String path, Map<String, dynamic> queryParam) async {
    var client = http.Client();
    Uri url = _generateUrl(path, queryParam);
    try {
      var response = await http.get(url);
      return response;
    } finally {
      client.close();
    }
  }

  Future put(String path, Map body) async {
    var client = http.Client();
    Uri url = _generateUrl(path, {});
    try {
      var response = await http.put(url, body: body);
      return response;
    } finally {
      client.close();
    }
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
