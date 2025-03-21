import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/tool/model_route.dart';
import 'package:fe_pos/tool/platform_checker.dart';
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
  image,
  url,
  datetime,
  model,
  timeOnly,
  action,
  text;

  bool isText() => this == text;
  bool isNumber() => this == number;
  bool isPercentage() => this == percentage;
  bool isMoney() => this == money;
  bool isEnums() => this == enums;
  bool isBool() => this == boolean;
  bool isDate() => this == date;
  bool isDatetime() => this == datetime;
  bool isModel() => this == model;
  bool isTimeOnly() => this == timeOnly;
  bool isAction() => this == action;

  static TableColumnType fromString(String value) {
    switch (value) {
      case 'decimal':
      case 'float':
      case 'integer':
      case 'double':
      case 'number':
        return number;
      case 'percentage':
        return percentage;
      case 'money':
        return money;
      case 'enum':
        return enums;
      case 'boolean':
        return boolean;
      case 'date':
        return date;
      case 'datetime':
        return datetime;
      case 'time':
        return timeOnly;
      case 'string':
      case 'text':
        return text;
      case 'link':
      case 'model':
        return model;
      case 'image':
        return image;
      default:
        throw 'invalid column type $value';
    }
  }
}

class TableColumn {
  double initX;
  double clientWidth;
  double? excelWidth;
  String name;
  TableColumnType type;
  Widget Function(PlutoColumnRendererContext rendererContext)? renderBody;
  String humanizeName;
  bool canSort;
  bool canFilter;
  PlutoColumnFrozen frozen;
  Map<String, dynamic> inputOptions = {};

  TableColumn(
      {this.initX = 0,
      required this.clientWidth,
      this.excelWidth,
      this.renderBody,
      this.frozen = PlutoColumnFrozen.none,
      Map<String, dynamic>? inputOptions,
      this.type = TableColumnType.text,
      this.canSort = true,
      bool? canFilter,
      required this.name,
      required this.humanizeName})
      : inputOptions = inputOptions ?? const {},
        canFilter = canFilter ?? !type.isAction();

  bool isNumeric() {
    return type.isNumber() || type.isMoney() || type.isPercentage();
  }
}

mixin TableDecorator<T extends Model>
    implements TextFormatter, PlatformChecker {
  late final TabManager tabManager;

  void _openModelDetailPage(
      {required TableColumn tableColumn, required Model value}) {
    final route = ModelRoute();
    if (isDesktop()) {
      tabManager.setSafeAreaContent(
          "${tableColumn.humanizeName} ${value.id}", route.detailPageOf(value));
    } else {
      tabManager.addTab(
          "${tableColumn.humanizeName} ${value.id}", route.detailPageOf(value));
    }
  }

  Widget _decorateCell(String val, TableColumnType columnType) {
    switch (columnType) {
      // case 'image':
      // return Image.network('assets/${val}')
      case TableColumnType.text:
      case TableColumnType.date:
      case TableColumnType.datetime:
        return Align(
          alignment: Alignment.topLeft,
          child: Text(
            val,
            overflow: TextOverflow.ellipsis,
          ),
        );
      case TableColumnType.money:
      case TableColumnType.number:
        return Align(
            alignment: Alignment.topRight,
            child: Text(
              val,
              overflow: TextOverflow.ellipsis,
            ));
      default:
        return Align(alignment: Alignment.topLeft, child: Text(val));
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

  DataCell decorateValue(T model, TableColumn column) {
    final jsonData = model.toMap();
    final cell = jsonData[column.name];
    final val = _formatData(cell);
    if (column.type.isModel()) {
      return DataCell(
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              val,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          onTap: () => _openModelDetailPage(
              tableColumn: column,
              value: jsonData[column.inputOptions['model_name']]));
    }
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
    var rows = columns
        .map<DataCell>((column) => decorateValue(model, column))
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

mixin PlutoTableDecorator implements PlatformChecker, TextFormatter {
  late final TabManager tabManager;
  final String _formatNumber = '#,###.#';
  final String _locale = 'id_ID';
  late final Server server;
  PlutoColumnType _parseColumnType(TableColumn tableColumn,
      {List<Enum>? listEnumValues}) {
    switch (tableColumn.type) {
      case TableColumnType.text:
        return PlutoColumnType.text();
      case TableColumnType.date:
        return PlutoColumnType.date(format: 'dd/MM/yyyy');
      case TableColumnType.datetime:
        return PlutoColumnType.date(format: 'dd/MM/yyyy HH::mm');
      case TableColumnType.timeOnly:
        return PlutoColumnType.time();
      case TableColumnType.money:
        return PlutoColumnType.currency(
            locale: _locale,
            // format: _formatNumber,
            symbol: 'Rp',
            decimalDigits: 2);
      case TableColumnType.model:
        return PlutoColumnTypeModelSelect(
            path: tableColumn.inputOptions['path'],
            modelName: tableColumn.inputOptions['model_name'],
            attributeKey: tableColumn.inputOptions['attribute_key']);
      case TableColumnType.enums:
        return PlutoColumnType.select(
            listEnumValues ?? tableColumn.inputOptions['enums'] ?? []);
      case TableColumnType.percentage:
      case TableColumnType.number:
        return PlutoColumnType.number(locale: _locale, format: _formatNumber);
      case TableColumnType.boolean:
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
      if (value is Percentage || value is Money) {
        value = value.value;
      }
      cells[tableColumn.name] = PlutoCell(value: value);
    }
    return PlutoRow(
        cells: cells, checked: isChecked, type: PlutoRowType.normal());
  }

  void _openModelDetailPage(
      {required TableColumn tableColumn, required Model value}) {
    final route = ModelRoute();
    if (isDesktop()) {
      tabManager.setSafeAreaContent(
          "${tableColumn.humanizeName} ${value.id}", route.detailPageOf(value));
    } else {
      tabManager.addTab(
          "${tableColumn.humanizeName} ${value.id}", route.detailPageOf(value));
    }
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
    bool showFooter = tableColumn.isNumeric();
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
      frozen: isFrozen ? PlutoColumnFrozen.start : tableColumn.frozen,
      enableRowChecked: showCheckboxColumn,
      enableFilterMenuItem: showFilter,
      enableContextMenu: !tableColumn.type.isAction(),
      renderer: tableColumn.renderBody ??
          (rendererContext) {
            var value = rendererContext.cell.value ?? '';
            if (tableColumn.type.isModel() && value is Model) {
              return InkWell(
                onTap: () => _openModelDetailPage(
                  tableColumn: tableColumn,
                  value: value,
                ),
                child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(value.toString())),
              );
            }
            if (value is double) {
              if (tableColumn.type.isMoney()) {
                value = Money(value).format();
              } else if (tableColumn.type.isPercentage()) {
                value = Percentage(value).format();
              } else {
                value = numberFormat(value);
              }
              return Align(
                  alignment: Alignment.topRight, child: SelectableText(value));
            }
            return Align(
                alignment: Alignment.topLeft,
                child: SelectableText(value.toString()));
          },
      footerRenderer: showFooter
          ? (rendererContext) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Offstage(
                    offstage: tableColumn.type.isPercentage(),
                    child: PlutoAggregateColumnFooter(
                      padding: const EdgeInsets.only(top: 5.0),
                      rendererContext: rendererContext,
                      formatAsCurrency: tableColumn.type.isMoney(),
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
                    formatAsCurrency: tableColumn.type.isMoney(),
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
                    formatAsCurrency: tableColumn.type.isMoney(),
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
                    formatAsCurrency: tableColumn.type.isMoney(),
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

class PlutoDeco with PlutoTableDecorator, PlatformChecker, TextFormatter {}

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
