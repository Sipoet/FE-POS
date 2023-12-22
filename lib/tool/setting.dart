import 'package:flutter/material.dart';

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
}
