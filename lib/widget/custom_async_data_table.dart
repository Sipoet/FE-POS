import 'package:data_table_2/data_table_2.dart';
import 'package:fe_pos/tool/text_formatter.dart';

import 'package:flutter/material.dart';
import 'package:fe_pos/tool/table_decorator.dart';
export 'package:fe_pos/tool/table_decorator.dart';

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
      width += column.width;
    }
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    double tableWidth = calculateTableWidth();
    List<DataColumn2> actions = [];
    if (_dataSource.hasActionButton) {
      actions.add(const DataColumn2(label: Text(''), fixedWidth: 200.0));
      tableWidth += 200;
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
              tooltip: tableColumn.name,
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
              fixedWidth: tableColumn.width,
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
                            final newWidth = tableColumn.width + increment;
                            setState(() {
                              tableColumn.initX = details.globalPosition.dx;
                              tableColumn.width = newWidth > minimumColumnWidth
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
                    width: tableColumn.width - 50,
                    child: Text(
                      tableColumn.name,
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
