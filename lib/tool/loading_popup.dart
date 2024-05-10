import 'package:flutter/material.dart';

mixin LoadingPopup<T extends StatefulWidget> on State<T> {
  void showLoadingPopup() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return Center(
            child: SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                color: colorScheme.onPrimary,
                backgroundColor: colorScheme.onPrimaryContainer,
              ),
            ),
          );
        });
  }

  void hideLoadingPopup() {
    Navigator.pop(context);
  }
}
