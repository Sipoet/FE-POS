import 'package:fe_pos/tool/text_formatter.dart';
import 'package:flutter/material.dart';

class TableForm<T> extends StatelessWidget {
  final List<T> rows;
  final List<TableFormColumn<T>> columns;
  final EdgeInsets? cellPadding;
  const TableForm({
    super.key,
    required this.columns,
    required this.rows,
    this.cellPadding,
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
            cellPadding: cellPadding ?? const .all(5),
          );
        } else {
          return MobileTableForm<T>(
            rows: rows,
            columns: columns,
            cellPadding: cellPadding ?? const .all(5),
          );
        }
      },
    );
  }
}

class DesktopTableForm<T> extends StatefulWidget {
  final List<T> rows;
  final List<TableFormColumn<T>> columns;
  final EdgeInsets cellPadding;
  const DesktopTableForm({
    super.key,
    this.cellPadding = const .all(5),
    required this.columns,
    required this.rows,
  });

  @override
  State<DesktopTableForm<T>> createState() => _DesktopTableFormState<T>();
}

class _DesktopTableFormState<T> extends State<DesktopTableForm<T>> {
  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: widget.columns
          .map<TableColumnWidth>(
            (column) => column.desktopWidth ?? FlexColumnWidth(),
          )
          .toList()
          .asMap(),
      border: TableBorder.symmetric(inside: BorderSide()),
      children: [
        TableRow(
          children: widget.columns
              .map<Widget>(
                (column) => Padding(
                  padding: widget.cellPadding,
                  child: column.headerBuilder(context),
                ),
              )
              .toList(),
        ),
        ...widget.rows.map(
          (row) => TableRow(
            key: ObjectKey(row),
            children: widget.columns
                .map<Widget>(
                  (column) => Padding(
                    padding: widget.cellPadding,
                    child: column.rowBuilder(context, row),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class MobileTableForm<T> extends StatefulWidget {
  final List<T> rows;
  final List<TableFormColumn<T>> columns;
  final EdgeInsets cellPadding;
  const MobileTableForm({
    super.key,
    required this.columns,
    required this.rows,
    this.cellPadding = const .all(5),
  });

  @override
  State<MobileTableForm<T>> createState() => _MobileTableFormState<T>();
}

class _MobileTableFormState<T> extends State<MobileTableForm<T>> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.rows
          .map<Widget>(
            (row) => Card(
              child: Column(
                children: widget.columns
                    .map<Widget>(
                      (column) => ListTile(
                        title: Text(
                          column.title,
                          style: TextFormatter.labelStyle,
                        ),
                        subtitle: column.rowBuilder(context, row),
                      ),
                    )
                    .toList(),
              ),
            ),
          )
          .toList(),
    );
  }
}

typedef RenderBy<T> = Widget Function(BuildContext context, T object);
typedef RenderHeader = Widget Function(BuildContext context);

class TableFormColumn<T> {
  String name;
  String title;
  TableColumnWidth? desktopWidth;
  RenderHeader headerBuilder;
  RenderBy<T> rowBuilder;

  TableFormColumn({
    required this.name,
    String? title,
    this.desktopWidth,
    required this.rowBuilder,
    RenderHeader? headerBuilder,
  }) : headerBuilder = headerBuilder ?? defaultHeaderBuilder,
       title = title ?? name;

  static RenderHeader defaultHeaderBuilder = (context) => const SizedBox();
}
