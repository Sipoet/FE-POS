import 'package:fe_pos/tool/setting.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthorizerFormField extends StatefulWidget {
  final String? Function() valueCallback;
  final ChangeNotifier notifier;
  final String tableName;
  final String columnName;
  final Widget Function(TextEditingController controller) childBuilder;
  final Widget? readModeWidget;
  const AuthorizerFormField({
    super.key,
    required this.valueCallback,
    this.readModeWidget,
    required this.columnName,
    required this.tableName,
    required this.notifier,
    required this.childBuilder,
  });

  @override
  State<AuthorizerFormField> createState() => _AuthorizerFormFieldState();
}

class _AuthorizerFormFieldState extends State<AuthorizerFormField> {
  final _controller = TextEditingController();
  @override
  void initState() {
    _controller.text = widget.valueCallback.call() ?? '';
    widget.notifier.addListener(() {
      _controller.text = widget.valueCallback.call() ?? '';
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final setting = context.read<Setting>();
    return Visibility(
      visible: setting.canShow(widget.tableName, widget.columnName),
      replacement: widget.readModeWidget ?? const SizedBox.shrink(),
      child: widget.childBuilder.call(_controller),
    );
  }
}
