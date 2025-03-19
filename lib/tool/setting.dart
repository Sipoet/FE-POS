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
      for (Map row in data[key]['data']) {
        final columnKey = row['id'];
        final attributes = row['attributes'];
        _tableColumns[key]![columnKey] = TableColumn(
            name: attributes['name'],
            humanizeName: attributes['humanize_name'],
            type: attributes['type'],
            inputOptions: attributes['input_options'],
            clientWidth:
                double.tryParse(attributes['client_width'].toString()) ?? 175,
            canFilter: attributes['can_filter'] ?? true,
            canSort: attributes['can_sort'] ?? true,
            excelWidth: double.tryParse(attributes['excel_width'].toString()));
      }
    }
  }

  String columnName(String tableName, String columnKey) {
    return _tableColumns[tableName]?[columnKey]?.humanizeName ?? columnKey;
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
