import 'package:flutter/material.dart' show TimeOfDay;
import 'package:intl/intl.dart';
import 'package:fe_pos/tool/custom_type.dart';

mixin TextFormatter {
  String timeFormat(TimeOfDay data) {
    return data.format24Hour();
  }

  String dateFormat(DateTime date) {
    return DateFormat('dd/MM/y', 'id_ID').format(date);
  }

  String moneyFormat(dynamic value) {
    if (value is Money) {
      return NumberFormat.currency(
              locale: "id_ID", symbol: value.symbol, decimalDigits: 1)
          .format(value.value);
    }
    return NumberFormat.currency(
            locale: "id_ID", symbol: "Rp", decimalDigits: 1)
        .format(value);
  }

  String dateTimeFormat(DateTime date) {
    return DateFormat('dd/MM/y HH:mm', 'id_ID').format(date);
  }

  String dateTimeLocalFormat(DateTime date) {
    return DateFormat('dd/MM/y HH:mm', 'id_ID').format(date.toLocal());
  }

  String numberFormat(number) {
    return NumberFormat(",##0.##", "en_US").format(number);
  }
}
