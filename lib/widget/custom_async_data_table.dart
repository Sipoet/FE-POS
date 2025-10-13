import 'package:data_table_2/data_table_2.dart';
import 'package:fe_pos/model/item.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';

import 'package:flutter/material.dart';
import 'package:fe_pos/tool/table_decorator.dart';
export 'package:fe_pos/tool/table_decorator.dart';
import 'package:fe_pos/tool/query_data.dart';
export 'package:fe_pos/tool/query_data.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';
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
    _dataSource.tabManager = context.read<TabManager>();
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
          width: 1, color: colorScheme.outline.withValues(alpha: 0.5)),
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
        return colorScheme.secondaryContainer.withValues(alpha: 0.08);
      }),
    );
  }
}

class CustomAsyncDataTableSource<T extends Model> extends AsyncDataTableSource
    with TableDecorator<T>, TextFormatter, PlatformChecker {
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
            if (value == null) {
              return;
            }
            if (value) {
              selectedMap[model.id] = model;
            } else {
              selectedMap.remove(model);
            }

            setRowSelection(ValueKey<dynamic>(model.id), value);
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

class CustomAsyncDataTable2<T extends Model> extends StatefulWidget {
  final int fixedLeftColumns;
  final List<Widget>? actions;
  final Widget? header;
  final bool showCheckboxColumn;
  final bool showSummary;
  final List<TableColumn> columns;
  final Future<DataTableResponse<T>> Function(DataTableRequest) fetchData;
  final Map<String, List<Enum>> enums;
  final OnLoadedCallBack? onLoaded;
  final OnRowCheckedCallback? onRowChecked;
  final OnSelectedCallback? onSelected;
  final OnRowDoubleTapCallback? onRowDoubleTap;
  final bool showFilter;
  final String primaryKey;

  const CustomAsyncDataTable2({
    super.key,
    required this.fetchData,
    this.actions,
    this.onLoaded,
    this.header,
    this.primaryKey = 'id',
    this.showFilter = true,
    List<TableColumn>? columns,
    this.enums = const {},
    this.onRowChecked,
    this.onRowDoubleTap,
    this.onSelected,
    this.showSummary = false,
    this.showCheckboxColumn = false,
    this.fixedLeftColumns = 0,
  }) : columns = columns ?? const [];

  @override
  State<CustomAsyncDataTable2<T>> createState() =>
      _CustomAsyncDataTable2State<T>();
}

class _CustomAsyncDataTable2State<T extends Model>
    extends State<CustomAsyncDataTable2<T>>
    with PlutoTableDecorator, PlatformChecker, TextFormatter {
  late List<PlutoColumn> columns;
  late final PlutoGridStateManager _source;
  List selectedValues = [];

  @override
  void initState() {
    server = context.read<Server>();
    tabManager = context.read<TabManager>();
    columns = widget.columns.asMap().entries.map<PlutoColumn>((entry) {
      int index = entry.key;
      TableColumn tableColumn = entry.value;
      return decorateColumn(
        tableColumn,
        tabManager: tabManager,
        showCheckboxColumn: index == 0 ? widget.showCheckboxColumn : false,
        listEnumValues: widget.enums[tableColumn.name],
        showFilter: widget.showFilter,
        isFrozen: index < widget.fixedLeftColumns,
      );
    }).toList();

    super.initState();
  }

  bool _containsCheckedValue(Map<String, dynamic> row) {
    return selectedValues.contains(row[widget.primaryKey]);
  }

  String filterTypeRemote(filterType) {
    if (filterType is PlutoFilterTypeContains) {
      return 'like';
    } else if (filterType is PlutoFilterTypeLessThanOrEqualTo) {
      return 'lte';
    } else if (filterType is PlutoFilterTypeNot) {
      return 'not';
    } else if (filterType is PlutoFilterTypeEquals) {
      return 'eq';
    } else if (filterType is PlutoFilterTypeGreaterThan) {
      return 'gt';
    } else if (filterType is PlutoFilterTypeGreaterThanOrEqualTo) {
      return 'gte';
    } else if (filterType is PlutoFilterTypeLessThan) {
      return 'lt';
    } else {
      return 'eq';
    }
  }

  Map<String, String> remoteFilters() {
    Map<String, String> filter = {};
    for (final row in _source.filterRows) {
      final columnName = row.cells['column']!.value;
      final comparator = filterTypeRemote(row.cells['type']!.value);
      final key = 'filter[$columnName][$comparator]';
      filter[key] = row.cells['value']!.value.toString();
    }
    return filter;
  }

  Map<String, List<Item>> selectedItems = {};
  Future<List<Item>?> showRemoteOptions({
    required String path,
    required String attributeKey,
    String searchText = '',
    String title = '',
  }) {
    final itemBefore = selectedItems[title] ?? [];
    return showDialog<List<Item>>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter $title',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () {
                      selectedItems[title] = itemBefore;
                      Navigator.of(context).pop(itemBefore);
                    },
                    icon: Icon(Icons.close),
                  )
                ],
              ),
              content: Column(
                children: [
                  SizedBox(
                    width: 400,
                    child: AsyncDropdownMultiple<Item>(
                      path: path,
                      width: 400,
                      selecteds: itemBefore,
                      textOnSearch: (item) => _itemText(item, attributeKey),
                      modelClass: ItemClass(),
                      onChanged: (List<Item> items) =>
                          selectedItems[title] = items,
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(selectedItems[title]),
                    child: Text('Submit'),
                  ),
                ],
              ));
        });
  }

  String _itemText(Item item, String attributeKey) {
    final key = attributeKey.split('.').last;
    return "${item.id.toString()} - ${item[key].toString()}";
  }

  CancelToken? cancelToken;
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PlutoGrid(
      columns: columns,
      rows: <PlutoRow>[],
      onSorted: (event) {
        var sorts = <SortData>[];
        if (!event.column.sort.isNone) {
          sorts = [
            SortData(
                key: event.column.field,
                isAscending: event.column.sort.isAscending)
          ];
        }
        cancelToken?.cancel();
        cancelToken = CancelToken();
        var request = DataTableRequest(
            page: 1,
            filter: remoteFilters(),
            sorts: sorts,
            cancelToken: cancelToken);

        widget.fetchData(request);
      },
      onLoaded: (PlutoGridOnLoadedEvent event) {
        _source = event.stateManager;
        _source.setShowColumnFilter(widget.showFilter);
        _source.setShowColumnFooter(widget.showSummary);
        _source.columnFooterHeight = 130.0;
        _source.eventManager!.listener((event) {
          if (event is PlutoGridChangeColumnFilterEvent) {
            final columType = event.column.type;
            if (columType is PlutoColumnTypeModelSelect) {
              showRemoteOptions(
                      searchText: event.filterValue,
                      title: event.column.title,
                      path: columType.path,
                      attributeKey: columType.attributeKey)
                  .then((items) {
                if (items == null) return;
                final filterValue = items
                    .map<String>((item) => item.id.toString())
                    .toList()
                    .join(',');
                List<PlutoRow> filterRows = _source.filterRows
                    .where((filterRow) =>
                        filterRow.cells['column']!.value ==
                            event.column.field &&
                        filterRow.cells['type']!.value is PlutoFilterTypeEquals)
                    .toList();
                if (filterRows.isEmpty) {
                  _source.filterRows.add(FilterHelper.createFilterRow(
                    filterType: PlutoFilterTypeEquals(),
                    filterValue: filterValue,
                    columnField: event.column.field,
                  ));
                } else {
                  filterRows.first.cells['value'] =
                      PlutoCell(value: filterValue);
                }
                _source.setFilterRows(_source.filterRows);
                _source.refreshTable();
              });
            }
          }
        });

        if (widget.onLoaded is Function) {
          widget.onLoaded!(_source);
        }
      },
      noRowsWidget: const Text('Data tidak ditemukan'),
      onChanged: (PlutoGridOnChangedEvent event) {
        debugPrint("onchanged ${event.toString()}");
      },
      mode: PlutoGridMode.selectWithOneTap,
      onSelected: widget.onSelected,
      onRowDoubleTap: widget.onRowDoubleTap,
      onRowChecked: (PlutoGridOnRowCheckedEvent event) {
        if (!event.isRow) {
          return;
        }
        final value = event.row!.cells[widget.primaryKey]!.value;
        if (event.isChecked == true) {
          selectedValues.add(value);
        } else {
          selectedValues.remove(value);
        }
        if (widget.onRowChecked is Function) {
          widget.onRowChecked!(event);
        }
      },
      createFooter: (stateManager) {
        return PlutoLazyPagination(
          fetch: (event) async {
            cancelToken?.cancel();
            cancelToken = CancelToken();
            var request =
                DataTableRequest(page: event.page, cancelToken: cancelToken);
            final sortColumn = event.sortColumn;

            if (sortColumn != null) {
              request.sorts = [
                SortData(
                    key: event.sortColumn!.field,
                    isAscending: event.sortColumn!.sort.isAscending),
              ];
            }
            request.filter = remoteFilters();
            return widget.fetchData(request).then(
              (DataTableResponse<T> response) {
                return PlutoLazyPaginationResponse(
                    rows: response.models
                        .map<PlutoRow>(
                          (model) => decorateRow(
                              isChecked: _containsCheckedValue(model.toMap()),
                              model: model,
                              tableColumns: widget.columns),
                        )
                        .toList(),
                    totalPage: response.totalPage);
              },
            );
          },
          stateManager: stateManager,
        );
      },
      configuration: PlutoGridConfiguration(
          columnFilter: PlutoGridColumnFilterConfig(
            filters: [
              PlutoFilterTypeContains(),
              PlutoFilterTypeEquals(),
              PlutoFilterTypeNot(),
              PlutoFilterTypeLessThan(),
              PlutoFilterTypeLessThanOrEqualTo(),
              PlutoFilterTypeGreaterThan(),
              PlutoFilterTypeGreaterThanOrEqualTo(),
            ],
            debounceMilliseconds: 500,
            resolveDefaultColumnFilter: (column, resolver) {
              if (column.type is PlutoColumnTypeModelSelect ||
                  column.type is PlutoColumnTypeNumber ||
                  column.type is PlutoColumnTypeCurrency) {
                return resolver<PlutoFilterTypeEquals>();
              } else {
                return resolver<PlutoFilterTypeContains>();
              }
            },
          ),
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

class DataTableRequest {
  int page;
  Map<String, dynamic> filter;
  List<SortData> sorts;
  CancelToken? cancelToken;
  DataTableRequest({
    this.page = 1,
    this.cancelToken,
    this.sorts = const [],
    this.filter = const {},
  });
}

class DataTableResponse<T extends Model> {
  int totalPage;
  List<T> models;
  DataTableResponse({this.totalPage = 0, this.models = const []});
}
