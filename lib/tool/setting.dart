import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fe_pos/tool/custom_type.dart';

class Setting extends ChangeNotifier {
  Map tableColumns = {};
  Setting();

  void removeSetting() {
    tableColumns = {};
    notifyListeners();
  }

  List<String> columnOrder(key) {
    return tableColumns[key].keys.map<String>((e) => e.toString()).toList();
  }

  List<String> columnNames(key) {
    return tableColumns[key].values.map<String>((e) => e.toString()).toList();
  }

  String dateTimeFormat(DateTime date) {
    return DateFormat('dd/MM/y HH:mm', 'id_ID').format(date);
  }

  String moneyFormat(var value) {
    if (value is Money) {
      return NumberFormat.currency(locale: "en_US", symbol: value.symbol)
          .format(value.value);
    }
    return NumberFormat.currency(locale: "en_US", symbol: "Rp").format(value);
  }

  String numberFormat(number) {
    return NumberFormat(",##0.##", "en_US").format(number);
  }
}
