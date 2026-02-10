import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/mobile_table.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/tool/table_decorator.dart';
export 'package:trina_grid/trina_grid.dart';
export 'package:fe_pos/tool/table_decorator.dart';
import 'package:trina_grid/trina_grid.dart';
import 'package:provider/provider.dart';

typedef OnLoadedCallBack<T extends Model> =
    void Function(SyncTableController<T> stateManager);
typedef OnRowCheckedCallback = void Function(TrinaGridOnRowCheckedEvent event);
typedef OnSelectedCallback = void Function(TrinaGridOnSelectedEvent event);
typedef OnRowDoubleTapCallback =
    void Function(TrinaGridOnRowDoubleTapEvent event);

class SyncDataTable<T extends Model> extends StatefulWidget {
  final int fixedLeftColumns;
  final List<Widget>? actions;
  final bool showCheckboxColumn;
  final bool showSummary;
  final List<T>? rows;
  final List<TableColumn> columns;
  final Map<String, List<Enum>> enums;
  final OnLoadedCallBack<T>? onLoaded;
  final OnRowCheckedCallback? onRowChecked;
  final OnSelectedCallback? onSelected;
  final OnRowDoubleTapCallback? onRowDoubleTap;
  final double? actionColumnWidth;
  final bool showFilter;
  final bool isPaginated;
  final Widget Function(T model)? renderAction;
  final void Function(QueryRequest queryRequest)? onQueryChanged;

  const SyncDataTable({
    super.key,
    this.actions,
    this.onLoaded,
    this.renderAction,
    this.actionColumnWidth,
    this.showFilter = true,
    this.onQueryChanged,
    List<TableColumn>? columns,
    this.rows,
    this.isPaginated = false,
    this.enums = const {},
    this.onRowChecked,
    this.onRowDoubleTap,
    this.onSelected,
    this.showSummary = false,
    this.showCheckboxColumn = false,
    this.fixedLeftColumns = 0,
  }) : columns = columns ?? const [];

  @override
  State<SyncDataTable<T>> createState() => _SyncDataTableState<T>();
}

class _SyncDataTableState<T extends Model> extends State<SyncDataTable<T>>
    with TrinaTableDecorator<T>, PlatformChecker, TextFormatter {
  List<TrinaRow>? get rows => (widget.rows ?? [])
      .map<TrinaRow>((row) => decorateRow(model: row, tableColumns: columns))
      .toList();
  final _menuController = MenuController();
  late final SyncTableController<T> controller;
  bool isLoaded = false;
  bool isMobileLayout = false;
  CancelableOperation? searchOperation;

  List<TrinaColumn> get columns =>
      widget.columns.asMap().entries.map<TrinaColumn>((entry) {
        int index = entry.key;
        TableColumn tableColumn = entry.value;
        return decorateColumn(
          tableColumn,
          tabManager: tabManager,
          listEnumValues: widget.enums[tableColumn.name],
          showFilter: widget.showFilter,
          isFrozen: index < widget.fixedLeftColumns,
        );
      }).toList()..add(
        TrinaColumn(
          title: ' ',
          field: 'model',
          enableFilterMenuItem: false,
          enableAutoEditing: false,
          enableColumnDrag: false,
          enableSorting: false,
          enableHideColumnMenuItem: false,
          enableContextMenu: false,
          enableEditingMode: false,
          type: TrinaColumnType.text(defaultValue: null),
          hide: widget.renderAction == null,
          frozen: TrinaColumnFrozen.end,
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

  @override
  void initState() {
    tabManager = context.read<TabManager>();
    controller = SyncTableController(
      columns: widget.columns,
      models: widget.rows ?? [],
      trinaController: TrinaGridStateManager(
        columns: columns,
        rows: rows ?? [],
        gridFocusNode: FocusNode(),
        scroll: TrinaGridScrollController(),
      ),
    );
    controller.initMobileController();
    controller.addListener(() {
      debugPrint('controller changed');
      if (widget.onQueryChanged != null && controller.searchTextChanged) {
        widget.onQueryChanged!(controller.queryRequest);
        controller.searchTextChanged = false;
      }
    });
    super.initState();
  }

  void displayShowHideColumn(TrinaGridStateManager stateManager) {
    stateManager.showSetColumnsPopup(context);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('sync build models ${controller.models.length}');
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraint) {
        if (constraint.maxWidth > 480) {
          isMobileLayout = false;
          controller.isMobileLayout = false;
          return trinaGrid(colorScheme);
        } else {
          isMobileLayout = true;
          controller.isMobileLayout = true;
          if (!isLoaded && widget.onLoaded != null) {
            isLoaded = true;
            widget.onLoaded!(controller);
          }
          return MobileTable<T>(
            controller: controller.mobileController,
            columns: widget.columns,
            renderAction: widget.renderAction,
          );
        }
      },
    );
  }

  List<T> paginatedRows({
    required List<T> models,
    int page = 1,
    int limit = 10,
  }) {
    int start = (page - 1) * limit;
    int end = [page * limit, models.length].min;
    return models.sublist(start, end);
  }

  Widget trinaGrid(ColorScheme colorScheme) {
    return TrinaGrid(
      columns: controller.trinaColumns,
      rows: controller.trinaController.rows,
      onLoaded: (TrinaGridOnLoadedEvent event) {
        final stateManager = event.stateManager;
        stateManager.setShowColumnFilter(widget.showFilter);
        stateManager.setShowColumnFooter(widget.showSummary);
        setState(() {
          stateManager.columnFooterHeight = 150.0;
        });
        controller.trinaController = stateManager;
        if (!isLoaded && widget.onLoaded != null) {
          isLoaded = true;
          widget.onLoaded!(controller);
        }
      },
      onSorted: (event) {
        event.column.field;
        if (event.column.sort == .none) {
          controller.sorts = [];
        } else {
          controller.sorts = [
            SortData(
              key: event.column.field,
              isAscending: event.column.sort == .ascending,
            ),
          ];
        }
      },
      noRowsWidget: const Text('Data tidak ditemukan'),
      onChanged: (TrinaGridOnChangedEvent event) {
        debugPrint(event.toString());
      },
      mode: TrinaGridMode.selectWithOneTap,
      onSelected: widget.onSelected,
      onRowDoubleTap: widget.onRowDoubleTap,
      onRowChecked: widget.onRowChecked,
      createHeader: (stateManager) => Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: widget.onQueryChanged == null
                  ? SizedBox()
                  : TextFormField(
                      onFieldSubmitted: (value) {
                        controller.searchText = value;
                        controller.page = 1;
                      },
                      onChanged: (value) {
                        searchOperation?.cancel();
                        searchOperation =
                            CancelableOperation<String>.fromFuture(
                              Future<String>.delayed(
                                Durations.long1,
                                () => value,
                              ),
                              onCancel: () => debugPrint('search cancel'),
                            );
                        searchOperation!.value.then((value) {
                          controller.searchText = value;
                          controller.page = 1;
                        });
                      },
                      initialValue: controller.queryRequest.searchText,
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
        return TrinaPagination(stateManager, pageSizeToMove: 1);
      },
      configuration: TrinaGridConfiguration(
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

class SyncTableController<T extends Model> extends ChangeNotifier {
  TrinaGridStateManager trinaController;
  late MobileTableController<T> mobileController;
  List<T> models = [];
  List<TableColumn> columns = [];
  QueryRequest queryRequest;
  bool isMobileLayout = false;
  bool searchTextChanged = false;
  // table rows per page
  int rowsPerPage;

  List<TrinaColumn> get trinaColumns => trinaController.columns.toList();
  TrinaDeco get decorator => TrinaDeco();

  SyncTableController({
    TrinaGridStateManager? trinaController,
    this.rowsPerPage = 10,
    QueryRequest? queryRequest,
    List<T>? models,
    List<TableColumn>? columns,
  }) : models = models ?? [],
       columns = columns ?? [],
       trinaController =
           trinaController ??
           TrinaGridStateManager(
             columns: [],
             rows: [],
             gridFocusNode: FocusNode(),
             scroll: TrinaGridScrollController(),
           ),
       queryRequest = queryRequest ?? QueryRequest();
  void initMobileController() {
    mobileController = MobileTableController(models: models)
      ..addListener(() {
        page = mobileController.currentPage;
        searchText = mobileController.searchText;
        sorts = mobileController.sorts;
      });
  }

  void setModels(List<T> value) {
    if (models.equals(value)) {
      return;
    }
    models.clear();
    models.addAll(value);
    trinaController.setModels(value);
    _refreshMobileModel();
    notifyListeners();
  }

  set searchText(String value) {
    if (queryRequest.searchText == value) {
      return;
    }
    debugPrint('search change from ${queryRequest.searchText} to $value');
    queryRequest.searchText = value;
    searchTextChanged = true;
    mobileController.searchText = value;

    notifyListeners();
  }

  set include(List<String> value) {
    final a = queryRequest.include.toSet();
    final b = value.toSet();
    if (a.containsAll(b) && b.containsAll(a)) {
      return;
    }
    queryRequest.include = value;
    notifyListeners();
  }

  set page(int value) {
    if (queryRequest.page == value) {
      return;
    }
    queryRequest.page = value;
    trinaController.setPage(value);
    mobileController.currentPage = value;
    _refreshMobileModel();
    notifyListeners();
  }

  void _refreshMobileModel() {
    mobileController.totalPage =
        (models.length.toDouble() / rowsPerPage.toDouble()).ceil();
    mobileController.models = paginatedRows(
      models: models,
      page: mobileController.currentPage,
      limit: rowsPerPage,
    );
  }

  set sorts(List<SortData> value) {
    if (queryRequest.sorts.equals(value)) {
      return;
    }
    queryRequest.sorts = value;
    for (final sort in queryRequest.sorts) {
      debugPrint('sort set ${sort.toString()}');
      sortByFieldName(sort.key, isAscending: sort.isAscending);
    }

    notifyListeners();
  }

  K? modelFromCheckEvent<K extends Model>(TrinaGridOnRowCheckedEvent event) =>
      event.row?.cells[modelKey]?.value as K;

  void appendModel(T model) {
    models = models.toList();
    models.add(model);
    trinaController.appendRows([
      decorator.decorateRow(model: model, tableColumns: trinaColumns),
    ]);
    mobileController.addModel(model);
    _refreshMobileModel();
    notifyListeners();
  }

  void setTableColumns(
    List<TableColumn> tableColumns, {
    int fixedLeftColumns = 0,
    bool showFilter = false,
    required TabManager tabManager,
  }) {
    columns = tableColumns;
    trinaController.setTableColumns(
      columns,
      fixedLeftColumns: fixedLeftColumns,
      showFilter: showFilter,
      tabManager: tabManager,
    );
    // notifyListeners();
  }

  void refreshTable() {
    if (isMobileLayout) {
      mobileController.notifyChanged(force: true);
    } else {
      trinaController.eventManager?.addEvent(
        TrinaGridChangeColumnSortEvent(
          column: trinaController.columns.first,
          oldSort: TrinaColumnSort.none,
        ),
      );
    }
    notifyListeners();
  }

  void sortByFieldName(String fieldName, {bool isAscending = true}) {
    final column = findColumn(fieldName);
    if (column == null) {
      debugPrint('field $fieldName tidak ditemukan');
      return;
    }
    if (isAscending) {
      sortAscending(column);
    } else {
      sortDescending(column);
    }
  }

  TableColumn? findColumn(fieldName) {
    return columns.firstWhereOrNull((e) => e.name == fieldName);
  }

  TrinaColumn? findTrinaColumn(String fieldName) {
    return trinaColumns.firstWhereOrNull((e) => e.field == fieldName);
  }

  void sortAscending(TableColumn column) {
    final trinaColumn = findTrinaColumn(column.name);
    if (trinaColumn != null) {
      trinaController.sortAscending(trinaColumn);
    }

    queryRequest.sorts = [SortData(key: column.name, isAscending: true)];
    mobileController.sorts = queryRequest.sorts;
    _refreshMobileModel();
    notifyListeners();
  }

  void sortDescending(TableColumn column) {
    final trinaColumn = findTrinaColumn(column.name);
    if (trinaColumn != null) {
      trinaController.sortDescending(trinaColumn);
    }
    queryRequest.sorts = [SortData(key: column.name, isAscending: false)];
    mobileController.sorts = queryRequest.sorts;
    _refreshMobileModel();
    notifyListeners();
  }

  List<T> paginatedRows({
    required List<T> models,
    int page = 1,
    int limit = 10,
  }) {
    int start = (page - 1) * limit;
    int end = [page * limit, models.length].min;
    return models.sublist(start, end);
  }

  ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  void setShowLoading(bool result) {
    isLoading.value = result;
    trinaController.setShowLoading(result);
    mobileController.loader.value = result;
    // notifyListeners();
  }

  void removeAllRows({bool notify = true}) {
    models = models.toList();
    models.clear();
    trinaController.removeAllRows(notify: notify);
    _refreshMobileModel();

    if (notify) {
      notifyListeners();
    }
  }
}
