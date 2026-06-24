import 'package:fe_pos/model/account.dart';
import 'package:fe_pos/model/unit_of_measurement.dart';
import 'package:fe_pos/tool/table_decorator.dart';

class Authorizer extends ChangeNotifier with ColumnTypeFinder {
  Map<String, Map<String, TableColumn>> _tableColumns = {};
  Map<String, List<String>> menus = {};
  Authorizer();

  void removeSetting() {
    _tableColumns = {};
    menus = {};
    notifyListeners();
  }

  void setTableColumns(Map<String, dynamic> data) {
    for (final entry in data.entries) {
      _tableColumns[entry.key] = {};
      for (Map row in entry.value['data']) {
        final columnKey = row['id'];
        final attributes = row['attributes'];

        _tableColumns[entry.key]![columnKey] = TableColumn(
          name: columnKey,
          humanizeName: attributes['humanize_name'],
          type: convertToColumnType(attributes['type'].toString(), attributes),
          inputOptions: attributes['input_options'],
          clientWidth:
              double.tryParse(attributes['client_width'].toString()) ?? 175,
          canFilter: attributes['can_filter'] ?? true,
          canSort: attributes['can_sort'] ?? true,
          excelWidth: double.tryParse(attributes['excel_width'].toString()),
        );
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

class DefaultSetting extends ChangeNotifier {
  UnitOfMeasurement? uom;
  Account? stockAccount;
  Account? cogsAccount;
  Account? sellProfitAccount;

  DefaultSetting({
    this.uom,
    this.sellProfitAccount,
    this.cogsAccount,
    this.stockAccount,
  });

  void setDefault(Map<String, dynamic> data) {
    if (data['uom'] != null) {
      uom = UnitOfMeasurementClass().fromJson(data['uom']?['data']);
    }
    if (data['stock_account'] != null) {
      stockAccount = AccountClass().fromJson(data['stock_account']?['data']);
    }
    if (data['cogs_account'] != null) {
      cogsAccount = AccountClass().fromJson(data['cogs_account']?['data']);
    }
    if (data['sell_profit_account'] != null) {
      sellProfitAccount = AccountClass().fromJson(
        data['sell_profit_account']?['data'],
      );
    }
  }
}
