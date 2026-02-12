import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fe_pos/tool/custom_type.dart';

mixin TextFormatter {
  String timeFormat(TimeOfDay data) {
    return data.format24Hour();
  }

  static const labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );
  String dateFormat(DateTime date) {
    return DateFormat('dd/MM/y', 'id_ID').format(date);
  }

  String moneyFormat(dynamic value, {int decimalDigits = 1}) {
    if (value is Money) {
      return NumberFormat.currency(
        locale: "id_ID",
        symbol: value.symbol,
        decimalDigits: decimalDigits,
      ).format(value.value);
    }
    return NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp",
      decimalDigits: decimalDigits,
    ).format(value);
  }

  String dateTimeFormat(DateTime date) {
    return DateFormat('dd/MM/y HH:mm', 'id_ID').format(date);
  }

  String dateTimeLocalFormat(DateTime date) {
    return DateFormat('dd/MM/y HH:mm', 'id_ID').format(date.toLocal());
  }

  String numberFormat(number) {
    if (number is! num) {
      return '';
    }
    return NumberFormat(",##0.##", "en_US").format(number);
  }

  String compactNumberFormat(number) {
    return NumberFormat.compact().format(number);
  }

  String percentageFormat(num value, {String locale = 'id_ID', int digit = 1}) {
    var numberFormatter = NumberFormat.decimalPercentPattern(
      locale: locale,
      decimalDigits: digit,
    );
    return numberFormatter.format(value);
  }
}
