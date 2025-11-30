import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/tool/table_decorator.dart';
export 'package:trina_grid/trina_grid.dart';
export 'package:fe_pos/tool/table_decorator.dart';
import 'package:trina_grid/trina_grid.dart';
import 'package:provider/provider.dart';

typedef OnLoadedCallBack = void Function(TrinaGridStateManager stateManager);
typedef OnRowCheckedCallback = void Function(TrinaGridOnRowCheckedEvent event);
typedef OnSelectedCallback = void Function(TrinaGridOnSelectedEvent event);
typedef OnRowDoubleTapCallback = void Function(
    TrinaGridOnRowDoubleTapEvent event);

class SyncDataTable<T extends Model> extends StatefulWidget {
  final int fixedLeftColumns;
  final List<Widget>? actions;
  final bool showCheckboxColumn;
  final bool showSummary;
  final List<T> rows;
  final List<TableColumn> columns;
  final Map<String, List<Enum>> enums;
  final OnLoadedCallBack? onLoaded;
  final OnRowCheckedCallback? onRowChecked;
  final OnSelectedCallback? onSelected;
  final OnRowDoubleTapCallback? onRowDoubleTap;
  final double? actionColumnWidth;
  final bool showFilter;
  final bool isPaginated;
  final Widget Function(T model)? renderAction;

  const SyncDataTable({
    super.key,
    this.actions,
    this.onLoaded,
    this.renderAction,
    this.actionColumnWidth,
    this.showFilter = true,
    List<TableColumn>? columns,
    List<T>? rows,
    this.isPaginated = false,
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
  State<SyncDataTable<T>> createState() => _SyncDataTableState<T>();
}

class _SyncDataTableState<T extends Model> extends State<SyncDataTable<T>>
    with TrinaTableDecorator, PlatformChecker, TextFormatter {
  List<TrinaRow> get rows => widget.rows
      .map<TrinaRow>((row) => decorateRow(model: row, tableColumns: columns))
      .toList();

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
      }).toList()
        ..add(TrinaColumn(
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
            minWidth: 0));

  @override
  void initState() {
    tabManager = context.read<TabManager>();
    super.initState();
  }

  void displayShowHideColumn(TrinaGridStateManager stateManager) {
    stateManager.showSetColumnsPopup(context);
  }

  final _menuController = MenuController();
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TrinaGrid(
      columns: columns,
      rows: rows,
      onLoaded: (TrinaGridOnLoadedEvent event) {
        final stateManager = event.stateManager;
        stateManager.setShowColumnFilter(widget.showFilter);
        stateManager.setShowColumnFooter(widget.showSummary);
        setState(() {
          stateManager.columnFooterHeight = 150.0;
        });
        if (widget.onLoaded is Function) {
          widget.onLoaded!(stateManager);
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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
              width: 50,
              child: SubmenuButton(
                  controller: _menuController,
                  menuChildren: [
                    MenuItemButton(
                      child: const Text('hide/show column'),
                      onPressed: () {
                        _menuController.close();
                        displayShowHideColumn(stateManager);
                      },
                    ),
                  ],
                  child: const Icon(Icons.more_vert)))
        ],
      ),
      createFooter: (stateManager) {
        return TrinaPagination(
          stateManager,
          pageSizeToMove: 1,
        );
      },
      configuration: TrinaGridConfiguration(
          scrollbar: const TrinaGridScrollbarConfig(
            isAlwaysShown: true,
          ),
          style: TrinaGridStyleConfig(
              borderColor: colorScheme.outline,
              rowColor: colorScheme.secondaryContainer,
              evenRowColor: colorScheme.onPrimary)),
    );
  }
}
