import 'package:collection/collection.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:flutter/material.dart';

class TableForm<T> extends StatelessWidget {
  final List<T> rows;
  final List<TableFormColumn<T>> columns;
  final double? columnSpacing;
  final TableFormColumn<T>? actionColumn;
  const TableForm({
    super.key,
    required this.columns,
    required this.rows,
    this.actionColumn,
    this.columnSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraint) {
        final size = MediaQuery.of(context).size;
        if (size.width > 600) {
          return DesktopTableForm<T>(
            rows: rows,
            columns: columns,
            actionColumn: actionColumn,
            columnSpacing: columnSpacing ?? 5,
          );
        } else {
          return MobileTableForm<T>(
            rows: rows,
            columns: columns,
            mobileHeader: actionColumn?.headerBuilder(context),
            cardAction: actionColumn?.rowBuilder,
            cellPadding: .all(columnSpacing ?? 5),
          );
        }
      },
    );
  }
}

class DesktopTableForm<T> extends StatefulWidget {
  final List<T> rows;
  final List<TableFormColumn<T>> columns;
  final double columnSpacing;
  final TableFormColumn<T>? actionColumn;
  const DesktopTableForm({
    super.key,
    required this.columnSpacing,
    required this.columns,
    required this.rows,
    this.actionColumn,
  });

  @override
  State<DesktopTableForm<T>> createState() => _DesktopTableFormState<T>();
}

class _DesktopTableFormState<T> extends State<DesktopTableForm<T>> {
  final _scrollController = ScrollController();
  bool sortAscending = true;
  int? sortColumnIndex;
  List<TableFormColumn<T>> get columns {
    if (widget.actionColumn != null) {
      return widget.columns + [widget.actionColumn!];
    }
    return widget.columns;
  }

  @override
  Widget build(BuildContext context) {
    final minWidth = columns.length * 200.0;
    final padding = MediaQuery.of(context).padding;
    final maxWidth = <double>[
      minWidth,
      MediaQuery.sizeOf(context).width - padding.left - padding.right - 60,
    ].max;
    return Scrollbar(
      thumbVisibility: true,
      trackVisibility: true,
      thickness: 8,
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: .horizontal,
        child: Container(
          constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Table(
              columnWidths: columns
                  .map<TableColumnWidth>(
                    (column) => column.desktopWidth ?? FlexColumnWidth(),
                  )
                  .toList()
                  .asMap(),

              border: TableBorder.symmetric(
                inside: BorderSide(color: Colors.grey.shade400),
              ),
              children: [
                TableRow(
                  children: columns
                      .map<Widget>(
                        (column) => Padding(
                          padding: .all(widget.columnSpacing),
                          child: column.headerBuilder(context),
                        ),
                      )
                      .toList(),
                ),
                ...widget.rows.map(
                  (row) => TableRow(
                    key: ObjectKey(row),
                    children: columns
                        .map<Widget>(
                          (column) => Padding(
                            padding: .all(widget.columnSpacing),
                            child: column.rowBuilder(context, row),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MobileTableForm<T> extends StatefulWidget {
  final List<T> rows;
  final List<TableFormColumn<T>> columns;
  final EdgeInsets cellPadding;
  final Widget? mobileHeader;
  final RenderBy<T>? cardAction;
  const MobileTableForm({
    super.key,
    required this.columns,
    required this.rows,
    this.mobileHeader,
    this.cardAction,
    this.cellPadding = const .all(5),
  });

  @override
  State<MobileTableForm<T>> createState() => _MobileTableFormState<T>();
}

class _MobileTableFormState<T> extends State<MobileTableForm<T>> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.mobileHeader != null)
          Column(children: [widget.mobileHeader!, const Divider()]),
        ...widget.rows.mapIndexed<Widget>(
          (index, row) => Card(
            key: ObjectKey(row),
            child: Column(
              children: [
                if (widget.cardAction != null)
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: .spaceBetween,
                          children: [
                            Text(
                              'Baris ${index + 1}',
                              style: TextFormatter.labelStyle,
                            ),
                            widget.cardAction!.call(context, row),
                          ],
                        ),
                      ),
                      const Divider(),
                    ],
                  ),
                ...widget.columns.map<Widget>(
                  (column) => ListTile(
                    title: Text(column.title, style: TextFormatter.labelStyle),
                    subtitle: column.rowBuilder(context, row),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

typedef RenderBy<T> = Widget Function(BuildContext context, T object);
typedef RenderHeader = Widget Function(BuildContext context);

class TableFormColumn<T> {
  String? name;
  String title;
  bool isNumeric;
  void Function(int, bool)? onSort;
  TableColumnWidth? desktopWidth;
  RenderHeader headerBuilder;
  RenderBy<T> rowBuilder;

  TableFormColumn({
    this.name,
    this.title = '',
    this.onSort,
    this.isNumeric = false,
    this.desktopWidth,
    required this.rowBuilder,
    RenderHeader? headerBuilder,
  }) : headerBuilder = headerBuilder ?? defaultHeaderBuilder;

  static RenderHeader defaultHeaderBuilder = (context) => const SizedBox();
}
