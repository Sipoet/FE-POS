import 'package:flutter/material.dart';

class TransactionReportController extends ChangeNotifier {
  DateTimeRange range;
  TransactionReportController(this.range);
  void changeDate(DateTimeRange newRange) {
    range = newRange;
    notifyListeners();
  }
}
