import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:fe_pos/page/loading_page.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/tool/flash.dart';

mixin DefaultResponse<T extends StatefulWidget> on State<T> {
  static const labelStyle =
      TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  dynamic defaultErrorResponse(
      {required var error, List trace = const [], var valueWhenError}) {
    if (error.runtimeType.toString() == '_TypeError') {
      log(error.toString());
      log(trace.toString());
      final flash = Flash();
      flash.showBanner(
          title: error.toString(),
          description: trace.toString(),
          messageType: ToastificationType.error);
      throw error;
    }
    if (error is ArgumentError) {
      debugPrint('error: ${error.toString()}');
      return;
    }
    var response = error.response;
    switch (error.type) {
      case DioExceptionType.badResponse:
        if (response?.statusCode == 401) {
          Navigator.pop(context);
          Navigator.push(context,
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
                'Pastikan sudah nyalakan VPN atau berada di satu network dengan server',
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

  double get bodyScreenHeight {
    final padding = MediaQuery.of(context).padding;
    final size = MediaQuery.of(context).size;
    double tableHeight = size.height - padding.top - padding.bottom - 150;
    return <double>[400.0, tableHeight].max;
  }

  void showConfirmDialog(
      {required Function onSubmit, String message = 'Apakah Anda Yakin?'}) {
    AlertDialog alert = AlertDialog(
      title: const Text("Konfirmasi"),
      content: Text(message),
      actions: [
        ElevatedButton(
          child: const Text("Kembali"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: const Text("Submit"),
          onPressed: () {
            onSubmit();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
