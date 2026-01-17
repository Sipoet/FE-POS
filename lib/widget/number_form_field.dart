import 'package:fe_pos/tool/custom_type.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/tool/thousand_separator_formatter.dart';
export 'package:fe_pos/tool/custom_type.dart';
import 'package:flutter/material.dart';

abstract class NumType<T> {
  T? convert(String value);

  InputDecoration decorateInput({Widget? label, String? hintText});
  String inputFormat(T value);
}

class DoubleType with TextFormatter implements NumType<double> {
  @override
  double? convert(String value) => double.tryParse(value);
  @override
  InputDecoration decorateInput({Widget? label, String? hintText}) =>
      InputDecoration(
        contentPadding: const EdgeInsets.all(5),
        label: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
      );
  @override
  String inputFormat(double value) => numberFormat(value);
}

class IntegerType with TextFormatter implements NumType<int> {
  @override
  int? convert(String value) => int.tryParse(value);
  @override
  InputDecoration decorateInput({Widget? label, String? hintText}) =>
      InputDecoration(
        contentPadding: const EdgeInsets.all(5),
        label: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
      );
  @override
  String inputFormat(int value) => numberFormat(value);
}

class MoneyType with TextFormatter implements NumType<Money> {
  @override
  Money? convert(String value) => Money.tryParse(value);
  @override
  InputDecoration decorateInput({Widget? label, String? hintText}) =>
      InputDecoration(
        label: label,
        contentPadding: const EdgeInsets.all(5),
        prefix: const Text(
          'Rp ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        hintText: hintText,
        border: const OutlineInputBorder(),
      );
  @override
  String inputFormat(Money value) => numberFormat(value.value);
}

class PercentageType with TextFormatter implements NumType<Percentage> {
  @override
  Percentage? convert(String value) => Percentage.inputParse(value);
  @override
  InputDecoration decorateInput({Widget? label, String? hintText}) =>
      InputDecoration(
        label: label,
        contentPadding: const EdgeInsets.all(5),
        suffixIcon: const Icon(Icons.percent),
        border: const OutlineInputBorder(),
      );
  @override
  String inputFormat(Percentage value) => numberFormat(value.value * 100);
}

class NumberFormField<T> extends StatefulWidget {
  final T? initialValue;
  final void Function(T? value)? onChanged;
  final void Function(T? value)? onSaved;
  final void Function(T? value)? onFieldSubmitted;
  final String? Function(T? value)? validator;
  final NumType<T>? numType;
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
    this.numType,
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

class _NumberFormFieldState<T> extends State<NumberFormField<T>>
    with TextFormatter {
  String? initialValue;
  late final NumType<T> numType;

  T? _valueFromInput(String input) {
    input = input.replaceAll(',', '');
    if (input.isEmpty) {
      return null;
    }
    return numType.convert(input);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    if (widget.numType != null) {
      numType = widget.numType!;
    } else {
      numType = getNumTypeBasedType() as NumType<T>;
    }

    initialValue = widget.initialValue == null
        ? null
        : numberFormat(widget.initialValue);
    super.initState();
  }

  NumType getNumTypeBasedType() {
    if (T == double) {
      return DoubleType();
    } else if (T == int) {
      return IntegerType();
    } else if (T == Money) {
      return MoneyType();
    } else if (T == Percentage) {
      return PercentageType();
    } else {
      return DoubleType();
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
      decoration: numType.decorateInput(
        label: widget.label,
        hintText: widget.hintText,
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
