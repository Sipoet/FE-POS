import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProtectedImage extends StatelessWidget {
  final Widget child;
  const ProtectedImage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        // Intercept and swallow Copy shortcuts
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC):
            VoidCallbackIntent(() {}),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyC):
            VoidCallbackIntent(() {}),
        // Intercept and swallow Save shortcuts (Ctrl+S / Cmd+S)
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            VoidCallbackIntent(() {}),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS):
            VoidCallbackIntent(() {}),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          VoidCallbackIntent: CallbackAction<VoidCallbackIntent>(
            onInvoke: (VoidCallbackIntent intent) =>
                null, // Do nothing when triggered
          ),
        },
        child: GestureDetector(onLongPress: () {}, child: child),
      ),
    );
  }
}
