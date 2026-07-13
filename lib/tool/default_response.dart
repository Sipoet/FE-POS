import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:fe_pos/page/loading_page.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/tool/flash.dart';

mixin DefaultResponse<T extends StatefulWidget> on State<T> {
  static const labelStyle = TextFormatter.labelStyle;

  dynamic defaultErrorResponse({
    required var error,
    final valueWhenError,
    List<String> backtrace = const [],
  }) {
    Flash flash = Flash();
    debugPrint(error.toString());
    debugPrint(backtrace.toString());
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
        messageType: ToastificationType.error,
      );
      return valueWhenError;
    }

    switch (error.type) {
      case DioExceptionType.badResponse:
        if (response?.statusCode == 401) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoadingPage()),
          );
        } else if (response?.statusCode == 500) {
          flash.showBanner(
            title: 'Gagal',
            description: 'Terjadi kesalahan server. hubungi IT support',
            messageType: ToastificationType.error,
          );
        }
        break;
      case DioExceptionType.connectionError:
        flash.showBanner(
          title: 'koneksi terputus',
          description:
              'Pastikan sudah nyalakan VPN atau berada di satu network dengan server',
          messageType: ToastificationType.error,
        );
        break;
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        flash.showBanner(
          title: 'Server sedang sibuk',
          description: 'cobalah beberapa saat lagi',
          messageType: ToastificationType.error,
        );
        break;
      default:
        flash.showBanner(
          title: 'Gagal',
          description: 'Terjadi kesalahan server. hubungi IT support',
          messageType: ToastificationType.error,
        );
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

  void showConfirmDialog({
    required Function onSubmit,
    String message = 'Apakah Anda Yakin?',
  }) {
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

  Future<bool> showConfirmDialog2({String message = 'Apakah Anda Yakin?'}) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: Text(message),
        actions: [
          ElevatedButton(
            child: const Text("Kembali"),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          ElevatedButton(
            child: const Text("Submit"),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    ).then((isSuccess) => isSuccess ?? false);
  }
}
