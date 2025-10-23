import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/tool/table_decorator.dart';
export 'package:fe_pos/tool/table_decorator.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';
export 'package:pluto_grid/pluto_grid.dart';

typedef OnLoadedCallBack = void Function(PlutoGridStateManager stateManager);
typedef OnRowCheckedCallback = void Function(PlutoGridOnRowCheckedEvent event);
typedef OnSelectedCallback = void Function(PlutoGridOnSelectedEvent event);
typedef OnRowDoubleTapCallback = void Function(
    PlutoGridOnRowDoubleTapEvent event);

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
  final bool showFilter;
  final bool isPaginated;

  const SyncDataTable({
    super.key,
    this.actions,
    this.onLoaded,
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
    with PlutoTableDecorator, PlatformChecker, TextFormatter {
  List<PlutoRow> get rows => widget.rows
      .map<PlutoRow>(
          (row) => decorateRow(model: row, tableColumns: widget.columns))
      .toList();

  List<PlutoColumn> get columns =>
      widget.columns.asMap().entries.map<PlutoColumn>((entry) {
        int index = entry.key;
        TableColumn tableColumn = entry.value;
        return decorateColumn(
          tableColumn,
          tabManager: tabManager,
          listEnumValues: widget.enums[tableColumn.name],
          showFilter: widget.showFilter,
          isFrozen: index < widget.fixedLeftColumns,
        );
      }).toList();

  @override
  void initState() {
    tabManager = context.read<TabManager>();
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
        setState(() {
          stateManager.columnFooterHeight = 150.0;
        });
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
      createFooter: (stateManager) {
        return PlutoPagination(
          stateManager,
          pageSizeToMove: 1,
        );
      },
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
