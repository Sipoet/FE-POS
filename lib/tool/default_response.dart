import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:fe_pos/page/loading_page.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/tool/flash.dart';

mixin DefaultResponse<T extends StatefulWidget> on State<T> {
  dynamic defaultErrorResponse({required var error, var valueWhenError}) {
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
}
