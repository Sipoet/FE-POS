import 'package:fe_pos/tool/custom_type.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/tool/thousand_separator_formatter.dart';
export 'package:fe_pos/tool/custom_type.dart';
import 'package:flutter/material.dart';

class MoneyFormField extends StatefulWidget {
  final Money? initialValue;
  final void Function(Money? value)? onChanged;
  final void Function(Money? value)? onFieldSubmitted;
  final String? Function(Money? value)? validator;
  final Widget? label;
  final TextEditingController? controller;
  final bool readOnly;
  final bool? enabled;
  final FocusNode? focusNode;
  const MoneyFormField({
    super.key,
    this.initialValue,
    this.onChanged,
    this.label,
    this.validator,
    this.focusNode,
    this.onFieldSubmitted,
    this.readOnly = false,
    this.enabled,
    this.controller,
  });

  @override
  State<MoneyFormField> createState() => _MoneyFormFieldState();
}

class _MoneyFormFieldState extends State<MoneyFormField> with TextFormatter {
  final controller = TextEditingController();

  Money? _valueFromInput(String input) {
    input = input.replaceAll(',', '');
    return Money.tryParse(input);
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.initialValue == null
        ? null
        : numberFormat(widget.initialValue?.value);
    return TextFormField(
      enableSuggestions: false,
      controller: widget.controller,
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
      inputFormatters: [ThousandSeparatorFormatter()],
      decoration: InputDecoration(
          label: widget.label,
          contentPadding: const EdgeInsets.all(5),
          prefix: const Text(
            'Rp ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          border: const OutlineInputBorder()),
      initialValue: value,
    );
  }
}
