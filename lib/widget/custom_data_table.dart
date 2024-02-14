import 'package:data_table_2/data_table_2.dart';

import 'package:flutter/material.dart';
import 'package:fe_pos/tool/datatable.dart';
export 'package:fe_pos/tool/datatable.dart';

class CustomDataTable extends StatefulWidget {
  final Future<List<Model>> Function(
      int page, String orderKey, bool isAscending)? onPageChanged;
  final CustomDataTableSource controller;
  final int fixedLeftColumns;
  final List<Widget>? actions;
  final Widget? header;
  final bool showCheckboxColumn;
  const CustomDataTable({
    super.key,
    required this.controller,
    this.onPageChanged,
    this.actions,
    this.header,
    this.showCheckboxColumn = false,
    this.fixedLeftColumns = 1,
  });

  @override
  State<CustomDataTable> createState() => _CustomDataTableState();
}

class _CustomDataTableState extends State<CustomDataTable> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  final minimumColumnWidth = 100.0;
  List<TableColumn> get columns => _dataSource.columns;
  CustomDataTableSource get _dataSource => widget.controller;
  @override
  void initState() {
    super.initState();
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
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    double tableWidth = calculateTableWidth();
    List<TableColumn> actions = [];
    if (_dataSource.actionButtons != null) {
      actions.add(TableColumn(key: 'action', name: ''));
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
      controller: _dataSource.paginatorController,
      border: TableBorder.all(
          width: 1, color: colorScheme.outline.withOpacity(0.5)),
      empty: const Text('Data tidak ditemukan'),
      columns: (columns + actions).map<DataColumn2>((tableColumn) {
        return DataColumn2(
          tooltip: tableColumn.name,
          numeric: true,
          onSort: ((columnIndex, ascending) {
            setState(() {
              _sortColumnIndex = columnIndex;
              _sortAscending = ascending;
            });
            _dataSource.sortData(tableColumn.key, _sortAscending);
          }),
          fixedWidth: tableColumn.width,
          label: Stack(
            alignment: AlignmentDirectional.centerStart,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                      onPanStart: (details) {
                        setState(() {
                          tableColumn.initX = details.globalPosition.dx;
                        });
                      },
                      onPanUpdate: (details) {
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
      }).toList(),
      minWidth: tableWidth,
      headingRowColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        return colorScheme.secondaryContainer.withOpacity(0.08);
      }),
    );
  }
}
