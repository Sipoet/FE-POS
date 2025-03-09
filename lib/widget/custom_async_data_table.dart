import 'package:data_table_2/data_table_2.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/tool/table_decorator.dart';
export 'package:fe_pos/tool/table_decorator.dart';
import 'package:pluto_grid/pluto_grid.dart';
export 'package:pluto_grid/pluto_grid.dart';

class CustomAsyncDataTable extends StatefulWidget {
  final CustomAsyncDataTableSource controller;
  final int fixedLeftColumns;
  final List<Widget>? actions;
  final Widget? header;
  final bool showCheckboxColumn;
  final void Function(int)? onPageChanged;
  const CustomAsyncDataTable({
    super.key,
    required this.controller,
    this.onPageChanged,
    this.actions,
    this.header,
    this.showCheckboxColumn = false,
    this.fixedLeftColumns = 1,
  });

  @override
  State<CustomAsyncDataTable> createState() => _CustomAsyncDataTableState();
}

class _CustomAsyncDataTableState extends State<CustomAsyncDataTable> {
  int _sortColumnIndex = 0;
  int page = 1;
  int limit = 10;
  bool _sortAscending = true;
  final minimumColumnWidth = 100.0;
  CustomAsyncDataTableSource get _dataSource => widget.controller;
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
    if (_dataSource.hasActionButton) {
      actions.add(const DataColumn2(label: Text(''), fixedWidth: 300.0));
      tableWidth += 300;
    }
    return AsyncPaginatedDataTable2(
      key: ObjectKey(widget.key),
      sortArrowAlwaysVisible: true,
      showFirstLastButtons: true,
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
        // _dataSource.getRows((page - 1) * limit, limit);
      },
      onRowsPerPageChanged: (int? limit) {
        this.limit = limit ?? 10;
        _paginatorController.goToFirstPage();
      },
      pageSyncApproach: PageSyncApproach.goToLast,
      availableRowsPerPage: const [10, 20, 50, 100],
      headingRowColor:
          WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        return colorScheme.secondaryContainer.withOpacity(0.08);
      }),
    );
  }
}

class CustomAsyncDataTableSource<T extends Model> extends AsyncDataTableSource
    with TableDecorator<T>, TextFormatter {
  final List<TableColumn> columns;
  late List<T> sortedData = [];
  TableColumn? sortColumn;
  bool isAscending = true;
  List<Widget> Function(T model, int index)? actionButtons;
  Map<int, T> selectedMap = {};
  PaginatorController? paginatorController;
  bool isShowActions = false;
  List<T> get selected => selectedMap.values.toList();
  int totalRows = 0;

  Future<ResponseResult<T>> Function(
      {int page,
      int limit,
      TableColumn sortColumn,
      bool isAscending}) fetchData;

  CustomAsyncDataTableSource(
      {required this.fetchData,
      this.isShowActions = false,
      this.isAscending = true,
      this.sortColumn,
      required this.columns,
      this.actionButtons,
      this.paginatorController});

  void refreshDataFromFirstPage() {
    if (paginatorController?.isAttached ?? false) {
      paginatorController?.goToFirstPage();
    }
    refreshDatasource();
  }

  bool get hasActionButton => actionButtons is Function;

  void sortData(TableColumn sortColumn, bool isAscending) {
    this.sortColumn = sortColumn;
    this.isAscending = isAscending;
    refreshDatasource();
  }

  @override
  int get rowCount => totalRows;

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) {
    final page = startIndex ~/ count + 1;
    return fetchData(
            page: page,
            limit: count,
            isAscending: this.isAscending,
            sortColumn: this.sortColumn ?? this.columns[0])
        .then((responseResult) {
      totalRows = responseResult.totalRows;
      List<DataRow> rows = [];
      for (T model in responseResult.models) {
        rows.add(DataRow(
          key: ValueKey<dynamic>(model.id),
          onSelectChanged: (value) {
            if (value != null) {
              setRowSelection(ValueKey<dynamic>(model.id), value);
            }
          },
          cells: decorateModel(model,
              columns: columns, actionButtons: actionButtons),
        ));
      }
      return AsyncRowsResponse(totalRows, rows);
    });
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => selectedMap.keys.length;
}

class ResponseResult<T> {
  int totalRows;
  List<T> models;
  ResponseResult({this.totalRows = 0, required this.models});
}

typedef OnLoadedCallBack = void Function(PlutoGridStateManager stateManager);
typedef OnRowCheckedCallback = void Function(PlutoGridOnRowCheckedEvent event);
typedef OnSelectedCallback = void Function(PlutoGridOnSelectedEvent event);
typedef OnRowDoubleTapCallback = void Function(
    PlutoGridOnRowDoubleTapEvent event);

class CustomASyncDataTable2<T extends Model> extends StatefulWidget {
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

  const CustomASyncDataTable2({
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
  State<CustomASyncDataTable2<T>> createState() =>
      _CustomASyncDataTable2State<T>();
}

class _CustomASyncDataTable2State<T extends Model>
    extends State<CustomASyncDataTable2<T>> with PlutoTableDecorator {
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
