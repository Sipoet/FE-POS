import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/transaction_report_controller.dart';
export 'package:fe_pos/tool/transaction_report_controller.dart';

class ItemSalesTransactionReportWidget extends StatefulWidget {
  final TransactionReportController? controller;
  final String groupKey;
  final String limit;
  final String label;
  const ItemSalesTransactionReportWidget(
      {super.key,
      required this.label,
      required this.groupKey,
      required this.limit,
      this.controller});

  @override
  State<ItemSalesTransactionReportWidget> createState() =>
      _ItemSalesTransactionReportWidgetState();
}

class _ItemSalesTransactionReportWidgetState
    extends State<ItemSalesTransactionReportWidget>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        TextFormatter,
        DefaultResponse {
  List results = [];
  late final Setting setting;
  late AnimationController _controller;
  DateTimeRange _dateRange = DateTimeRange(
      start: DateTime.now().copyWith(hour: 0, minute: 0, second: 0),
      end: DateTime.now()
          .copyWith(hour: 23, minute: 59, second: 59, millisecond: 999));

  late String limit;
  CancelToken cancelToken = CancelToken();
  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reset();
          _controller.forward();
        }
      });
    limit = widget.limit;
    setting = context.read<Setting>();
    _dateRange = widget.controller?.range ?? _dateRange;
    widget.controller?.addListener(() {
      setState(() {
        _dateRange = widget.controller?.range ?? _dateRange;
        refreshReport();
      });
    });
    refreshReport();
    super.initState();
  }

  @override
  void dispose() {
    cancelToken.cancel();
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  void refreshReport() {
    _controller.forward();
    final server = context.read<Server>();
    server.get('sale_items/transaction_report',
        cancelToken: cancelToken,
        queryParam: {
          'group_key': widget.groupKey,
          'limit': limit,
          'start_time': _dateRange.start.toIso8601String(),
          'end_time': _dateRange.end.toIso8601String(),
        }).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          results = response.data['data'];
        });
      }
    },
        onError: (error, stack) =>
            defaultErrorResponse(error: error)).whenComplete(() {
      if (_controller.isAnimating) {
        _controller.stop();
        _controller.reset();
      }
    });
  }

  String _humanizeKey(String key) {
    switch (key) {
      case 'brand':
        return 'Merek';
      case 'item_type':
        return 'Jenis / Departemen';
      case 'supplier':
        return 'Supplier';
      default:
        return '';
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var colorScheme = Theme.of(context).colorScheme;
    var style = TextStyle(
        fontWeight: FontWeight.bold, color: colorScheme.onSecondaryContainer);
    int index = 0;
    Size size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    double width = size.width - padding.left - padding.right - 50;
    double headerLabelWidth = width - 40;
    if (width < 700) {
      width = 700.0;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: headerLabelWidth,
              child: Text(
                widget.label,
                softWrap: true,
                style: TextStyle(
                    fontSize: 18,
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w900),
              ),
            ),
            IconButton.filled(
                tooltip: 'Refresh Laporan',
                alignment: Alignment.centerRight,
                onPressed: () => refreshReport(),
                icon: const Icon(Icons.refresh_rounded))
          ],
        ),
        DropdownMenu(
          width: 100,
          textStyle:
              TextStyle(fontSize: 18, color: colorScheme.onPrimaryContainer),
          inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color.fromARGB(255, 221, 219, 219),
              contentPadding: EdgeInsets.only(left: 10, right: 0),
              border: OutlineInputBorder()),
          enableSearch: false,
          initialSelection: limit,
          dropdownMenuEntries: const [
            DropdownMenuEntry(
              value: '5',
              label: '5',
            ),
            DropdownMenuEntry(
              value: '10',
              label: '10',
            ),
            DropdownMenuEntry(
              value: '20',
              label: '20',
            ),
            DropdownMenuEntry(
              value: '50',
              label: '50',
            ),
            DropdownMenuEntry(
              value: '100',
              label: '100',
            ),
          ],
          onSelected: ((value) => setState(() {
                limit = value ?? '5';
                refreshReport();
              })),
        ),
        const SizedBox(
          height: 10,
        ),
        if (_controller.isAnimating)
          Center(
            child: CircularProgressIndicator(
              value: _controller.value,
              semanticsLabel: 'Dalam proses data',
            ),
          ),
        if (results.isNotEmpty && !_controller.isAnimating)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Table(
                  border: TableBorder.all(
                    color: Colors.grey.shade400.withOpacity(0.5),
                  ),
                  columnWidths: const {
                    0: FixedColumnWidth(50),
                    3: FixedColumnWidth(100),
                  },
                  children: <TableRow>[
                        TableRow(
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                            ),
                            children: [
                              Text(
                                'NO',
                                style: style,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                _humanizeKey(widget.groupKey),
                                style: style,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Total Terjual',
                                style: style,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Jumlah',
                                style: style,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Total Diskon',
                                style: style,
                                textAlign: TextAlign.center,
                              )
                            ]),
                      ] +
                      results
                          .map<TableRow>((row) => TableRow(
                                  decoration: BoxDecoration(
                                      color: index.isEven
                                          ? colorScheme.tertiaryContainer
                                          : colorScheme.secondaryContainer),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(
                                        (index += 1).toString(),
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            color: index.isOdd
                                                ? colorScheme
                                                    .onTertiaryContainer
                                                : colorScheme
                                                    .onSecondaryContainer),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(
                                        row['identifier'] ?? '',
                                        style: TextStyle(
                                            color: index.isOdd
                                                ? colorScheme
                                                    .onTertiaryContainer
                                                : colorScheme
                                                    .onSecondaryContainer),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(
                                        moneyFormat(
                                          row['sales_total'],
                                        ),
                                        style: TextStyle(
                                            color: index.isOdd
                                                ? colorScheme
                                                    .onTertiaryContainer
                                                : colorScheme
                                                    .onSecondaryContainer),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(
                                        numberFormat(row['quantity']),
                                        style: TextStyle(
                                            color: index.isOdd
                                                ? colorScheme
                                                    .onTertiaryContainer
                                                : colorScheme
                                                    .onSecondaryContainer),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(
                                        moneyFormat(row['discount_total']),
                                        style: TextStyle(
                                            color: index.isOdd
                                                ? colorScheme
                                                    .onTertiaryContainer
                                                : colorScheme
                                                    .onSecondaryContainer),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ]))
                          .toList()),
            ),
          ),
        if (results.isEmpty && !_controller.isAnimating)
          Text('belum ada transaksi',
              style: TextStyle(color: colorScheme.onPrimaryContainer)),
      ],
    );
  }
}
