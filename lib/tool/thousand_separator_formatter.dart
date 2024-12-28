import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandSeparatorFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###.##');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formattedValue = _formatter
        .format(double.tryParse(newValue.text.replaceAll(',', '')) ?? 0);

    final selectionOffset = newValue.selection.baseOffset +
        (formattedValue.length - newValue.text.length);

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }
}
