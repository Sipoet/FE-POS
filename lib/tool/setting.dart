import 'package:fe_pos/tool/datatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Setting extends ChangeNotifier {
  Map<String, List<TableColumn>> tableColumns = {};
  Map<String, List<String>> menus = {};
  Setting();

  void removeSetting() {
    tableColumns = {};
    menus = {};
    notifyListeners();
  }

  void setTableColumns(Map<String, dynamic> data) {
    for (final key in data.keys.toList()) {
      tableColumns[key] = data[key]!
          .map<TableColumn>((row) => TableColumn(
              key: row['name'],
              name: row['humanize_name'],
              type: row['type'],
              excelWidth: double.tryParse(row['width'].toString())))
          .toList();
    }
  }

  String columnName(String tableName, String columnKey) {
    return tableColumn(tableName)
        .firstWhere((tableColumn) => tableColumn.key == columnKey)
        .name;
  }

  List<TableColumn> tableColumn(String key) {
    return tableColumns[key] ?? [];
  }

  String dateFormat(DateTime date) {
    return DateFormat('dd/MM/y', 'id_ID').format(date);
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

  bool isAuthorize(String controllerName, String actionName) {
    return menus[controllerName] != null &&
        menus[controllerName]!.contains(actionName);
  }
}
