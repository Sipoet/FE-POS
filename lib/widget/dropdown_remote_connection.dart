import 'package:fe_pos/model/server.dart';
import 'package:flutter/material.dart';
export 'package:fe_pos/model/server.dart';
export 'dart:developer';

class DropdownRemoteConnection {
  const DropdownRemoteConnection(this.server, this.context);
  final Server server;
  final BuildContext context;
  Future<List> getData(String path, {String query = ''}) async {
    var response = await server.get(path, queryParam: {'query': query}).onError(
        (error, stackTrace) => {
              server.defaultErrorResponse(
                  context: context, error: error, valueWhenError: [])
            });
    if (response.statusCode == 200) {
      Map responseBody = response.data as Map;
      List list = responseBody['data'];
      return list;
    } else {
      return [];
      // throw Error('cant connect to server');
    }
  }
}
