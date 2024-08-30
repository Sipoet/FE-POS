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
            key: row['name'],
            sortKey: row['sort_key'],
            attributeKey: row['attribute_key'],
            path: row['path'],
            name: row['humanize_name'],
            type: row['type'],
            width: row['pixel_width'] ?? 175,
            canFilter: row['can_filter'] ?? true,
            excelWidth: double.tryParse(row['width'].toString()));
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
