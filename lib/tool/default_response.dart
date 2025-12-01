import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:fe_pos/page/loading_page.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/tool/flash.dart';

mixin DefaultResponse<T extends StatefulWidget> on State<T> {
  dynamic defaultErrorResponse({required var error, final valueWhenError}) {
    Flash flash = Flash();
    if (error.runtimeType.toString() == '_TypeError' ||
        error is ArgumentError) {
      throw error;
    }

    dynamic response;
    try {
      response = error.response;
    } catch (e) {
      flash.showBanner(
          title: 'Gagal',
          description: error.toString(),
          messageType: ToastificationType.error);
      return valueWhenError;
    }

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
    double tableHeight = size.height - padding.top - padding.bottom - 250;
    return tableHeight < 400 ? 400.0 : tableHeight;
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
