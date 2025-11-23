import 'package:fe_pos/model/item.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';

import 'package:flutter/material.dart';
import 'package:fe_pos/tool/table_decorator.dart';
export 'package:fe_pos/tool/table_decorator.dart';
export 'package:fe_pos/tool/query_data.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';
export 'package:pluto_grid/pluto_grid.dart';

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
  final Future<DataTableResponse<T>> Function(QueryRequest) fetchData;
  final Map<String, List<Enum>> enums;
  final OnLoadedCallBack? onLoaded;
  final OnRowCheckedCallback? onRowChecked;
  final OnSelectedCallback? onSelected;
  final OnRowDoubleTapCallback? onRowDoubleTap;
  final bool showFilter;
  final String primaryKey;
  final Widget Function(T model)? renderAction;
  final double? actionColumnWidth;

  const CustomAsyncDataTable2({
    super.key,
    required this.fetchData,
    this.actions,
    this.onLoaded,
    this.header,
    this.actionColumnWidth,
    this.primaryKey = 'id',
    this.showFilter = true,
    required this.columns,
    this.enums = const {},
    this.onRowChecked,
    this.renderAction,
    this.onRowDoubleTap,
    this.onSelected,
    this.showSummary = false,
    this.showCheckboxColumn = false,
    this.fixedLeftColumns = 0,
  });

  @override
  State<CustomAsyncDataTable2<T>> createState() =>
      _CustomAsyncDataTable2State<T>();
}

class _CustomAsyncDataTable2State<T extends Model>
    extends State<CustomAsyncDataTable2<T>>
    with PlutoTableDecorator, PlatformChecker, TextFormatter {
  late final List<PlutoColumn> columns;
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
    }).toList()
      ..add(PlutoColumn(
          title: ' ',
          field: 'model',
          type: PlutoColumnType.text(defaultValue: null),
          hide: widget.renderAction == null,
          frozen: PlutoColumnFrozen.end,
          renderer: widget.renderAction == null
              ? null
              : (PlutoColumnRendererContext rendererContext) =>
                  widget.renderAction!(rendererContext.cell.value as T),
          width: widget.renderAction == null
              ? 0
              : widget.actionColumnWidth ?? PlutoGridSettings.columnWidth,
          minWidth: 0));

    super.initState();
  }

  bool _containsCheckedValue(Map<String, dynamic> row) {
    return selectedValues.contains(row[widget.primaryKey]);
  }

  QueryOperator filterTypeRemote(filterType) {
    if (filterType is PlutoFilterTypeContains) {
      return QueryOperator.contains;
    } else if (filterType is PlutoFilterTypeLessThanOrEqualTo) {
      return QueryOperator.lessThanOrEqualTo;
    } else if (filterType is PlutoFilterTypeNot) {
      return QueryOperator.not;
    } else if (filterType is PlutoFilterTypeEquals) {
      return QueryOperator.equals;
    } else if (filterType is PlutoFilterTypeGreaterThan) {
      return QueryOperator.greaterThan;
    } else if (filterType is PlutoFilterTypeGreaterThanOrEqualTo) {
      return QueryOperator.greaterThanOrEqualTo;
    } else if (filterType is PlutoFilterTypeLessThan) {
      return QueryOperator.lessThan;
    } else {
      return QueryOperator.equals;
    }
  }

  List<FilterData> remoteFilters() {
    List<FilterData> filter = [];
    for (final row in _source.filterRows) {
      filter.add(ComparisonFilterData(
        key: row.cells['column']!.value,
        operator: filterTypeRemote(row.cells['type']!.value),
        value: row.cells['value']!.value.toString(),
      ));
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
        var request = QueryRequest(
            page: 1,
            filters: remoteFilters(),
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
        final value = event.row?.cells[widget.primaryKey]?.value;
        if (value == null) {
          return;
        }
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
                QueryRequest(page: event.page, cancelToken: cancelToken);
            final sortColumn = event.sortColumn;

            if (sortColumn != null) {
              request.sorts = [
                SortData(
                    key: event.sortColumn!.field,
                    isAscending: event.sortColumn!.sort.isAscending),
              ];
            }
            request.filters = remoteFilters();
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
