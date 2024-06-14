import 'package:data_table_2/data_table_2.dart';

import 'package:flutter/material.dart';
import 'package:fe_pos/tool/datatable.dart';
export 'package:fe_pos/tool/datatable.dart';

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
      scrollController: ScrollController(keepScrollOffset: false),
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
      headingRowColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        return colorScheme.secondaryContainer.withOpacity(0.08);
      }),
    );
  }
}

class SyncDataTable extends StatefulWidget {
  final SyncDataTableSource controller;
  final int fixedLeftColumns;
  final List<Widget>? actions;
  final Widget? header;
  final bool showCheckboxColumn;
  final void Function(int)? onPageChanged;
  const SyncDataTable({
    super.key,
    required this.controller,
    this.onPageChanged,
    this.actions,
    this.header,
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
      width += column.width;
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
      scrollController: ScrollController(keepScrollOffset: false),
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
      },
      showFirstLastButtons: true,
      onRowsPerPageChanged: (int? limit) {
        this.limit = limit ?? 10;
        _paginatorController.goToFirstPage();
      },
      availableRowsPerPage: const [10, 20, 50, 100],
      headingRowColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        return colorScheme.secondaryContainer.withOpacity(0.08);
      }),
    );
  }
}
