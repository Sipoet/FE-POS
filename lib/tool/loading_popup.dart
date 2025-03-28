import 'package:flutter/material.dart';

mixin LoadingPopup<T extends StatefulWidget> on State<T> {
  void showLoadingPopup() {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return Center(
            child: loadingWidget(),
          );
        });
  }

  Widget loadingWidget(
      {double size = 50.0, Color? color, Color? backgroundColor}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          color: color ?? colorScheme.primary,
          backgroundColor: backgroundColor ?? colorScheme.primaryContainer,
        ),
      ),
    );
  }

  void hideLoadingPopup() {
    Navigator.pop(context);
  }
}
