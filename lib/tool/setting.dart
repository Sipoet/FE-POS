import 'package:fe_pos/tool/datatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Setting extends ChangeNotifier {
  Map<String, Map<String, TableColumn>> tableColumns = {};
  Map<String, List<String>> menus = {};
  Setting();

  void removeSetting() {
    tableColumns = {};
    menus = {};
    notifyListeners();
  }

  void setTableColumns(Map<String, dynamic> data) {
    for (final key in data.keys.toList()) {
      tableColumns[key] = {};
      for (Map row in data[key]) {
        final columnKey = row['name'];
        tableColumns[key]![columnKey] = TableColumn(
            key: row['name'],
            sortKey: row['sort_key'],
            attributeKey: row['attribute_key'],
            path: row['path'],
            name: row['humanize_name'],
            type: row['type'],
            canFilter: row['can_filter'] ?? true,
            excelWidth: double.tryParse(row['width'].toString()));
      }
    }
  }

  String columnName(String tableName, String columnKey) {
    return tableColumns[tableName]?[columnKey]?.name ?? '';
  }

  List<TableColumn> tableColumn(String key) {
    return tableColumns[key]?.values.toList() ?? [];
  }

  String dateFormat(DateTime date) {
    return DateFormat('dd/MM/y', 'id_ID').format(date);
  }

  String dateTimeFormat(DateTime date) {
    return DateFormat('dd/MM/y HH:mm', 'id_ID').format(date);
  }

  String timeFormat(TimeOfDay time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  String dateTimeLocalFormat(DateTime date) {
    return DateFormat('dd/MM/y HH:mm', 'id_ID').format(date.toLocal());
  }

  String moneyFormat(dynamic value) {
    if (value is Money) {
      return NumberFormat.currency(
              locale: "en_US", symbol: value.symbol, decimalDigits: 1)
          .format(value.value);
    }
    return NumberFormat.currency(
            locale: "en_US", symbol: "Rp", decimalDigits: 1)
        .format(value);
  }

  String numberFormat(number) {
    return NumberFormat(",##0.##", "en_US").format(number);
  }

  bool isAuthorize(String controllerName, String actionName) {
    return menus[controllerName] != null &&
        menus[controllerName]!.contains(actionName);
  }

  bool canShow(String tableName, String columnKey) {
    return tableColumns[tableName]?[columnKey] != null;
  }
}
