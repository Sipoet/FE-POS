import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

mixin Datatable {
  // static List keys = [];

  DataCell decorateValue(cell) {
    if (cell == null) {
      return const DataCell(Text('-'));
    } else if (cell is DateTime) {
      String val = _formatDate(cell);
      return DataCell(SelectableText(val));
    } else if (cell is double || cell is int) {
      String val = _formatNumber(cell);
      return DataCell(
          Align(alignment: Alignment.centerRight, child: SelectableText(val)));
    } else {
      return DataCell(SelectableText(cell.toString()));
    }
  }

  static String _formatDate(DateTime cell) {
    var formated = DateFormat('dd/MM/y HH:mm');
    return formated.format(cell.toUtc());
  }

  static String _formatNumber(number) {
    var formated = NumberFormat(",##0.##", "en_US");
    return formated.format(number);
  }
}
