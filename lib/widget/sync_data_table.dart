import 'package:data_table_2/data_table_2.dart';
import 'package:fe_pos/tool/text_formatter.dart';

import 'package:flutter/material.dart';
import 'package:fe_pos/tool/table_decorator.dart';
export 'package:fe_pos/tool/table_decorator.dart';
import 'package:pluto_grid/pluto_grid.dart';
export 'package:pluto_grid/pluto_grid.dart';

class SyncDataTable extends StatefulWidget {
  final SyncDataTableSource controller;
  final int fixedLeftColumns;
  final List<Widget>? actions;
  final Widget? header;
  final bool showCheckboxColumn;
  final bool showSummary;

  final void Function(int)? onPageChanged;
  const SyncDataTable({
    super.key,
    required this.controller,
    this.onPageChanged,
    this.actions,
    this.header,
    this.showSummary = false,
    this.showCheckboxColumn = false,
    this.fixedLeftColumns = 1,
  });

  @override
  State<SyncDataTable> createState() => _SyncDataTableState();
}

class _SyncDataTableState extends State<SyncDataTable> {
  int _sortColumnIndex = 0;
  int page = 1;
  int limit = 10;
  bool _sortAscending = true;
  final minimumColumnWidth = 100.0;
  SyncDataTableSource get _dataSource => widget.controller;
  List<TableColumn> get columns => _dataSource.columns;
  final _paginatorController = PaginatorController();

  @override
  void initState() {
    _dataSource.paginatorController = _paginatorController;
    if (_dataSource.sortColumn != null) {
      _sortColumnIndex = _dataSource.columns.indexOf(_dataSource.sortColumn!);
      _sortAscending = _dataSource.isAscending;
    }
    super.initState();
  }

  @override
  void dispose() {
    _paginatorController.dispose();
    super.dispose();
  }

  double calculateTableWidth() {
    double width = 100;
    for (TableColumn column in columns) {
      width += column.clientWidth;
    }
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    double tableWidth = calculateTableWidth();
    List<DataColumn2> actions = [];
    if (_dataSource.actionButtons != null) {
      actions.add(const DataColumn2(label: Text(''), fixedWidth: 200.0));
      tableWidth += 200;
    }
    return PaginatedDataTable2(
      key: ObjectKey(widget.key),
      sortArrowAlwaysVisible: true,
      source: _dataSource,
      actions: widget.actions,
      header: widget.header,
      showCheckboxColumn: widget.showCheckboxColumn,
      fixedLeftColumns: widget.fixedLeftColumns,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      headingRowDecoration: BoxDecoration(
          border: Border.all(width: 2, color: colorScheme.outline)),
      controller: _paginatorController,
      border: TableBorder.all(
          width: 1, color: colorScheme.outline.withOpacity(0.5)),
      empty: const Text('Data tidak ditemukan'),
      columns: (columns).map<DataColumn2>((tableColumn) {
            return DataColumn2(
              tooltip: tableColumn.humanizeName,
              numeric: true,
              onSort: tableColumn.canSort
                  ? ((columnIndex, ascending) {
                      setState(() {
                        _sortColumnIndex = columnIndex;
                        _sortAscending = ascending;
                      });
                      _dataSource.sortData(tableColumn, _sortAscending);
                    })
                  : null,
              fixedWidth: tableColumn.clientWidth,
              label: Stack(
                alignment: AlignmentDirectional.centerStart,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                          onHorizontalDragStart: (details) {
                            setState(() {
                              tableColumn.initX = details.globalPosition.dx;
                            });
                          },
                          onHorizontalDragUpdate: (details) {
                            final increment =
                                details.globalPosition.dx - tableColumn.initX;
                            final newWidth =
                                tableColumn.clientWidth + increment;
                            setState(() {
                              tableColumn.initX = details.globalPosition.dx;
                              tableColumn.clientWidth =
                                  newWidth > minimumColumnWidth
                                      ? newWidth
                                      : minimumColumnWidth;
                            });
                          },
                          child: const Icon(
                            Icons.switch_left,
                            size: 20,
                          ))),
                  Positioned(
                    left: 0,
                    width: tableColumn.clientWidth - 50,
                    child: Text(
                      tableColumn.humanizeName,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }).toList() +
          actions,
      minWidth: tableWidth,
      onPageChanged: (int page) {
        this.page = page;
        if (widget.onPageChanged != null) {
          widget.onPageChanged!(page);
        }
      },
      showFirstLastButtons: true,
      onRowsPerPageChanged: (int? limit) {
        this.limit = limit ?? 10;
        _paginatorController.goToFirstPage();
      },
      availableRowsPerPage: const [10, 20, 50, 100],
      headingRowColor:
          WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        return colorScheme.secondaryContainer.withOpacity(0.08);
      }),
    );
  }
}

class SyncDataTableSource<T extends Model> extends DataTableSource
    with TableDecorator<T>, TextFormatter {
  late List<T> sortedData = [];
  final List<TableColumn> columns;
  TableColumn? sortColumn;
  bool isAscending;
  Map<int, T> selectedMap = {};
  PaginatorController? paginatorController;
  bool isShowActions = false;
  List<T> get selected => selectedMap.values.toList();
  List<Widget> Function(T model, int? index)? actionButtons;

  SyncDataTableSource(
      {required this.columns,
      this.isAscending = true,
      this.sortColumn,
      this.actionButtons,
      this.paginatorController});

  void setActionButtons(value) {
    actionButtons = value;
  }

  void updateData(index, T model) {
    sortedData[index] = model;
    notifyListeners();
  }

  void refreshData() {
    notifyListeners();
  }

  void setData(List<T> rawData) {
    if (paginatorController?.isAttached ?? false) {
      paginatorController?.goToFirstPage();
    }
    sortedData = rawData;

    sortData(sortColumn ?? columns[0], isAscending);
  }

  void sortData(TableColumn sortColumn, bool isAscending) {
    this.sortColumn = sortColumn;
    this.isAscending = isAscending;
    sortedData.sort((T a, T b) {
      var cellA = a.toMap()[sortColumn.attributeKey] ?? '';
      var cellB = b.toMap()[sortColumn.attributeKey] ?? '';
      if (cellA is TimeOfDay) {
        cellA = cellA.toString();
        cellB = cellB.toString();
      }
      return cellA.compareTo(cellB) * (isAscending ? 1 : -1);
    });
    notifyListeners();
  }

  @override
  int get rowCount => sortedData.length;

  @override
  DataRow? getRow(int index) {
    T model = sortedData[index];
    return DataRow.byIndex(
      index: index,
      selected: selectedMap.containsKey(index),
      onSelectChanged: (bool? isSelected) {
        if (isSelected == true) {
          selectedMap[index] = model;
        } else {
          selectedMap.remove(index);
        }
        notifyListeners();
      },
      cells: decorateModel(model,
          index: index, columns: columns, actionButtons: actionButtons),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}

typedef OnLoadedCallBack = void Function(PlutoGridStateManager stateManager);
typedef OnRowCheckedCallback = void Function(PlutoGridOnRowCheckedEvent event);
typedef OnSelectedCallback = void Function(PlutoGridOnSelectedEvent event);
typedef OnRowDoubleTapCallback = void Function(
    PlutoGridOnRowDoubleTapEvent event);

class SyncDataTable2<T extends Model> extends StatefulWidget {
  final int fixedLeftColumns;
  final List<Widget>? actions;
  final Widget? header;
  final bool showCheckboxColumn;
  final bool showSummary;
  final List<T> rows;
  final List<TableColumn> columns;
  final void Function(int)? onPageChanged;
  final Map<String, List<Enum>> enums;
  final OnLoadedCallBack? onLoaded;
  final OnRowCheckedCallback? onRowChecked;
  final OnSelectedCallback? onSelected;
  final OnRowDoubleTapCallback? onRowDoubleTap;
  final bool showFilter;

  const SyncDataTable2({
    super.key,
    this.onPageChanged,
    this.actions,
    this.onLoaded,
    this.header,
    this.showFilter = true,
    List<TableColumn>? columns,
    List<T>? rows,
    this.enums = const {},
    this.onRowChecked,
    this.onRowDoubleTap,
    this.onSelected,
    this.showSummary = false,
    this.showCheckboxColumn = false,
    this.fixedLeftColumns = 0,
  })  : columns = columns ?? const [],
        rows = rows ?? const [];

  @override
  State<SyncDataTable2<T>> createState() => _SyncDataTable2State<T>();
}

extension TableStateMananger on PlutoGridStateManager {
  PlutoDeco get decorator => PlutoDeco();

  void appendModel(model, List<TableColumn> tableColumns) {
    appendRows([decorator.decorateRow(model, tableColumns)]);
    notifyListeners();
  }

  void setModels(models, List<TableColumn> tableColumns) {
    if (rows.isNotEmpty) {
      removeAllRows();
    }
    final rowsTemp = models
        .map<PlutoRow>((model) => decorator.decorateRow(model, tableColumns))
        .toList();
    appendRows(rowsTemp);
    notifyListeners();
  }

  void setTableColumns(List<TableColumn> tableColumns,
      {int fixedLeftColumns = 0,
      bool showCheckboxColumn = false,
      bool showFilter = false}) {
    removeColumns(columns);
    final newColumns = tableColumns.asMap().entries.map<PlutoColumn>((entry) {
      int index = entry.key;
      TableColumn tableColumn = entry.value;
      return decorator.decorateColumn(
        tableColumn,
        showCheckboxColumn: showCheckboxColumn,
        showFilter: showFilter,
        isFrozen: index < fixedLeftColumns,
      );
    }).toList();
    insertColumns(0, newColumns);
  }
}

class _SyncDataTable2State<T extends Model> extends State<SyncDataTable2<T>>
    with PlutoTableDecorator {
  late List<PlutoColumn> columns;
  late List<PlutoRow> rows;

  @override
  void initState() {
    columns = widget.columns.asMap().entries.map<PlutoColumn>((entry) {
      int index = entry.key;
      TableColumn tableColumn = entry.value;
      return decorateColumn(
        tableColumn,
        listEnumValues: widget.enums[tableColumn.name],
        showCheckboxColumn: widget.showCheckboxColumn,
        showFilter: widget.showFilter,
        isFrozen: index < widget.fixedLeftColumns,
      );
    }).toList();
    rows = widget.rows
        .map<PlutoRow>((row) => decorateRow(row, widget.columns))
        .toList();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PlutoGrid(
      columns: columns,
      rows: rows,
      onLoaded: (PlutoGridOnLoadedEvent event) {
        final stateManager = event.stateManager;
        stateManager.setShowColumnFilter(widget.showFilter);
        stateManager.setShowColumnFooter(widget.showSummary);
        stateManager.columnFooterHeight = 115.0;
        if (widget.onLoaded is Function) {
          widget.onLoaded!(stateManager);
        }
      },
      noRowsWidget: const Text('Data tidak ditemukan'),
      onChanged: (PlutoGridOnChangedEvent event) {
        debugPrint(event.toString());
      },
      mode: PlutoGridMode.selectWithOneTap,
      onSelected: widget.onSelected,
      onRowDoubleTap: widget.onRowDoubleTap,
      onRowChecked: widget.onRowChecked,
      configuration: PlutoGridConfiguration(
          scrollbar: const PlutoGridScrollbarConfig(
            isAlwaysShown: true,
            scrollbarThickness: 10,
          ),
          style: PlutoGridStyleConfig(
              borderColor: colorScheme.outline,
              rowColor: colorScheme.secondaryContainer,
              evenRowColor: colorScheme.onPrimary)),
    );
  }
}

mixin PlutoTableDecorator {
  final String _formatPercentage = '';
  final String _formatNumber = '#,###.#';
  final String _locale = 'id_ID';
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
      case 'enum':
        return PlutoColumnType.select(
            listEnumValues ?? tableColumn.options['enums'] ?? []);
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

  PlutoRow decorateRow(row, List<TableColumn> tableColumns) {
    final rowMap = row.toMap();
    Map<String, PlutoCell> cells = {};
    for (final tableColumn in tableColumns) {
      var value = rowMap[tableColumn.name];
      if (tableColumn.renderValue != null) {
        value = tableColumn.renderValue!(rowMap);
      }
      if (value is Money) {
        value = value.value;
      } else if (value is Percentage) {
        value = value.value * 100;
      }
      cells[tableColumn.name] = PlutoCell(value: value);
    }

    return PlutoRow(cells: cells, type: PlutoRowType.normal());
  }

  static const _labelStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Color.fromRGBO(56, 142, 60, 1));
  static const _footerStyle = TextStyle(fontWeight: FontWeight.bold);

  PlutoColumn decorateColumn(TableColumn tableColumn,
      {List<Enum>? listEnumValues,
      bool showCheckboxColumn = false,
      bool showFilter = false,
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
