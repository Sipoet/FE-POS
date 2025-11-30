import 'package:fe_pos/model/model.dart';
import 'package:fe_pos/tool/model_route.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
export 'package:fe_pos/model/model.dart';
export 'package:fe_pos/tool/custom_type.dart';
import 'package:trina_grid/trina_grid.dart';

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

class TableColumn<T extends Model> {
  double initX;
  double clientWidth;
  double? excelWidth;
  String name;
  TableColumnType type;
  Widget Function(TrinaColumnRendererContext rendererContext)? renderBody;
  dynamic Function(T model)? getValue;
  String humanizeName;
  bool canSort;
  bool canFilter;
  TrinaColumnFrozen frozen;
  Map<String, dynamic> inputOptions = {};

  TableColumn(
      {this.initX = 0,
      required this.clientWidth,
      this.excelWidth,
      this.renderBody,
      this.getValue,
      this.frozen = TrinaColumnFrozen.none,
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

const modelKey = 'model';
mixin TrinaTableDecorator implements PlatformChecker, TextFormatter {
  late final TabManager tabManager;
  final String _formatNumber = '#,###.#';
  final String _locale = 'id_ID';
  late final Server server;
  final route = ModelRoute();
  TrinaColumnType _parseColumnType(TableColumn tableColumn,
      {List<Enum>? listEnumValues}) {
    switch (tableColumn.type) {
      case TableColumnType.text:
        return TrinaColumnType.text();
      case TableColumnType.date:
        return TrinaColumnType.date(format: 'dd/MM/yyyy');
      case TableColumnType.datetime:
        return TrinaColumnType.dateTime(format: 'dd/MM/yyyy HH:mm');
      case TableColumnType.timeOnly:
        return TrinaColumnType.time();
      case TableColumnType.money:
        return TrinaColumnType.currency(
            locale: _locale,
            // format: _formatNumber,
            symbol: 'Rp',
            decimalDigits: 2);
      case TableColumnType.model:
        return TrinaColumnTypeModelSelect(
            path: tableColumn.inputOptions['path'] ?? '',
            modelName: tableColumn.inputOptions['model_name'] ?? '',
            attributeKey: tableColumn.inputOptions['attribute_key'] ?? '');
      case TableColumnType.enums:
        return TrinaColumnType.select(
            listEnumValues ?? tableColumn.inputOptions['enums'] ?? []);
      case TableColumnType.percentage:
        return TrinaColumnTypePercentage2();
      case TableColumnType.number:
        return TrinaColumnType.number(locale: _locale, format: _formatNumber);
      case TableColumnType.boolean:
        return TrinaColumnType.select([true, false]);
      default:
        return TrinaColumnType.text();
    }
  }

  TrinaRow decorateRow(
      {required Model model,
      required List<TrinaColumn> tableColumns,
      bool isChecked = false}) {
    final rowMap = model.asMap();
    Map<String, TrinaCell> cells = {};
    for (final tableColumn in tableColumns) {
      cells[tableColumn.field] = TrinaCell(value: rowMap[tableColumn.field]);
    }
    cells['id'] = TrinaCell(value: model.id);
    cells[modelKey] = TrinaCell(value: model, key: ObjectKey(model));
    return TrinaRow(
        cells: cells, checked: isChecked, type: TrinaRowType.normal());
  }

  void _openModelDetailPage(
      {required TableColumn tableColumn, required Model value}) {
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

  TrinaColumn decorateColumn(TableColumn tableColumn,
      {List<Enum>? listEnumValues,
      bool showFilter = false,
      required TabManager tabManager,
      bool showCheckboxColumn = false,
      bool isFrozen = false}) {
    final columnType =
        _parseColumnType(tableColumn, listEnumValues: listEnumValues);
    bool showFooter = tableColumn.isNumeric();
    final format = _formatNumber;
    final renderer = tableColumn.renderBody ??
        (TrinaColumnRendererContext rendererContext) =>
            defaultRenderBody(rendererContext, tableColumn);
    return TrinaColumn(
      titleTextAlign: TrinaColumnTextAlign.center,
      readOnly: true,
      enableSorting: tableColumn.canSort,
      enableEditingMode: false,
      textAlign:
          showFooter ? TrinaColumnTextAlign.right : TrinaColumnTextAlign.left,
      title: tableColumn.humanizeName,
      field: tableColumn.name,
      minWidth: 50 < tableColumn.clientWidth ? 50 : tableColumn.clientWidth,
      width: tableColumn.clientWidth,
      type: columnType,
      frozen: isFrozen ? TrinaColumnFrozen.start : tableColumn.frozen,
      enableRowChecked: showCheckboxColumn,
      enableFilterMenuItem: showFilter,
      enableContextMenu: !tableColumn.type.isAction(),
      renderer: renderer,
      footerRenderer: showFooter
          ? (rendererContext) {
              return ListView(
                children: [
                  Offstage(
                    offstage: tableColumn.type.isPercentage(),
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
                              child: Text(
                                'TOTAL',
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
                            child: Text(
                              'RATA2',
                              style: _labelStyle,
                            ),
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

  Widget defaultRenderBody(
      TrinaColumnRendererContext rendererContext, TableColumn tableColumn) {
    var value = rendererContext.cell.value ?? '';
    if (tableColumn.type.isModel() && value is Model) {
      return InkWell(
        onTap: () => _openModelDetailPage(
          tableColumn: tableColumn,
          value: value,
        ),
        child: Text(
          value.modelValue,
          textAlign: TextAlign.left,
        ),
      );
    }

    if (value is Money || value is Percentage) {
      return SelectableText(
        value.format(),
        textAlign: TextAlign.right,
      );
    } else if (value is double && tableColumn.type.isMoney()) {
      return SelectableText(
        moneyFormat(value),
        textAlign: TextAlign.right,
      );
    } else if (value is num) {
      return SelectableText(
        numberFormat(value),
        textAlign: TextAlign.right,
      );
    } else if (value is TimeOfDay) {
      return SelectableText(value.format24Hour(), textAlign: TextAlign.left);
    } else if (value is Date) {
      return SelectableText(value.format(), textAlign: TextAlign.left);
    } else if (value is DateTime) {
      if (tableColumn.type == TableColumnType.timeOnly) {
        return SelectableText(TimeOfDay.fromDateTime(value).format24Hour(),
            textAlign: TextAlign.left);
      }
      return SelectableText(value.format(), textAlign: TextAlign.left);
    } else if (value is EnumTranslation) {
      return SelectableText(value.humanize(), textAlign: TextAlign.left);
    }
    return SelectableText(
      value.toString(),
      textAlign: TextAlign.left,
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

  void setModels(List models) {
    if (rows.isNotEmpty) {
      removeAllRows();
    }
    final rowsTemp = models
        .map<TrinaRow>((model) =>
            decorator.decorateRow(model: model, tableColumns: columns))
        .toList();
    appendRows(rowsTemp);
    notifyListeners();
  }

  void setTableColumns(List<TableColumn> tableColumns,
      {int fixedLeftColumns = 0,
      bool showFilter = false,
      required TabManager tabManager}) {
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
    eventManager!.addEvent(TrinaGridChangeColumnSortEvent(
        column: columns.first, oldSort: TrinaColumnSort.none));
  }
}

class TrinaFilterTypeNot implements TrinaFilterType {
  @override
  String get title => 'Not equal';

  @override
  get compare => ({
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
    return v?.value;
  }

  @override
  bool isValid(dynamic value) => value is Percentage;

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
