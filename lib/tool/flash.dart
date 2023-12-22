import 'package:flutter/material.dart';

enum MessageType { success, failed, info, warning }

class Flash extends ChangeNotifier {
  BuildContext context;

  Flash(this.context);
  void show(Widget content, MessageType messageType) {
    hide();
    var messenger = ScaffoldMessenger.of(context);
    // messenger.showSnackBar(
    //   SnackBar(
    //     content: Center(child: content),
    //     behavior: SnackBarBehavior.floating,
    //     dismissDirection: DismissDirection.up,
    //     margin: EdgeInsets.only(
    //         bottom: MediaQuery.of(context).size.height - 60,
    //         left: 50,
    //         right: 50),
    //   ),
    // );
    MaterialColor color;
    switch (messageType) {
      case MessageType.warning:
        color = Colors.yellow;
        break;
      case MessageType.failed:
        color = Colors.red;
        break;
      case MessageType.info:
        color = Colors.blue;
        break;
      case MessageType.success:
        color = Colors.green;
        break;
      default:
        color = Colors.blue;
    }

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

  void hide() {
    ScaffoldMessenger.of(context).clearMaterialBanners();
  }
}
