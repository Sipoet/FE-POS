import 'dart:developer';
import 'dart:convert';
import 'package:fe_pos/model/server.dart';
export 'package:fe_pos/model/server.dart';
export 'dart:developer';

class DropdownRemoteConnection {
  const DropdownRemoteConnection(this.server);
  final Server server;
  Future<List> getData(String path, {String query = ''}) async {
    try {
      var response = await server.get(path, {'query': query});
      if (response.statusCode == 200) {
        Map responseBody = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
        List list = responseBody['data'];
        return list;
      } else {
        return [];
        // throw Error('cant connect to server');
      }
    } catch (err) {
      log('Caught error: $err');
      return [];
    }
  }
}
