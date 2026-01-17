import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/tool/thousand_separator_formatter.dart';
export 'package:fe_pos/tool/custom_type.dart';
import 'package:flutter/material.dart';

class NumberFormField<T extends num> extends StatefulWidget {
  final T? initialValue;
  final void Function(T? value)? onChanged;
  final void Function(T? value)? onSaved;
  final void Function(T? value)? onFieldSubmitted;
  final String? Function(T? value)? validator;
  final Widget? label;
  final TextEditingController? controller;
  final bool readOnly;
  final FocusNode? focusNode;
  final String? hintText;
  const NumberFormField({
    super.key,
    this.initialValue,
    this.onFieldSubmitted,
    this.onChanged,
    this.onSaved,
    this.label,
    this.hintText,
    this.validator,
    this.focusNode,
    this.readOnly = false,
    this.controller,
  });

  @override
  State<NumberFormField<T>> createState() => _NumberFormFieldState<T>();
}

class _NumberFormFieldState<T extends num> extends State<NumberFormField<T>>
    with TextFormatter {
  TextEditingController? _controller;
  String? initialValue;

  T? _valueFromInput(String input) {
    input = input.replaceAll(',', '');
    if (input.isEmpty) {
      return null;
    }
    if (T == double) {
      return double.tryParse(input) as T?;
    } else if (T == int) {
      return int.tryParse(input) as T?;
    } else {
      throw 'not support $T';
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    initialValue = widget.initialValue == null
        ? null
        : numberFormat(widget.initialValue);
    super.initState();
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
      onSaved: widget.onSaved is Function
          ? (value) {
              final number = _valueFromInput(value ?? '');
              widget.onSaved!(number);
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
        border: const OutlineInputBorder(),
      ),
      initialValue: initialValue,
    );
  }
}

extension NumberFormController on TextEditingController {
  void setValue(num value) {
    text = value.toString();
  }
}
