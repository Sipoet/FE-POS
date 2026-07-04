import 'package:collection/collection.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class TableForm<T> extends StatelessWidget {
  final List<T> rows;
  final List<TableFormColumn<T>> columns;
  final double? columnSpacing;
  final bool? showSearch;
  final bool? isRowReorderable;
  final TableFormColumn<T>? actionColumn;
  final Function(List<T> rows, int fromIndex, int toIndex)? onRowReorder;
  const TableForm({
    super.key,
    required this.columns,
    required this.rows,
    this.showSearch,
    this.onRowReorder,
    this.isRowReorderable,
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
            isRowReorderable: isRowReorderable ?? false,
            columns: columns,
            onRowReorder: onRowReorder,
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
  final bool isRowReorderable;
  final Function(List<T> rows, int fromIndex, int toIndex)? onRowReorder;
  const DesktopTableForm({
    super.key,
    required this.columnSpacing,
    required this.columns,
    required this.rows,
    this.isRowReorderable = false,
    this.actionColumn,
    this.onRowReorder,
  });

  @override
  State<DesktopTableForm<T>> createState() => _DesktopTableFormState<T>();
}

class _DesktopTableFormState<T> extends State<DesktopTableForm<T>> {
  final _scrollController = ScrollController();
  bool sortAscending = true;
  int? sortColumnIndex;
  List<TableFormColumn<T>> columns = [];

  @override
  void initState() {
    if (widget.actionColumn != null) {
      columns = widget.columns + [widget.actionColumn!];
    }
    columns = widget.columns;
    super.initState();
  }

  void moveRows(int fromIndex, int toIndex) {
    final data = widget.rows[fromIndex];
    setState(() {
      widget.rows.removeAt(fromIndex);
      widget.rows.insert(toIndex, data);
      widget.onRowReorder?.call(widget.rows, fromIndex, toIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    double minWidth = columns.map<double>((e) => e.width).sum;
    if (widget.isRowReorderable) {
      minWidth += 35;
    }
    final padding = MediaQuery.of(context).padding;
    final maxWidth = <double>[
      minWidth,
      MediaQuery.sizeOf(context).width - padding.left - padding.right - 60,
    ].max;
    final double height = 70;
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
      child: Scrollbar(
        thumbVisibility: true,
        trackVisibility: true,
        thickness: 8,
        controller: _scrollController,
        child: SingleChildScrollView(
          scrollDirection: .horizontal,
          controller: _scrollController,
          child: SizedBox(
            width: minWidth,
            height: (widget.rows.length + 1) * 51,
            child: Column(
              children: [
                Row(
                  children: [
                    if (widget.isRowReorderable)
                      Container(
                        width: 35,
                        height: height,
                        decoration: BoxDecoration(border: Border.all()),
                      ),
                    ...columns.map<Widget>(
                      (column) => Stack(
                        children: [
                          Container(
                            width: column.width,
                            height: height,
                            decoration: BoxDecoration(border: Border.all()),
                            padding: .all(widget.columnSpacing),
                            child: column.headerBuilder(context),
                          ),
                          if (column.isColumnResizeable == true)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onHorizontalDragUpdate: (detail) {
                                  final beforeWidth = column.width;
                                  setState(() {
                                    column.width +=
                                        (detail.localPosition.dx -
                                        column.beforePosition);
                                    if (column.width < column.minWidth) {
                                      column.width = column.minWidth;
                                    }
                                    if (column.maxWidth != null &&
                                        column.width > column.maxWidth!) {
                                      column.width = column.maxWidth!;
                                    }
                                    if (column.width != beforeWidth) {
                                      column.beforePosition =
                                          detail.localPosition.dx;
                                    }
                                  });
                                },
                                onHorizontalDragEnd: (detail) {
                                  debugPrint("end:${detail.localPosition.dx}");
                                  column.beforePosition = 0;
                                },
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.resizeColumn,
                                  child: Icon(
                                    PhosphorIconsRegular.splitHorizontal,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                Flexible(
                  child: ReorderableListView(
                    buildDefaultDragHandles: false,
                    onReorder: moveRows,
                    // scrollController: _scrollController,
                    children: widget.rows
                        .mapIndexed(
                          (index, row) => Container(
                            key: ObjectKey(row),
                            padding: .all(0),
                            decoration: BoxDecoration(
                              color: index % 2 == 0
                                  ? Colors.grey.shade100
                                  : Colors.white,
                            ),
                            child: Row(
                              children: [
                                if (widget.isRowReorderable)
                                  Container(
                                    width: 35,
                                    height: height,
                                    decoration: BoxDecoration(
                                      border: Border.all(),
                                    ),
                                    child: ReorderableDragStartListener(
                                      index: index,
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.move,
                                        child: Icon(Icons.drag_indicator),
                                      ),
                                    ),
                                  ),
                                ...columns.map<Widget>(
                                  (column) => Container(
                                    width: column.width,
                                    height: height,
                                    decoration: BoxDecoration(
                                      border: Border.all(),
                                    ),
                                    child: Padding(
                                      padding: .all(widget.columnSpacing),
                                      child: column.rowBuilder(
                                        context,
                                        row,
                                        index,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

    // return Scrollbar(
    //   thumbVisibility: true,
    //   trackVisibility: true,
    //   thickness: 8,
    //   controller: _scrollController,
    //   child: SingleChildScrollView(
    //     controller: _scrollController,
    //     scrollDirection: .horizontal,
    //     child: Container(
    //       constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
    //       child: Padding(
    //         padding: const EdgeInsets.only(bottom: 20),
    //         child: Table(
    //           columnWidths: columns
    //               .map<TableColumnWidth>(
    //                 (column) => FixedColumnWidth(column.width),
    //               )
    //               .toList()
    //               .asMap(),

    //           border: TableBorder.symmetric(
    //             inside: BorderSide(color: Colors.grey.shade400),
    //           ),
    //           children: [
    //             TableRow(
    //               children: [
    //                 if (widget.isRowReorderable) SizedBox.shrink(),
    //                 ...columns.map<Widget>(
    //                   (column) => Padding(
    //                     padding: .all(widget.columnSpacing),
    //                     child: Stack(
    //                       children: [
    //                         column.headerBuilder(context),
    //                         if (column.isColumnResizeable == true)
    //                           Positioned(
    //                             top: 0,
    //                             right: 0,
    //                             child: GestureDetector(
    //                               onHorizontalDragUpdate: (detail) {
    //                                 final beforeWidth = column.width;
    //                                 setState(() {
    //                                   column.width +=
    //                                       (detail.localPosition.dx -
    //                                       column.beforePosition);
    //                                   if (column.width < column.minWidth) {
    //                                     column.width = column.minWidth;
    //                                   }
    //                                   if (column.maxWidth != null &&
    //                                       column.width > column.maxWidth!) {
    //                                     column.width = column.maxWidth!;
    //                                   }
    //                                   if (column.width != beforeWidth) {
    //                                     column.beforePosition =
    //                                         detail.localPosition.dx;
    //                                   }
    //                                 });
    //                               },
    //                               onHorizontalDragEnd: (detail) {
    //                                 debugPrint(
    //                                   "end:${detail.localPosition.dx}",
    //                                 );
    //                                 column.beforePosition = 0;
    //                               },
    //                               child: MouseRegion(
    //                                 cursor: SystemMouseCursors.resizeColumn,
    //                                 child: Icon(
    //                                   PhosphorIconsRegular.splitHorizontal,
    //                                   size: 15,
    //                                 ),
    //                               ),
    //                             ),
    //                           ),
    //                       ],
    //                     ),
    //                   ),
    //                 ),
    //               ],
    //             ),
    //             ...widget.rows.mapIndexed(
    //               (index, row) => TableRow(
    //                 decoration: BoxDecoration(
    //                   color: index % 2 == 0
    //                       ? Colors.grey.shade100
    //                       : Colors.white,
    //                 ),
    //                 key: ObjectKey(row),
    //                 children: [
    //                   if (widget.isRowReorderable)
    //                     Draggable<int>(
    //                       data: index,
    //                       feedback: Row(children: [Icon(Icons.drag_indicator)]),
    //                       child: DragTarget(
    //                         builder: (context, accepted, rejected) =>
    //                             Icon(Icons.drag_indicator),
    //                       ),
    //                     ),
    //                   ...columns
    //                       .map<Widget>(
    //                         (column) => Padding(
    //                           padding: .all(widget.columnSpacing),
    //                           child: column.rowBuilder(context, row, index),
    //                         ),
    //                       )
    //                       .toList(),
    //                 ],
    //               ),
    //             ),
    //           ],
    //         ),
    //       ),
    //     ),
    //   ),
    // );
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
                            widget.cardAction!.call(context, row, index),
                          ],
                        ),
                      ),
                      const Divider(),
                    ],
                  ),
                ...widget.columns.map<Widget>(
                  (column) => ListTile(
                    title: Text(column.title, style: TextFormatter.labelStyle),
                    subtitle: column.rowBuilder(context, row, index),
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

typedef RenderBy<T> =
    Widget Function(BuildContext context, T object, int index);
typedef RenderHeader = Widget Function(BuildContext context);

class TableFormColumn<T> {
  String? name;
  String title;
  bool isNumeric;
  double width;
  double minWidth;
  double? maxWidth;
  final bool? isColumnResizeable;
  final bool? isColumnReorderable;
  double beforePosition = 0;
  void Function(int, bool)? onSort;
  FixedColumnWidth? desktopWidth;
  RenderHeader headerBuilder;
  RenderBy<T> rowBuilder;

  TableFormColumn({
    this.name,
    this.title = '',
    this.onSort,
    this.isNumeric = false,
    this.isColumnResizeable,
    this.isColumnReorderable,
    this.desktopWidth,
    double? width,
    this.minWidth = 50,
    this.maxWidth,
    required this.rowBuilder,
    RenderHeader? headerBuilder,
  }) : headerBuilder = headerBuilder ?? defaultHeaderBuilder,
       width = desktopWidth?.value ?? 200;

  static RenderHeader defaultHeaderBuilder = (context) => const SizedBox();
}
