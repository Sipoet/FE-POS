import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
export 'package:toastification/toastification.dart';

class Flash extends ChangeNotifier {
  Flash();
  void show(
    Widget content,
    ToastificationType messageType, {
    Duration? duration,
  }) {
    hide();
    if (messageType == .success && duration == null) {
      duration = const Duration(seconds: 5);
    }
    toastification.show(
      autoCloseDuration: duration,
      title: content,
      type: messageType,
    );
  }

  void showBanner({
    String title = '',
    String description = '',
    required ToastificationType messageType,
    Duration? duration,
  }) {
    hide();
    if (messageType == .success && duration == null) {
      duration = const Duration(seconds: 5);
    }
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
