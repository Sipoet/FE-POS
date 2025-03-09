import 'package:fe_pos/tool/custom_type.dart';
import 'package:fe_pos/tool/thousand_separator_formatter.dart';
export 'package:fe_pos/tool/custom_type.dart';
import 'package:flutter/material.dart';

class PercentageFormField extends StatefulWidget {
  final Percentage? initialValue;
  final void Function(Percentage? value)? onChanged;
  final void Function(Percentage? value)? onSaved;
  final void Function(Percentage? value)? onFieldSubmitted;
  final String? Function(Percentage? value)? validator;
  final Widget? label;
  final TextEditingController? controller;
  final bool readOnly;
  final FocusNode? focusNode;
  const PercentageFormField(
      {super.key,
      this.initialValue,
      this.onChanged,
      this.label,
      this.onSaved,
      this.validator,
      this.focusNode,
      this.onFieldSubmitted,
      this.readOnly = false,
      this.controller});

  @override
  State<PercentageFormField> createState() => _PercentageFormFieldState();
}

class _PercentageFormFieldState extends State<PercentageFormField> {
  final controller = TextEditingController();

  Percentage? _valueFromInput(String input) {
    final percentValue = double.tryParse(input);
    if (percentValue == null) {
      return null;
    }
    return Percentage(percentValue / 100);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enableSuggestions: false,
      controller: widget.controller,
      readOnly: widget.readOnly,
      focusNode: widget.focusNode,
      onSaved: widget.onSaved is Function
          ? (value) {
              final percent = _valueFromInput(value ?? '');
              widget.onSaved!(percent);
            }
          : null,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: widget.onChanged is Function
          ? (value) {
              final percent = _valueFromInput(value);
              widget.onChanged!(percent);
            }
          : null,
      onFieldSubmitted: widget.onFieldSubmitted is Function
          ? (value) {
              final percent = _valueFromInput(value);
              widget.onFieldSubmitted!(percent);
            }
          : null,
      validator: widget.validator is Function
          ? (String? value) {
              final percent = _valueFromInput(value ?? '');
              return widget.validator!(percent);
            }
          : null,
      inputFormatters: [ThousandSeparatorFormatter()],
      decoration: InputDecoration(
          label: widget.label,
          contentPadding: const EdgeInsets.all(5),
          suffixIcon: const Icon(Icons.percent),
          border: const OutlineInputBorder()),
      initialValue: widget.initialValue?.toString(),
    );
  }
}
