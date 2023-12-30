import 'package:flutter/material.dart';

enum MessageType { success, failed, info, warning }

class Flash extends ChangeNotifier {
  BuildContext context;
  ScaffoldMessengerState? messenger;

  Flash(this.context);
  void show(Widget content, MessageType messageType) {
    hide();
    messenger = ScaffoldMessenger.of(context);
    MaterialColor color = _colorBasedMessageType(messageType);
    messenger?.showMaterialBanner(MaterialBanner(
      elevation: 1,
      padding: const EdgeInsets.all(20),
      content: content,
      backgroundColor: color,
      actions: <Widget>[
        TextButton(
          onPressed: () {
            hide();
          },
          child: const Text(
            'DISMISS',
            selectionColor: Colors.black,
          ),
        ),
      ],
    ));
    if (messageType == MessageType.success) {
      Future.delayed(const Duration(seconds: 3), () {
        hide();
      });
    }
  }

  void showBanner(
      {String title = '',
      String description = '',
      required MessageType messageType}) {
    hide();
    messenger = ScaffoldMessenger.of(context);
    MaterialColor color = _colorBasedMessageType(messageType);

    messenger?.showMaterialBanner(MaterialBanner(
      elevation: 1,
      padding: const EdgeInsets.all(20),
      content: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Flexible(child: Text(description))
          ],
        ),
      ),
      backgroundColor: color,
      actions: <Widget>[
        TextButton(
          onPressed: () {
            messenger?.clearMaterialBanners();
          },
          child: const Text('DISMISS'),
        ),
      ],
    ));
    if (messageType == MessageType.success) {
      Future.delayed(const Duration(seconds: 3), () {
        hide();
      });
    }
  }

  MaterialColor _colorBasedMessageType(MessageType messageType) {
    switch (messageType) {
      case MessageType.warning:
        return Colors.yellow;
      case MessageType.failed:
        return Colors.red;
      case MessageType.success:
        return Colors.green;
      case MessageType.info:
      default:
        return Colors.blue;
    }
  }

  void hide() {
    messenger = messenger ?? ScaffoldMessenger.of(context);
    messenger?.clearMaterialBanners();
  }
}
