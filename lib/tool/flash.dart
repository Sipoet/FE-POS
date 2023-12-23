import 'package:flutter/material.dart';

enum MessageType { success, failed, info, warning }

class Flash extends ChangeNotifier {
  BuildContext context;

  Flash(this.context);
  void show(Widget content, MessageType messageType) {
    hide();
    var messenger = ScaffoldMessenger.of(context);
    MaterialColor color = colorBasedMessageType(messageType);

    messenger.showMaterialBanner(MaterialBanner(
      padding: const EdgeInsets.all(20),
      content: content,
      backgroundColor: color,
      actions: <Widget>[
        TextButton(
          onPressed: () {
            messenger.clearMaterialBanners();
          },
          child: const Text('DISMISS'),
        ),
      ],
    ));
  }

  void showBanner(
      {String title = '',
      String description = '',
      required MessageType messageType}) {
    hide();
    var messenger = ScaffoldMessenger.of(context);
    MaterialColor color = colorBasedMessageType(messageType);

    messenger.showMaterialBanner(MaterialBanner(
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
            Text(description)
          ],
        ),
      ),
      backgroundColor: color,
      actions: <Widget>[
        TextButton(
          onPressed: () {
            messenger.clearMaterialBanners();
          },
          child: const Text('DISMISS'),
        ),
      ],
    ));
  }

  MaterialColor colorBasedMessageType(MessageType messageType) {
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
    ScaffoldMessenger.of(context).clearMaterialBanners();
  }
}
