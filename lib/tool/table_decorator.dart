import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/tool/model_route.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:flutter/material.dart';
export 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';
import 'package:pluto_grid/pluto_grid.dart';

extension ComparingTimeOfDay on TimeOfDay {
  int compareTo(TimeOfDay val2) {
    return toString().compareTo(val2.toString());
  }
}

enum TableColumnType {
  number,
  percentage,
  money,
  enums,
  boolean,
  date,
  datetime,
  text;
}

class TableColumn {
  double initX;
  double clientWidth;
  double? excelWidth;
  String name;
  String type;
  Widget Function(PlutoColumnRendererContext rendererContext)? renderBody;
  String humanizeName;
  String? path;
  String? attributeKey;
  bool canSort;
  bool canFilter;
  Map<String, dynamic> inputOptions = {};

  TableColumn(
      {this.initX = 0,
      required this.clientWidth,
      this.excelWidth,
      this.path,
      this.renderBody,
      Map<String, dynamic>? inputOptions,
      this.attributeKey = '',
      this.type = 'string',
      this.canSort = true,
      this.canFilter = true,
      required this.name,
      required this.humanizeName})
      : inputOptions = inputOptions ?? const {};

  bool isNumeric() {
    return ['float', 'decimal', 'int', 'money', 'percentage'].contains(type);
  }
}

mixin TableDecorator<T extends Model> implements TextFormatter {
  Widget _decorateCell(String val, String columnType) {
    switch (columnType) {
      // case 'image':
      // return Image.network('assets/${val}')
      case 'link':
      case 'date':
      case 'datetime':
        return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            val,
            overflow: TextOverflow.ellipsis,
          ),
        );
      case 'money':
      case 'double':
      case 'decimal':
      case 'integer':
        return Align(
            alignment: Alignment.centerRight,
            child: Text(
              val,
              overflow: TextOverflow.ellipsis,
            ));
      default:
        return Align(alignment: Alignment.centerLeft, child: Text(val));
    }
  }

  String _formatData(cell) {
    if (cell == null) {
      return '-';
    }
    switch (cell.runtimeType) {
      case const (Date):
        return dateFormat(cell);
      case const (DateTime):
        return dateTimeLocalFormat(cell);
      case const (TimeDay):
        return timeFormat(cell);
      case const (Money):
        return moneyFormat(cell);
      case const (double):
      case const (int):
        return numberFormat(cell);
      case const (Percentage):
        return cell.format();
      case const (String):
        return cell;
      default:
        try {
          return cell.humanize();
        } catch (error) {
          return cell.toString();
        }
    }
  }

  DataCell decorateValue(jsonData, TableColumn column) {
    final cell = jsonData[column.attributeKey] ?? jsonData[column.name];
    final val = _formatData(cell);
    return DataCell(Tooltip(
      message: val,
      triggerMode: TooltipTriggerMode.longPress,
      child: _decorateCell(val, column.type),
    ));
  }

  List<DataCell> decorateModel(T model,
      {List<TableColumn> columns = const [],
      int index = 0,
      List<Widget> Function(T model, int index)? actionButtons}) {
    var jsonData = model.toMap();
    var rows = columns
        .map<DataCell>((column) => decorateValue(jsonData, column))
        .toList();
    if (actionButtons != null) {
      rows.add(DataCell(Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: actionButtons(model, index),
      )));
    }
    return rows;
  }
}

mixin PlutoTableDecorator {
  final String _formatNumber = '#,###.#';
  final String _locale = 'id_ID';
  late final Server server;
  PlutoColumnType _parseColumnType(TableColumn tableColumn,
      {List<Enum>? listEnumValues}) {
    switch (tableColumn.type) {
      case 'string':
        return PlutoColumnType.text();
      case 'date':
        return PlutoColumnType.date(format: 'dd/MM/yyyy');
      case 'datetime':
        return PlutoColumnType.date(format: 'dd/MM/yyyy HH::mm');
      case 'time':
        return PlutoColumnType.time();
      case 'money':
        return PlutoColumnType.currency(
            locale: _locale,
            // format: _formatNumber,
            symbol: 'Rp',
            decimalDigits: 2);
      case 'model':
        return PlutoColumnTypeModelSelect(
            path: tableColumn.inputOptions['path'],
            modelName: tableColumn.inputOptions['model_name'],
            attributeKey: tableColumn.inputOptions['attribute_key']);
      case 'enum':
        return PlutoColumnType.select(
            listEnumValues ?? tableColumn.inputOptions['enums'] ?? []);
      case 'percentage':
      case 'decimal':
      case 'integer':
      case 'double':
      case 'float':
        return PlutoColumnType.number(locale: _locale, format: _formatNumber);
      case 'boolean':
        return PlutoColumnType.select([true, false]);
      default:
        return PlutoColumnType.text();
    }
  }

  PlutoRow decorateRow(
      {required Model data,
      required List<TableColumn> tableColumns,
      bool isChecked = false}) {
    final rowMap = data.toMap();
    Map<String, PlutoCell> cells = {};
    for (final tableColumn in tableColumns) {
      var value = rowMap[tableColumn.name];
      cells[tableColumn.name] = PlutoCell(value: value);
    }
    return PlutoRow(
        cells: cells, checked: isChecked, type: PlutoRowType.normal());
  }

  void _openModelDetailPage(
      {required PlutoColumnTypeModelSelect columnType,
      required TabManager tabManager,
      required Model value}) {
    final route = ModelRoute();
    tabManager.addTab(
        "Detail ${columnType.modelName}", route.detailPageOf(value));
  }

  static const _labelStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Color.fromRGBO(56, 142, 60, 1));
  static const _footerStyle = TextStyle(fontWeight: FontWeight.bold);

  PlutoColumn decorateColumn(TableColumn tableColumn,
      {List<Enum>? listEnumValues,
      bool showFilter = false,
      required TabManager tabManager,
      bool showCheckboxColumn = false,
      bool isFrozen = false}) {
    final columnType =
        _parseColumnType(tableColumn, listEnumValues: listEnumValues);
    bool showFooter = [
      'money',
      'decimal',
      'integer',
      'float',
      'double',
      'percentage',
    ].contains(tableColumn.type);
    final isCurrency = tableColumn.type == 'money';
    final format = _formatNumber;

    return PlutoColumn(
      readOnly: true,
      enableSorting: tableColumn.canSort,
      enableEditingMode: false,
      textAlign:
          showFooter ? PlutoColumnTextAlign.right : PlutoColumnTextAlign.left,
      title: tableColumn.humanizeName,
      field: tableColumn.name,
      minWidth: 50 < tableColumn.clientWidth ? 50 : tableColumn.clientWidth,
      width: tableColumn.clientWidth,
      type: columnType,
      frozen: isFrozen ? PlutoColumnFrozen.start : PlutoColumnFrozen.none,
      enableRowChecked: showCheckboxColumn,
      enableFilterMenuItem: showFilter,
      renderer: tableColumn.renderBody ??
          (rendererContext) {
            var value = rendererContext.cell.value;
            if (tableColumn.type == 'model' && value is Model) {
              return InkWell(
                onTap: () => _openModelDetailPage(
                  columnType: columnType as PlutoColumnTypeModelSelect,
                  value: value,
                  tabManager: tabManager,
                ),
                child: Text(value.toString()),
              );
            }
            if (value is double) {
              if (tableColumn.type == 'money') {
                value = Money(value).format();
              } else if (tableColumn.type == 'Percentage') {
                value = Percentage(value).format();
              }
              return Align(
                  alignment: Alignment.topRight, child: SelectableText(value));
            }
            return SelectableText(value.toString());
          },
      footerRenderer: showFooter
          ? (rendererContext) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Visibility(
                    visible: tableColumn.type != 'percentage',
                    child: PlutoAggregateColumnFooter(
                      padding: const EdgeInsets.only(top: 5.0),
                      rendererContext: rendererContext,
                      formatAsCurrency: isCurrency,
                      type: PlutoAggregateColumnType.sum,
                      format: format,
                      locale: _locale,
                      alignment: Alignment.topLeft,
                      titleSpanBuilder: (text) {
                        return [
                          const WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Tooltip(
                              message: 'Total Penjumlahan',
                              child: Text(
                                'SUM',
                                style: _labelStyle,
                              ),
                            ),
                          ),
                          const TextSpan(text: ' : '),
                          TextSpan(text: text, style: _footerStyle),
                        ];
                      },
                    ),
                  ),
                  PlutoAggregateColumnFooter(
                    padding: const EdgeInsets.only(top: 5.0),
                    rendererContext: rendererContext,
                    formatAsCurrency: isCurrency,
                    type: PlutoAggregateColumnType.min,
                    format: format,
                    locale: _locale,
                    alignment: Alignment.topLeft,
                    titleSpanBuilder: (text) {
                      return [
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Tooltip(
                            message: 'Minimum',
                            child: Text(
                              'MIN',
                              style: _labelStyle,
                            ),
                          ),
                        ),
                        const TextSpan(text: '  : '),
                        TextSpan(text: text, style: _footerStyle),
                      ];
                    },
                  ),
                  PlutoAggregateColumnFooter(
                    padding: const EdgeInsets.only(top: 5.0),
                    rendererContext: rendererContext,
                    formatAsCurrency: isCurrency,
                    type: PlutoAggregateColumnType.average,
                    format: format,
                    locale: _locale,
                    alignment: Alignment.topLeft,
                    titleSpanBuilder: (text) {
                      return [
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Tooltip(
                            message: 'Rata-rata',
                            child: Text(
                              'AVG',
                              style: _labelStyle,
                            ),
                          ),
                        ),
                        const TextSpan(text: '  : '),
                        TextSpan(text: text, style: _footerStyle),
                      ];
                    },
                  ),
                  PlutoAggregateColumnFooter(
                    padding: const EdgeInsets.only(top: 5.0),
                    rendererContext: rendererContext,
                    formatAsCurrency: isCurrency,
                    type: PlutoAggregateColumnType.max,
                    format: format,
                    locale: _locale,
                    alignment: Alignment.topLeft,
                    titleSpanBuilder: (text) {
                      return [
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Tooltip(
                            message: 'Maksimum',
                            child: Text(
                              'MAX',
                              style: _labelStyle,
                            ),
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
}

class PlutoDeco with PlutoTableDecorator {}

extension TableStateMananger on PlutoGridStateManager {
  PlutoDeco get decorator => PlutoDeco();

  void appendModel(model, List<TableColumn> tableColumns) {
    appendRows(
        [decorator.decorateRow(data: model, tableColumns: tableColumns)]);
    notifyListeners();
  }

  void setModels(models, List<TableColumn> tableColumns) {
    if (rows.isNotEmpty) {
      removeAllRows();
    }
    final rowsTemp = models
        .map<PlutoRow>((model) =>
            decorator.decorateRow(data: model, tableColumns: tableColumns))
        .toList();
    appendRows(rowsTemp);
    notifyListeners();
  }

  void setTableColumns(List<TableColumn> tableColumns,
      {int fixedLeftColumns = 0,
      bool showFilter = false,
      required TabManager tabManager}) {
    removeColumns(columns);
    final newColumns = tableColumns.asMap().entries.map<PlutoColumn>((entry) {
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
    eventManager!.addEvent(PlutoGridChangeColumnSortEvent(
        column: columns.first, oldSort: PlutoColumnSort.none));
  }
}

class PlutoFilterTypeNot implements PlutoFilterType {
  @override
  String get title => 'Not equal';

  @override
  get compare => ({
        required String? base,
        required String? search,
        required PlutoColumn? column,
      }) {
        var keys = search!.split(',').map((e) => e.toLowerCase()).toList();

        return !keys.contains(base!.trim().toLowerCase());
      };

  const PlutoFilterTypeNot();
}

class PlutoColumnTypeModelSelect implements PlutoColumnType {
  @override
  final dynamic defaultValue;

  String get title => 'Select';
  final String modelName;
  final String attributeKey;
  final String path;

  const PlutoColumnTypeModelSelect({
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
      return a.toString().compareTo(b.toString());
    });
  }

  @override
  dynamic makeCompareValue(dynamic v) {
    return v;
  }

  int _compareWithNull(
    dynamic a,
    dynamic b,
    int Function() resolve,
  ) {
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
