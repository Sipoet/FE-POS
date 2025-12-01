import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
export 'package:toastification/toastification.dart';

class Flash extends ChangeNotifier {
  Flash();
  void show(Widget content, ToastificationType messageType) {
    hide();
    toastification.show(
      autoCloseDuration: const Duration(seconds: 5),
      title: content,
      type: messageType,
    );
  }

  void showBanner(
      {String title = '',
      String description = '',
      required ToastificationType messageType,
      Duration? duration}) {
    hide();
    toastification.show(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      description: Tooltip(message: description, child: Text(description)),
      type: messageType,
      autoCloseDuration: duration,
    );
  }

  void hide() {
    toastification.dismissAll();
  }
}
