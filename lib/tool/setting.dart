import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Setting extends ChangeNotifier {
  List<String> discountColumns = <String>[];
  List<String> discountColumnOrder = <String>[];
  List<String> salesItemPercentageReportColumns = <String>[];
  List<String> salesItemPercentageReportColumnOrder = <String>[];
  Setting();

  void removeSetting() {
    discountColumns = <String>[];
    discountColumnOrder = <String>[];
    salesItemPercentageReportColumns = <String>[];
    salesItemPercentageReportColumnOrder = <String>[];
    notifyListeners();
  }

  String dateTimeFormat(DateTime date) {
    return DateFormat('dd/MM/y HH:mm', 'id_ID').format(date);
  }

  String moneyFormat(double value) {
    return NumberFormat.currency(locale: "en_US", symbol: "Rp").format(value);
  }

  String numberFormat(number) {
    return NumberFormat(",##0.##", "en_US").format(number);
  }
}
