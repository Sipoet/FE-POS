import 'package:fe_pos/tool/thousand_separator_formatter.dart';
export 'package:fe_pos/tool/custom_type.dart';
import 'package:flutter/material.dart';

class NumberFormField<T extends num> extends StatefulWidget {
  final T? initialValue;
  final void Function(T? value)? onChanged;
  final void Function(T? value)? onFieldSubmitted;
  final String? Function(T? value)? validator;
  final Widget? label;
  final TextEditingController? controller;
  final bool readOnly;
  final FocusNode? focusNode;
  final String? hintText;
  const NumberFormField(
      {super.key,
      this.initialValue,
      this.onFieldSubmitted,
      this.onChanged,
      this.label,
      this.hintText,
      this.validator,
      this.focusNode,
      this.readOnly = false,
      this.controller});

  @override
  State<NumberFormField<T>> createState() => _NumberFormFieldState<T>();
}

class _NumberFormFieldState<T extends num> extends State<NumberFormField<T>> {
  T? _valueFromInput(String input) {
    input = input.replaceAll(',', '');
    if (T == double) {
      return double.tryParse(input) as T?;
    } else if (T == int) {
      return int.tryParse(input) as T?;
    } else {
      throw 'not support $T';
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enableSuggestions: false,
      controller: widget.controller,
      readOnly: widget.readOnly,
      focusNode: widget.focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: widget.onChanged is Function
          ? (value) {
              final number = _valueFromInput(value);
              widget.onChanged!(number);
            }
          : null,
      onFieldSubmitted: widget.onFieldSubmitted is Function
          ? (value) {
              final number = _valueFromInput(value);
              widget.onFieldSubmitted!(number);
            }
          : null,
      validator: widget.validator is Function
          ? (String? value) {
              final number = _valueFromInput(value ?? '');
              return widget.validator!(number);
            }
          : null,
      inputFormatters: [ThousandSeparatorFormatter()],
      decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(5),
          label: widget.label,
          hintText: widget.hintText,
          border: const OutlineInputBorder()),
      initialValue: widget.initialValue?.toString(),
    );
  }
}

extension NumberFormController on TextEditingController {
  void setValue(value) {
    text = value.toString();
  }
}
