import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/tool/table_column.dart';
export 'package:fe_pos/tool/table_column.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:intl/intl.dart';
import 'package:fe_pos/model/model.dart';
export 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';
import 'package:fe_pos/model/server.dart';
import 'package:trina_grid/trina_grid.dart';
import 'package:flutter/material.dart';

const modelKey = 'model';
const formatNumber = '#,###.#';
const locale = 'id_ID';
mixin TrinaTableDecorator<T extends Model>
    implements PlatformChecker, TextFormatter {
  late final TabManager tabManager;
  final String _formatNumber = '#,###.#';
  final String _locale = 'id_ID';
  late final Server server;
  TrinaColumnType _parseColumnType(
    TableColumn tableColumn, {
    List<Enum>? listEnumValues,
  }) {
    return tableColumn.type.trinaColumnType;
  }

  TrinaRow decorateRow({
    required Model model,
    required List<TrinaColumn> tableColumns,
    bool isChecked = false,
  }) {
    final rowMap = model.asMap();
    Map<String, TrinaCell> cells = {};
    for (final tableColumn in tableColumns) {
      cells[tableColumn.field] = tableColumn.formatter == null
          ? TrinaCell(value: rowMap[tableColumn.field])
          : TrinaCell(value: tableColumn.formatter!(model));
    }
    cells['id'] = TrinaCell(value: model.id);
    cells[modelKey] = TrinaCell(value: model, key: ObjectKey(model));
    return TrinaRow(
      cells: cells,
      checked: isChecked,
      type: TrinaRowType.normal(),
    );
  }

  static const _labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Color.fromRGBO(56, 142, 60, 1),
  );
  static const _footerStyle = TextStyle(fontWeight: FontWeight.bold);

  TrinaColumn decorateColumn(
    TableColumn tableColumn, {
    List<Enum>? listEnumValues,
    bool showFilter = false,
    required TabManager tabManager,
    bool showCheckboxColumn = false,
    bool isFrozen = false,
  }) {
    final columnType = _parseColumnType(
      tableColumn,
      listEnumValues: listEnumValues,
    );
    bool showFooter = tableColumn.isNumeric();
    final format = _formatNumber;
    final renderer =
        tableColumn.renderBody ??
        (TrinaColumnRendererContext rendererContext) =>
            defaultRenderBody(rendererContext, tableColumn, tabManager);

    return TrinaColumn(
      readOnly: true,
      enableSorting: tableColumn.canSort,
      enableEditingMode: false,
      titleTextAlign: showFooter
          ? TrinaColumnTextAlign.right
          : TrinaColumnTextAlign.center,
      textAlign: showFooter
          ? TrinaColumnTextAlign.right
          : TrinaColumnTextAlign.left,
      title: tableColumn.humanizeName,
      field: tableColumn.name,
      minWidth: 50 < tableColumn.clientWidth ? 50 : tableColumn.clientWidth,
      width: tableColumn.clientWidth,
      type: columnType,
      frozen: isFrozen ? TrinaColumnFrozen.start : tableColumn.frozen,
      enableRowChecked: showCheckboxColumn,
      enableFilterMenuItem: showFilter,
      enableContextMenu: tableColumn.type is! ActionTableColumnType,
      renderer: renderer,
      footerRenderer: showFooter
          ? (rendererContext) {
              return ListView(
                children: [
                  Offstage(
                    offstage: tableColumn.type is PercentageTableColumnType,
                    child: TrinaAggregateColumnFooter(
                      iterateRowType:
                          TrinaAggregateColumnIterateRowType.filtered,
                      padding: const EdgeInsets.only(top: 5.0),
                      rendererContext: rendererContext,
                      type: TrinaAggregateColumnType.sum,
                      numberFormat: NumberFormat(format, _locale),
                      alignment: Alignment.topLeft,
                      titleSpanBuilder: (text) {
                        return [
                          const WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Tooltip(
                              message: 'Total Penjumlahan',
                              child: Text('TOTAL', style: _labelStyle),
                            ),
                          ),
                          const TextSpan(text: ' : '),
                          TextSpan(text: text, style: _footerStyle),
                        ];
                      },
                    ),
                  ),
                  TrinaAggregateColumnFooter(
                    iterateRowType: TrinaAggregateColumnIterateRowType.filtered,
                    padding: const EdgeInsets.only(top: 5.0),
                    rendererContext: rendererContext,
                    numberFormat: NumberFormat(format, _locale),
                    type: TrinaAggregateColumnType.min,
                    alignment: Alignment.topLeft,
                    titleSpanBuilder: (text) {
                      return [
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Tooltip(
                            message: 'Minimum',
                            child: Text('MIN', style: _labelStyle),
                          ),
                        ),
                        const TextSpan(text: '  : '),
                        TextSpan(text: text, style: _footerStyle),
                      ];
                    },
                  ),
                  TrinaAggregateColumnFooter(
                    iterateRowType: TrinaAggregateColumnIterateRowType.filtered,
                    padding: const EdgeInsets.only(top: 5.0),
                    rendererContext: rendererContext,
                    numberFormat: NumberFormat(format, _locale),
                    type: TrinaAggregateColumnType.average,
                    alignment: Alignment.topLeft,
                    titleSpanBuilder: (text) {
                      return [
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Tooltip(
                            message: 'Rata-rata',
                            child: Text('RATA2', style: _labelStyle),
                          ),
                        ),
                        const TextSpan(text: '  : '),
                        TextSpan(text: text, style: _footerStyle),
                      ];
                    },
                  ),
                  TrinaAggregateColumnFooter(
                    iterateRowType: TrinaAggregateColumnIterateRowType.filtered,
                    padding: const EdgeInsets.only(top: 5.0),
                    rendererContext: rendererContext,
                    numberFormat: NumberFormat(format, _locale),
                    type: TrinaAggregateColumnType.max,
                    alignment: Alignment.topLeft,
                    titleSpanBuilder: (text) {
                      return [
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Tooltip(
                            message: 'Maksimum',
                            child: Text('MAX', style: _labelStyle),
                          ),
                        ),
                        const TextSpan(text: ' : '),
                        TextSpan(text: text, style: _footerStyle),
                      ];
                    },
                  ),
                ],
              );
            }
          : null,
    );
  }

  Widget defaultRenderBody(
    TrinaColumnRendererContext rendererContext,
    TableColumn tableColumn,
    TabManager? tabManager,
  ) {
    Map model = rendererContext.row.modelOf<T>().asMap();
    var value = model[tableColumn.name];
    if (tableColumn.getValue != null) {
      value = tableColumn.getValue!(rendererContext.row.modelOf<T>());
    }
    if (value == null) {
      return SizedBox();
    }
    if (value is String && tableColumn.type is ModelTableColumnType) {
      return Text(value);
    }
    return tableColumn.type.renderCell(
      value: tableColumn.type.convert(value),
      column: tableColumn,
      tabManager: tabManager,
    );
  }
}

class TrinaDeco with TrinaTableDecorator, PlatformChecker, TextFormatter {}

extension TableStateMananger on TrinaGridStateManager {
  TrinaDeco get decorator => TrinaDeco();

  T? modelFromCheckEvent<T extends Model>(TrinaGridOnRowCheckedEvent event) =>
      event.row?.cells[modelKey]?.value as T;

  void appendModel(model) {
    appendRows([decorator.decorateRow(model: model, tableColumns: columns)]);
    notifyListeners();
  }

  void setModels(Iterable models) {
    if (rows.isNotEmpty) {
      removeAllRows();
    }
    final rowsTemp = models
        .map<TrinaRow>(
          (model) => decorator.decorateRow(model: model, tableColumns: columns),
        )
        .toList();
    appendRows(rowsTemp);
    notifyListeners();
  }

  void setTableColumns(
    List<TableColumn> tableColumns, {
    int fixedLeftColumns = 0,
    bool showFilter = false,
    required TabManager tabManager,
  }) {
    removeColumns(columns);
    final newColumns = tableColumns.asMap().entries.map<TrinaColumn>((entry) {
      int index = entry.key;
      TableColumn tableColumn = entry.value;
      return decorator.decorateColumn(
        tableColumn,
        tabManager: tabManager,
        showFilter: showFilter,
        isFrozen: index < fixedLeftColumns,
      );
    }).toList();
    insertColumns(0, newColumns);
  }

  void refreshTable() {
    eventManager!.addEvent(
      TrinaGridChangeColumnSortEvent(
        column: columns.first,
        oldSort: TrinaColumnSort.none,
      ),
    );
  }
}

class TrinaFilterTypeNot implements TrinaFilterType {
  @override
  String get title => 'Not equal';

  @override
  get compare =>
      ({
        required String? base,
        required String? search,
        required TrinaColumn? column,
      }) {
        var keys = search!.split(',').map((e) => e.toLowerCase()).toList();

        return !keys.contains(base!.trim().toLowerCase());
      };

  const TrinaFilterTypeNot();
}

class TrinaColumnTypeModelSelect implements TrinaColumnType {
  @override
  final dynamic defaultValue;

  String get title => 'Select';
  final String modelName;
  final String attributeKey;
  final String path;

  @override
  (bool, dynamic) filteredValue({newValue, oldValue}) {
    return (newValue == oldValue, newValue);
  }

  const TrinaColumnTypeModelSelect({
    this.defaultValue,
    required this.modelName,
    required this.attributeKey,
    required this.path,
  });

  @override
  bool isValid(dynamic value) => value is Model;

  @override
  int compare(dynamic a, dynamic b) {
    return _compareWithNull(a, b, () {
      return a.modelValue.compareTo(b.modelValue);
    });
  }

  @override
  dynamic makeCompareValue(dynamic v) {
    return v;
  }

  int _compareWithNull(dynamic a, dynamic b, int Function() resolve) {
    if (a == null || b == null) {
      return a == b
          ? 0
          : a == null
          ? -1
          : 1;
    }

    return resolve();
  }
}

class TrinaColumnTypePercentage2 implements TrinaColumnType {
  @override
  final Percentage? defaultValue;

  const TrinaColumnTypePercentage2({this.defaultValue});

  @override
  (bool, dynamic) filteredValue({newValue, oldValue}) {
    return (newValue == oldValue, newValue);
  }

  @override
  int compare(dynamic a, dynamic b) {
    return _compareWithNull(a, b, () {
      return a.compareTo(b);
    });
  }

  @override
  dynamic makeCompareValue(dynamic v) {
    if (v is Percentage) {
      return v.value;
    } else if (v is String) {
      return double.tryParse(v);
    } else {
      return v;
    }
  }

  @override
  bool isValid(dynamic value) => value is Percentage;

  int _compareWithNull(dynamic a, dynamic b, int Function() resolve) {
    if (a == null || b == null) {
      return a == b
          ? 0
          : a == null
          ? -1
          : 1;
    }

    return resolve();
  }
}

class DataTableResponse<T extends Model> {
  int totalPage;
  List<T> models;
  DataTableResponse({this.totalPage = 0, this.models = const []});

  factory DataTableResponse.empty() {
    return DataTableResponse<T>(totalPage: 1, models: []);
  }
}

extension TrinaRowExt on TrinaRow {
  T modelOf<T extends Model>() {
    return cells[modelKey]?.value as T;
  }
}
