import 'package:async/async.dart';
import 'package:fe_pos/model/hash_model.dart';
import 'package:fe_pos/tool/default_response.dart';

import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/mobile_table.dart';

import 'package:flutter/material.dart';
import 'package:fe_pos/tool/table_decorator.dart';
export 'package:fe_pos/tool/table_decorator.dart';
export 'package:fe_pos/tool/query_data.dart';
import 'package:trina_grid/trina_grid.dart';
import 'package:provider/provider.dart';
export 'package:trina_grid/trina_grid.dart';

typedef OnLoadedCallBack<T extends Model> =
    void Function(TableController<T> stateManager);
typedef OnRowCheckedCallback = void Function(TrinaGridOnRowCheckedEvent event);
typedef OnSelectedCallback = void Function(TrinaGridOnSelectedEvent event);
typedef OnRowDoubleTapCallback =
    void Function(TrinaGridOnRowDoubleTapEvent event);

class CustomAsyncDataTable<T extends Model> extends StatefulWidget {
  final int fixedLeftColumns;
  final List<Widget>? actions;
  final Widget? header;
  final bool showCheckboxColumn;
  final bool showSummary;
  final List<TableColumn> columns;
  final Future<DataTableResponse<T>> Function(QueryRequest) fetchData;
  final Map<String, List<Enum>> enums;
  final OnLoadedCallBack<T>? onLoaded;
  final OnRowCheckedCallback? onRowChecked;
  final OnSelectedCallback? onSelected;
  final OnRowDoubleTapCallback? onRowDoubleTap;
  final bool showFilter;
  final String primaryKey;
  final Widget Function(T model)? renderAction;
  final double? actionColumnWidth;

  const CustomAsyncDataTable({
    super.key,
    required this.fetchData,
    this.actions,
    this.onLoaded,
    this.header,
    this.actionColumnWidth,
    this.primaryKey = 'id',
    this.showFilter = false,
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
  State<CustomAsyncDataTable<T>> createState() =>
      _CustomAsyncDataTableState<T>();
}

class _CustomAsyncDataTableState<T extends Model>
    extends State<CustomAsyncDataTable<T>>
    with
        TrinaTableDecorator<T>,
        PlatformChecker,
        TextFormatter,
        DefaultResponse {
  late final List<TrinaColumn> columns;
  late final TableController<T> controller;
  late final MobileTableController<T> mobileController;
  List selectedValues = [];
  Map<String, List<HashModel>> selectedItems = {};
  CancelableOperation? searchOperation;
  @override
  void initState() {
    server = context.read<Server>();
    tabManager = context.read<TabManager>();
    columns =
        widget.columns.asMap().entries.map<TrinaColumn>((entry) {
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
        }).toList()..add(
          TrinaColumn(
            title: ' ',
            field: 'model',
            type: TrinaColumnType.text(defaultValue: null),
            hide: widget.renderAction == null,
            frozen: TrinaColumnFrozen.end,
            enableFilterMenuItem: false,
            enableAutoEditing: false,
            enableColumnDrag: false,
            enableSorting: false,
            enableHideColumnMenuItem: false,
            enableContextMenu: false,
            enableEditingMode: false,
            renderer: widget.renderAction == null
                ? null
                : (TrinaColumnRendererContext rendererContext) =>
                      widget.renderAction!(rendererContext.cell.value as T),
            width: widget.renderAction == null
                ? 0
                : widget.actionColumnWidth ?? TrinaGridSettings.columnWidth,
            minWidth: 0,
          ),
        );
    controller = TableController(
      columns: widget.columns,
      trinaController: TrinaGridStateManager(
        columns: columns,
        rows: [],
        gridFocusNode: FocusNode(),
        scroll: TrinaGridScrollController(),
      ),
    );
    mobileController = MobileTableController(
      currentPage: controller.queryRequest.page,
      searchText: controller.queryRequest.searchText,
      sorts: controller.queryRequest.sorts,
      models: controller.models,
    );
    controller.addListener(() {
      mobileController.currentPage = controller.queryRequest.page;
      mobileController.searchText = controller.queryRequest.searchText;
      mobileController.sorts = controller.queryRequest.sorts;
      mobileController.models = controller.models;
      debugPrint('controller changed');
      if (inMobileLayout) {
        mobileFetchData();
      }
    });
    mobileController.addListener(() {
      controller.page = mobileController.currentPage;
      controller.searchText = mobileController.searchText;
      controller.sorts = mobileController.sorts;
      debugPrint('mobile controller change');
      if (inMobileLayout) {
        mobileFetchData();
      }
    });
    super.initState();
  }

  void mobileFetchData() {
    debugPrint(
      'queryRequest params: ${controller.queryRequest.toQueryParam().toString()}',
    );
    mobileController.showLoading();
    widget
        .fetchData(controller.queryRequest)
        .then((response) {
          updateMobileController(response);
          debugPrint(
            'mobile notify models ${mobileController.models.length}  -  ${response.models.length}',
          );
          mobileController.notifyChanged();
        }, onError: (error) => defaultErrorResponse(error: error))
        .whenComplete(mobileController.hideLoading);
  }

  void updateMobileController(DataTableResponse<T> response) {
    mobileController.totalPage = response.totalPage;
    mobileController.models = response.models;
    mobileController.currentPage = controller.queryRequest.page;
    mobileController.searchText = controller.queryRequest.searchText;
    mobileController.sorts = controller.queryRequest.sorts;
  }

  bool inMobileLayout = false;

  bool _containsCheckedValue(Map<String, dynamic> row) {
    return selectedValues.contains(row[widget.primaryKey]);
  }

  QueryOperator filterTypeRemote(filterType) {
    if (filterType is TrinaFilterTypeContains) {
      return QueryOperator.contains;
    } else if (filterType is TrinaFilterTypeLessThanOrEqualTo) {
      return QueryOperator.lessThanOrEqualTo;
    } else if (filterType is TrinaFilterTypeNot) {
      return QueryOperator.not;
    } else if (filterType is TrinaFilterTypeEquals) {
      return QueryOperator.equals;
    } else if (filterType is TrinaFilterTypeGreaterThan) {
      return QueryOperator.greaterThan;
    } else if (filterType is TrinaFilterTypeGreaterThanOrEqualTo) {
      return QueryOperator.greaterThanOrEqualTo;
    } else if (filterType is TrinaFilterTypeLessThan) {
      return QueryOperator.lessThan;
    } else {
      return QueryOperator.equals;
    }
  }

  List<FilterData> remoteFilters() {
    List<FilterData> filter = [];
    for (final row in controller.trinaController.filterRows) {
      filter.add(
        ComparisonFilterData(
          key: row.cells['column']!.value,
          operator: filterTypeRemote(row.cells['type']!.value),
          value: row.cells['value']!.value.toString(),
        ),
      );
    }
    return filter;
  }

  Future<List<HashModel>?> showRemoteOptions({
    required String path,
    required String attributeKey,
    String searchText = '',
    String title = '',
  }) {
    final itemBefore = selectedItems[title] ?? [];
    return showDialog<List<HashModel>>(
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
              ),
            ],
          ),
          content: Column(
            children: [
              SizedBox(
                width: 400,
                child: AsyncDropdownMultiple<HashModel>(
                  path: path,
                  width: 400,
                  selecteds: itemBefore,
                  textOnSearch: (item) => _itemText(item, attributeKey),
                  modelClass: HashModelClass(),
                  onChanged: (List<HashModel> items) =>
                      selectedItems[title] = items,
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pop(selectedItems[title]),
                child: Text('Submit'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _itemText(HashModel item, String attributeKey) {
    final key = attributeKey.split('.').last;
    return "${item.id.toString()} - ${item[key].toString()}";
  }

  void displayShowHideColumn(TrinaGridStateManager stateManager) {
    stateManager.showSetColumnsPopup(context);
  }

  CancelToken? cancelToken;
  final _menuController = MenuController();
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraint) {
        if (constraint.maxWidth > 480) {
          inMobileLayout = false;
          controller.isMobileLayout = false;
          return trinaGrid(colorScheme);
        } else {
          inMobileLayout = true;
          controller.isMobileLayout = true;
          if (!isLoaded && widget.onLoaded != null) {
            isLoaded = true;
            widget.onLoaded!(controller);
          }
          return MobileTable<T>(
            controller: mobileController,
            columns: widget.columns,
            renderAction: widget.renderAction,
          );
        }
      },
    );
  }

  bool isLoaded = false;

  Widget trinaGrid(ColorScheme colorScheme) {
    return TrinaGrid(
      columns: controller.trinaColumns,
      rows: controller.trinaController.rows,
      onLoaded: (TrinaGridOnLoadedEvent event) {
        final source = event.stateManager;
        source.setShowColumnFilter(widget.showFilter);
        source.setShowColumnFooter(widget.showSummary);
        source.columnFooterHeight = TrinaTableDecorator.summaryHeight;
        source.eventManager!.listener((event) {
          if (event is TrinaGridChangeColumnFilterEvent) {
            final columType = event.column.type;
            if (columType is TrinaColumnTypeModelSelect) {
              showRemoteOptions(
                searchText: event.filterValue,
                title: event.column.title,
                path: columType.path,
                attributeKey: columType.attributeKey,
              ).then((items) {
                if (items == null) return;
                final filterValue = items
                    .map<String>((item) => item.id.toString())
                    .toList()
                    .join(',');
                List<TrinaRow> filterRows = source.filterRows
                    .where(
                      (filterRow) =>
                          filterRow.cells['column']!.value ==
                              event.column.field &&
                          filterRow.cells['type']!.value
                              is TrinaFilterTypeEquals,
                    )
                    .toList();
                if (filterRows.isEmpty) {
                  source.filterRows.add(
                    FilterHelper.createFilterRow(
                      filterType: TrinaFilterTypeEquals(),
                      filterValue: filterValue,
                      columnField: event.column.field,
                    ),
                  );
                } else {
                  filterRows.first.cells['value'] = TrinaCell(
                    value: filterValue,
                  );
                }
                source.setFilterRows(source.filterRows);
                source.refreshTable();
              });
            }
          }
        });
        controller.trinaController = source;

        if (!isLoaded && widget.onLoaded != null) {
          isLoaded = true;
          widget.onLoaded!(controller);
        }
      },
      noRowsWidget: const Text('Data tidak ditemukan'),
      onChanged: (TrinaGridOnChangedEvent event) {
        debugPrint("onchanged ${event.toString()}");
      },
      onSorted: (event) {
        event.column.field;
        if (event.column.sort == .none) {
          controller.queryRequest.sorts = [];
        } else {
          controller.queryRequest.sorts = [
            SortData(
              key: event.column.field,
              isAscending: event.column.sort == .ascending,
            ),
          ];
        }
      },
      mode: TrinaGridMode.selectWithOneTap,
      onSelected: widget.onSelected,
      onRowDoubleTap: widget.onRowDoubleTap,
      onRowChecked: (TrinaGridOnRowCheckedEvent event) {
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
      createHeader: (stateManager) => Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onSubmitted: (value) {
                  controller.searchText = value;
                  stateManager.refreshTable();
                },
                onChanged: (value) {
                  searchOperation?.cancel();
                  searchOperation = CancelableOperation<String>.fromFuture(
                    Future<String>.delayed(Durations.long1, () => value),
                    onCancel: () => debugPrint('search cancel'),
                  );
                  searchOperation!.value.then((value) {
                    controller.searchText = value;
                    controller.refreshTable();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari',
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: SubmenuButton(
              controller: _menuController,
              menuChildren: [
                MenuItemButton(
                  child: const Text('hide/show column'),
                  onPressed: () {
                    displayShowHideColumn(stateManager);
                    _menuController.close();
                  },
                ),
                MenuItemButton(
                  child: const Text('Refresh Data'),
                  onPressed: () {
                    stateManager.refreshTable();
                    _menuController.close();
                  },
                ),
              ],
              child: const Icon(Icons.more_vert),
            ),
          ),
        ],
      ),
      createFooter: (stateManager) {
        return TrinaLazyPagination(
          fetch: (event) async {
            cancelToken?.cancel();
            cancelToken = CancelToken();

            var request = controller.queryRequest;
            request.page = event.page;
            request.cancelToken = cancelToken;
            final sortColumn = event.sortColumn;

            if (sortColumn != null) {
              request.sorts = [
                SortData(
                  key: event.sortColumn!.field,
                  isAscending: event.sortColumn!.sort.isAscending,
                ),
              ];
            }
            request.filters = remoteFilters();
            controller.queryRequest = request;
            debugPrint('desktop fetch');
            return widget.fetchData(request).then(
              (DataTableResponse<T> response) {
                updateMobileController(response);
                return TrinaLazyPaginationResponse(
                  rows: response.models
                      .map<TrinaRow>(
                        (model) => decorateRow(
                          isChecked: _containsCheckedValue(model.toMap()),
                          model: model,
                          tableColumns: columns,
                        ),
                      )
                      .toList(),
                  totalPage: response.totalPage,
                );
              },
              onError: (error) => defaultErrorResponse(
                error: error,
                valueWhenError: DataTableResponse<T>.empty(),
              ),
            );
          },
          stateManager: stateManager,
        );
      },
      configuration: TrinaGridConfiguration(
        columnFilter: TrinaGridColumnFilterConfig(
          filters: [
            TrinaFilterTypeContains(),
            TrinaFilterTypeEquals(),
            TrinaFilterTypeNot(),
            TrinaFilterTypeLessThan(),
            TrinaFilterTypeLessThanOrEqualTo(),
            TrinaFilterTypeGreaterThan(),
            TrinaFilterTypeGreaterThanOrEqualTo(),
          ],
          debounceMilliseconds: 500,
          resolveDefaultColumnFilter: (column, resolver) {
            if (column.type is TrinaColumnTypeModelSelect ||
                column.type is TrinaColumnTypeNumber ||
                column.type is TrinaColumnTypeCurrency) {
              return resolver<TrinaFilterTypeEquals>();
            } else {
              return resolver<TrinaFilterTypeContains>();
            }
          },
        ),
        scrollbar: const TrinaGridScrollbarConfig(
          isAlwaysShown: true,
          thickness: 8,
        ),
        style: TrinaGridStyleConfig(
          borderColor: colorScheme.outline,
          rowColor: colorScheme.secondaryContainer,
          evenRowColor: colorScheme.onPrimary,
        ),
      ),
    );
  }
}
