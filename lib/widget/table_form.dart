import 'package:fe_pos/tool/text_formatter.dart';
import 'package:flutter/material.dart';

class TableForm<T> extends StatelessWidget {
  final List<T> rows;
  final List<TableFormColumn<T>> columns;
  final double? columnSpacing;
  const TableForm({
    super.key,
    required this.columns,
    required this.rows,
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
            columnSpacing: columnSpacing ?? 5,
          );
        } else {
          return MobileTableForm<T>(
            rows: rows,
            columns: columns,
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

  const DesktopTableForm({
    super.key,
    required this.columnSpacing,
    required this.columns,
    required this.rows,
  });

  @override
  State<DesktopTableForm<T>> createState() => _DesktopTableFormState<T>();
}

class _DesktopTableFormState<T> extends State<DesktopTableForm<T>> {
  final _scrollController = ScrollController();
  bool sortAscending = true;
  int? sortColumnIndex;
  @override
  Widget build(BuildContext context) {
    double maxWidth = widget.columns.length * 200.0;
    return Scrollbar(
      thumbVisibility: true,
      trackVisibility: true,
      thickness: 8,
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: .horizontal,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: DataTable(
              // columnWidths: widget.columns
              //     .map<TableColumnWidth>(
              //       (column) => column.desktopWidth ?? FlexColumnWidth(),
              //     )
              //     .toList()
              //     .asMap(),
              sortAscending: sortAscending,
              sortColumnIndex: sortColumnIndex,
              columnSpacing: 10,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 120,
              border: TableBorder.symmetric(
                inside: BorderSide(color: Colors.grey.shade400),
              ),
              columns: widget.columns
                  .map<DataColumn>(
                    (column) => DataColumn(
                      columnWidth: column.desktopWidth ?? FlexColumnWidth(),
                      numeric: column.isNumeric,
                      onSort: column.onSort,
                      label: column.headerBuilder(context),
                    ),
                  )
                  .toList(),
              rows: widget.rows
                  .map<DataRow>(
                    (row) => DataRow(
                      key: ObjectKey(row),
                      cells: widget.columns
                          .map<DataCell>(
                            (column) =>
                                DataCell(column.rowBuilder(context, row)),
                          )
                          .toList(),
                    ),
                  )
                  .toList(),
              // children: [
              //   TableRow(
              //     children: widget.columns
              //         .map<Widget>(
              //           (column) => Padding(
              //             padding: widget.cellPadding,
              //             child: column.headerBuilder(context),
              //           ),
              //         )
              //         .toList(),
              //   ),
              //   ...widget.rows.map(
              //     (row) => TableRow(
              //       key: ObjectKey(row),
              //       children: widget.columns
              //           .map<Widget>(
              //             (column) => Padding(
              //               padding: widget.cellPadding,
              //               child: column.rowBuilder(context, row),
              //             ),
              //           )
              //           .toList(),
              //     ),
              //   ),
              // ],
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
  bool isNumeric;
  void Function(int, bool)? onSort;
  TableColumnWidth? desktopWidth;
  RenderHeader headerBuilder;
  RenderBy<T> rowBuilder;

  TableFormColumn({
    required this.name,
    String? title,
    this.onSort,
    this.isNumeric = false,
    this.desktopWidth,
    required this.rowBuilder,
    RenderHeader? headerBuilder,
  }) : headerBuilder = headerBuilder ?? defaultHeaderBuilder,
       title = title ?? name;

  static RenderHeader defaultHeaderBuilder = (context) => const SizedBox();
}
