import 'package:fe_pos/tool/table_decorator.dart';
import 'package:flutter/material.dart';

class Setting extends ChangeNotifier {
  Map<String, Map<String, TableColumn>> _tableColumns = {};
  Map<String, List<String>> menus = {};
  Setting();

  void removeSetting() {
    _tableColumns = {};
    menus = {};
    notifyListeners();
  }

  void setTableColumns(Map<String, dynamic> data) {
    for (final key in data.keys.toList()) {
      _tableColumns[key] = {};
      for (Map row in data[key]) {
        final columnKey = row['name'];
        _tableColumns[key]![columnKey] = TableColumn(
            name: row['name'],
            attributeKey: row['attribute_key'],
            path: row['path'],
            humanizeName: row['humanize_name'],
            type: row['type'],
            clientWidth: double.tryParse(row['client_width'].toString()) ?? 175,
            canFilter: row['can_filter'] ?? true,
            canSort: row['can_sort'] ?? true,
            excelWidth: double.tryParse(row['excel_width'].toString()));
      }
    }
  }

  String columnName(String tableName, String columnKey) {
    return _tableColumns[tableName]?[columnKey]?.name ?? '';
  }

  List<TableColumn> tableColumn(String key) {
    return _tableColumns[key]?.values.toList() ?? [];
  }

  bool isAuthorize(String controllerName, String actionName) {
    return menus[controllerName] != null &&
        menus[controllerName]!.contains(actionName);
  }

  bool canShow(String tableName, String columnKey) {
    return _tableColumns[tableName]?[columnKey] != null;
  }
}
