import 'package:collection/collection.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class TableForm<T> extends StatelessWidget {
  final List<T> rows;
  final List<TableFormColumn<T>> columns;
  final EdgeInsets? columnSpacing;
  final bool? showSearch;
  final bool? isRowReorderable;
  final double? desktopRowHeight;
  final TableFormColumn<T>? actionColumn;
  final Function(List<T> rows, int fromIndex, int toIndex)? onRowReorder;
  const TableForm({
    super.key,
    required this.columns,
    required this.rows,
    this.showSearch,
    this.onRowReorder,
    this.desktopRowHeight,
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
            rowHeight: desktopRowHeight ?? 70,
            onRowReorder: onRowReorder,
            actionColumn: actionColumn,
            columnSpacing: columnSpacing ?? .only(left: 5, right: 5, top: 16),
          );
        } else {
          return MobileTableForm<T>(
            rows: rows,
            columns: columns,
            mobileHeader: actionColumn?.headerBuilder(context),
            cardAction: actionColumn?.rowBuilder,
            cellPadding: columnSpacing ?? .all(5),
          );
        }
      },
    );
  }
}

class DesktopTableForm<T> extends StatefulWidget {
  final List<T> rows;
  final List<TableFormColumn<T>> columns;
  final EdgeInsets columnSpacing;
  final TableFormColumn<T>? actionColumn;
  final bool isRowReorderable;
  final double rowHeight;
  final Function(List<T> rows, int fromIndex, int toIndex)? onRowReorder;
  const DesktopTableForm({
    super.key,
    required this.columnSpacing,
    required this.columns,
    required this.rows,
    required this.rowHeight,
    this.isRowReorderable = false,
    this.actionColumn,
    this.onRowReorder,
  });

  @override
  State<DesktopTableForm<T>> createState() => _DesktopTableFormState<T>();
}

class _DesktopTableFormState<T> extends State<DesktopTableForm<T>> {
  final _scrollController = ScrollController();
  final _scrollVerticalController = ScrollController();
  bool sortAscending = true;
  int? sortColumnIndex;
  double beforePosition = 0;
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
  void dispose() {
    _scrollController.dispose();
    _scrollVerticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double minWidth = columns.map<double>((e) => e.width).sum;
    if (widget.isRowReorderable) {
      minWidth += 35;
    }
    if (widget.actionColumn != null) {
      minWidth += widget.actionColumn!.width;
    }
    final padding = MediaQuery.of(context).padding;
    final maxWidth = <double>[
      minWidth,
      MediaQuery.sizeOf(context).width - padding.left - padding.right - 60,
    ].max;
    const borderside = BorderSide();
    return Scrollbar(
      thumbVisibility: true,
      trackVisibility: true,
      thickness: 8,
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0, right: 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, minWidth: minWidth),
          child: SingleChildScrollView(
            scrollDirection: .horizontal,
            controller: _scrollController,
            child: SizedBox(
              width: minWidth,
              child: Column(
                mainAxisSize: .min,
                children: [
                  SizedBox(
                    height: widget.rowHeight,
                    child: Row(
                      mainAxisSize: .min,
                      children: [
                        if (widget.isRowReorderable)
                          Container(
                            width: 35,
                            height: widget.rowHeight,
                            decoration: BoxDecoration(
                              border: Border(
                                left: borderside,
                                right: borderside,
                                top: borderside,
                                bottom: borderside,
                              ),
                            ),
                          ),
                        ...columns.mapIndexed<Widget>(
                          (index, column) => Stack(
                            children: [
                              Container(
                                width: column.width,
                                height: widget.rowHeight,
                                decoration: BoxDecoration(
                                  border: Border(
                                    left:
                                        (!widget.isRowReorderable && index == 0)
                                        ? borderside
                                        : BorderSide.none,
                                    right: borderside,
                                    top: borderside,
                                    bottom: borderside,
                                  ),
                                ),
                                padding: widget.columnSpacing,
                                child: column.headerBuilder(context),
                              ),
                              if (column.isColumnResizeable == true)
                                Positioned(
                                  top: 1,
                                  right: 5,
                                  child: GestureDetector(
                                    onHorizontalDragUpdate: (detail) {
                                      final beforeWidth = column.width;
                                      setState(() {
                                        column.width +=
                                            (detail.localPosition.dx -
                                            beforePosition);
                                        if (column.width < column.minWidth) {
                                          column.width = column.minWidth;
                                        }
                                        if (column.maxWidth != null &&
                                            column.width > column.maxWidth!) {
                                          column.width = column.maxWidth!;
                                        }
                                        if (column.width != beforeWidth) {
                                          beforePosition =
                                              detail.localPosition.dx;
                                        }
                                      });
                                    },
                                    onHorizontalDragEnd: (detail) {
                                      beforePosition = 0;
                                    },
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.resizeColumn,
                                      child: Icon(
                                        PhosphorIconsRegular
                                            .arrowsOutLineHorizontal,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (widget.actionColumn != null)
                          Stack(
                            children: [
                              Container(
                                width: widget.actionColumn!.width,
                                height: widget.rowHeight,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: borderside,
                                    top: borderside,
                                    bottom: borderside,
                                  ),
                                ),
                                padding: widget.columnSpacing,
                                child: widget.actionColumn!.headerBuilder(
                                  context,
                                ),
                              ),
                              if (widget.actionColumn!.isColumnResizeable ==
                                  true)
                                Positioned(
                                  top: 1,
                                  right: 5,
                                  child: GestureDetector(
                                    onHorizontalDragUpdate: (detail) {
                                      final beforeWidth =
                                          widget.actionColumn!.width;
                                      setState(() {
                                        widget.actionColumn!.width +=
                                            (detail.localPosition.dx -
                                            beforePosition);
                                        if (widget.actionColumn!.width <
                                            widget.actionColumn!.minWidth) {
                                          widget.actionColumn!.width =
                                              widget.actionColumn!.minWidth;
                                        }
                                        if (widget.actionColumn!.maxWidth !=
                                                null &&
                                            widget.actionColumn!.width >
                                                widget
                                                    .actionColumn!
                                                    .maxWidth!) {
                                          widget.actionColumn!.width =
                                              widget.actionColumn!.maxWidth!;
                                        }
                                        if (widget.actionColumn!.width !=
                                            beforeWidth) {
                                          beforePosition =
                                              detail.localPosition.dx;
                                        }
                                      });
                                    },
                                    onHorizontalDragEnd: (detail) {
                                      beforePosition = 0;
                                    },
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.resizeColumn,
                                      child: Icon(
                                        PhosphorIconsRegular
                                            .arrowsOutLineHorizontal,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: [widget.rows.length * widget.rowHeight, 300.0].min,
                    child: Scrollbar(
                      thumbVisibility: true,
                      trackVisibility: true,
                      thickness: 8,
                      controller: _scrollController,
                      child: ReorderableListView(
                        buildDefaultDragHandles: false,
                        scrollController: _scrollVerticalController,
                        onReorder: moveRows,
                        children: widget.rows
                            .mapIndexed(
                              (index, row) => Container(
                                width: maxWidth,
                                height: widget.rowHeight,
                                key: ObjectKey(row),
                                padding: .all(0),
                                decoration: BoxDecoration(
                                  color: index % 2 == 0
                                      ? Colors.grey.shade100
                                      : Colors.white,
                                  border: BoxBorder.fromLTRB(
                                    bottom: borderside,
                                  ),
                                ),
                                child: Row(
                                  key: ObjectKey(row),
                                  mainAxisAlignment: .start,
                                  // crossAxisAlignment: .stretch,
                                  children: [
                                    if (widget.isRowReorderable)
                                      Container(
                                        width: 35,
                                        height: widget.rowHeight,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            left: borderside,
                                            right: borderside,
                                          ),
                                        ),
                                        child: ReorderableDragStartListener(
                                          index: index,
                                          child: MouseRegion(
                                            cursor: SystemMouseCursors.move,
                                            child: Icon(Icons.drag_indicator),
                                          ),
                                        ),
                                      ),
                                    ...columns.mapIndexed<Widget>(
                                      (indexColumn, column) => Container(
                                        width: column.width,
                                        height: widget.rowHeight,
                                        constraints: BoxConstraints(
                                          maxHeight: double.infinity,
                                          minHeight: 35,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            left:
                                                (!widget.isRowReorderable &&
                                                    indexColumn == 0)
                                                ? borderside
                                                : BorderSide.none,
                                            right: borderside,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: widget.columnSpacing,
                                          child: column.rowBuilder(
                                            context,
                                            row,
                                            index,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (widget.actionColumn != null)
                                      Container(
                                        width: widget.actionColumn!.width,
                                        height: widget.rowHeight,
                                        decoration: BoxDecoration(
                                          border: Border(right: borderside),
                                        ),
                                        child: Padding(
                                          padding: widget.columnSpacing,
                                          child: widget.actionColumn!
                                              .rowBuilder(context, row, index),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
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
  final Function(List<T> rows, int fromIndex, int toIndex)? onRowReorder;
  const MobileTableForm({
    super.key,
    required this.columns,
    required this.rows,
    this.mobileHeader,
    this.cardAction,
    this.onRowReorder,
    required this.cellPadding,
  });

  @override
  State<MobileTableForm<T>> createState() => _MobileTableFormState<T>();
}

class _MobileTableFormState<T> extends State<MobileTableForm<T>> {
  final Map<int, bool> togglerAccordion = {};
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      children: [
        if (widget.mobileHeader != null)
          Row(
            crossAxisAlignment: .start,
            children: [widget.mobileHeader!, const Divider()],
          ),
        SizedBox(
          height: 300,
          child: ReorderableListView(
            buildDefaultDragHandles: false,
            onReorder: moveRows,
            children: widget.rows
                .mapIndexed<Widget>(
                  (index, row) => Card(
                    key: ObjectKey(row),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 3,
                            horizontal: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: .spaceBetween,
                            spacing: 5,
                            children: [
                              Row(
                                mainAxisSize: .min,
                                children: [
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: Icon(Icons.drag_indicator),
                                  ),
                                  Flexible(
                                    child: Text(
                                      'No ${index + 1}',
                                      style: TextFormatter.labelStyle,
                                    ),
                                  ),
                                  widget.cardAction?.call(
                                        context,
                                        row,
                                        index,
                                      ) ??
                                      SizedBox.shrink(),
                                ],
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    if (togglerAccordion[index] == null) {
                                      togglerAccordion[index] = true;
                                    } else {
                                      togglerAccordion[index] =
                                          !togglerAccordion[index]!;
                                    }
                                  });
                                },
                                icon: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: .circular(15),
                                    border: Border.all(color: Colors.black),
                                  ),
                                  child: Icon(
                                    togglerAccordion[index] == true
                                        ? Icons.arrow_drop_down
                                        : Icons.arrow_drop_up,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Visibility(
                          visible: togglerAccordion[index] == true,
                          child: Column(
                            children: [
                              const Divider(),
                              ...widget.columns.map<Widget>(
                                (column) => ListTile(
                                  title: Text(
                                    column.title,
                                    style: TextFormatter.labelStyle,
                                  ),
                                  subtitle: column.rowBuilder(
                                    context,
                                    row,
                                    index,
                                  ),
                                ),
                              ),
                            ],
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
    );
  }

  void moveRows(int fromIndex, int toIndex) {
    final data = widget.rows[fromIndex];
    setState(() {
      widget.rows.removeAt(fromIndex);
      widget.rows.insert(toIndex, data);
      widget.onRowReorder?.call(widget.rows, fromIndex, toIndex);
    });
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
