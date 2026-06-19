import 'package:fe_pos/tool/custom_type.dart';
import 'package:fe_pos/tool/text_formatter.dart';
export 'package:fe_pos/tool/custom_type.dart';
import 'package:flutter/material.dart';

class MoneyFormField extends StatefulWidget {
  final Money? initialValue;
  final FormCallback<Money>? onChanged;
  final FormCallback<Money>? onSaved;
  final ChangeNotifier? notifier;
  final FormCallback<Money>? onFieldSubmitted;
  final String? Function(Money? value)? validator;
  final Widget? label;
  final ValueCallBack<Money>? valueCallback;
  final TextEditingController? controller;
  final bool readOnly;
  final bool? enabled;
  final FocusNode? focusNode;
  final bool? isDense;
  const MoneyFormField({
    super.key,
    this.initialValue,
    this.onChanged,
    this.label,
    this.validator,
    this.notifier,
    this.isDense,
    this.valueCallback,
    this.focusNode,
    this.onFieldSubmitted,
    this.onSaved,
    this.readOnly = false,
    this.enabled,
    this.controller,
  });

  @override
  State<MoneyFormField> createState() => _MoneyFormFieldState();
}

class _MoneyFormFieldState extends State<MoneyFormField> with TextFormatter {
  final _controller = TextEditingController();
  Money? _valueFromInput(String input) {
    input = input.replaceAll(',', '');
    return Money.tryParse(input);
  }

  @override
  void initState() {
    _controller.text =
        widget.initialValue?.value.format() ?? widget.controller?.text ?? '';

    widget.controller?.addListener(controllerListener);
    widget.notifier?.addListener(notifierListener);
    super.initState();
  }

  void controllerListener() {
    if (mounted) {
      _controller.text = widget.controller!.text;
    } else {
      widget.controller!.removeListener(controllerListener);
    }
  }

  void notifierListener() {
    if (mounted) {
      setState(() {
        Money? value = widget.valueCallback?.call();
        _controller.text = value == null ? '' : numberFormat(value.value);
      });
    } else {
      widget.notifier!.removeListener(notifierListener);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enableSuggestions: false,
      controller: _controller,
      readOnly: widget.readOnly,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: widget.onChanged is Function
          ? (value) {
              final money = _valueFromInput(value);
              widget.onChanged!(money);
            }
          : null,
      onSaved: widget.onSaved is Function
          ? (value) {
              final money = _valueFromInput(value ?? '');
              widget.onSaved!(money);
            }
          : null,
      onFieldSubmitted: widget.onFieldSubmitted is Function
          ? (value) {
              final money = _valueFromInput(value);
              widget.onFieldSubmitted!(money);
            }
          : null,
      validator: widget.validator is Function
          ? (String? value) {
              final money = _valueFromInput(value ?? '');
              return widget.validator!(money);
            }
          : null,
      inputFormatters: [
        CustomNumberInputFormatter(
          formatType: .amount,
          separator: ',',
          decimalSeparator: '.',
        ),
      ],
      decoration: InputDecoration(
        label: widget.label,
        isDense: widget.isDense,
        contentPadding: const EdgeInsets.all(5),
        prefix: const Text(
          'Rp ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
