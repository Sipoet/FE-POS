import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fe_pos/tool/custom_type.dart';

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
