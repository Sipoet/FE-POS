import 'dart:developer';
import 'dart:convert';
export 'dart:developer';
export 'dart:convert';
import 'package:fe_pos/components/server.dart';
import 'package:flutter/material.dart';

class DropdownRemoteConnection {
  const DropdownRemoteConnection(this.server);
  final Server server;
  Future<List<DropdownMenuEntry>> getData(String path,
      {String query = ''}) async {
    try {
      var response = await server.get(path, {'query': query});
      if (response.statusCode == 200) {
        Map responseBody = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
        List list = responseBody['data'];
        log(list.toString());
        return list.map<DropdownMenuEntry<String>>((row) {
          return DropdownMenuEntry<String>(
              label: row['name'], value: row['id']);
        }).toList();
      } else {
        return <DropdownMenuEntry<String>>[];
        // throw Error('cant connect to server');
      }
    } catch (err) {
      log('Caught error: $err');
      return [];
    }
  }
}
