import 'package:collection/collection.dart';
import 'package:fe_pos/model/sale.dart';
import 'package:fe_pos/page/sale_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/transaction_report_controller.dart';
export 'package:fe_pos/tool/transaction_report_controller.dart';
import 'package:fe_pos/tool/platform_checker.dart';

class LastSalesTransactionWidget extends StatefulWidget {
  final int limit;

  final TransactionReportController? controller;
  const LastSalesTransactionWidget(
      {super.key, this.limit = 5, this.controller});
  @override
  State<LastSalesTransactionWidget> createState() =>
      _LastSalesTransactionWidgetState();
}

class _LastSalesTransactionWidgetState extends State<LastSalesTransactionWidget>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        DefaultResponse,
        PlatformChecker,
        TextFormatter {
  List<Sale> sales = [];
  late int limit;
  CancelToken cancelToken = CancelToken();
  late final Setting setting;
  late AnimationController _controller;
  DateTimeRange _dateRange = DateTimeRange(
      start: DateTime.now().copyWith(hour: 0, minute: 0, second: 0),
      end: DateTime.now()
          .copyWith(hour: 23, minute: 59, second: 59, millisecond: 999));
  @override
  void initState() {
    limit = widget.limit;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      })
      ..addStatusListener((status) {
        if (mounted && status == AnimationStatus.completed) {
          _controller.reset();
          _controller.forward();
        }
      });
    setting = context.read<Setting>();
    _dateRange = widget.controller?.range ?? _dateRange;
    widget.controller?.addListener(setDateAndRefreshReport);

    refreshReport();
    super.initState();
  }

  void setDateAndRefreshReport() {
    setState(() {
      _dateRange = widget.controller?.range ?? _dateRange;
      refreshReport();
    });
  }

  void refreshReport() {
    _controller.reset();
    _controller.forward();
    final server = context.read<Server>();
    server
        .get(
      'sales',
      queryParam: {
        'filter[tanggal][btw]': [
          _dateRange.start.toIso8601String(),
          _dateRange.end.toIso8601String()
        ].join(','),
        'page[page]': '1',
        'page[limit]': limit.toString(),
        'sort': '-tanggal'
      },
      cancelToken: cancelToken,
    )
        .then((response) {
      if (!mounted) return;
      if (response.statusCode == 200) {
        var data = response.data['data'] as List;
        setState(() {
          sales = data.map<Sale>((row) => Sale.fromJson(row)).toList();
        });
      }
    },
            onError: (error, stack) =>
                defaultErrorResponse(error: error)).whenComplete(() {
      if (_controller.isAnimating) _controller.reset();
    });
  }

  @override
  void dispose() {
    cancelToken.cancel();
    _controller.dispose();
    widget.controller?.removeListener(setDateAndRefreshReport);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var colorScheme = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(
        color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Penjualan Terakhir',
              style: TextStyle(
                  fontSize: 18,
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w900),
            ),
            IconButton.filled(
                tooltip: 'Refresh Laporan',
                alignment: Alignment.centerRight,
                onPressed: () => refreshReport(),
                icon: const Icon(Icons.refresh_rounded))
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        DropdownMenu<int>(
          width: 100,
          textStyle:
              TextStyle(fontSize: 18, color: colorScheme.onPrimaryContainer),
          inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              isDense: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.only(left: 10, right: 0),
              border: OutlineInputBorder()),
          dropdownMenuEntries: List<int>.generate(5, (i) => i * 5)
              .map<DropdownMenuEntry<int>>((value) =>
                  DropdownMenuEntry<int>(value: value, label: value.toString()))
              .toList(),
          initialSelection: limit,
          onSelected: (value) {
            limit = value ?? 5;
            refreshReport();
          },
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
        if (!_controller.isAnimating) const Divider(),
        if (!_controller.isAnimating)
          Table(
            columnWidths: const {
              3: FlexColumnWidth(2),
              2: FlexColumnWidth(0.5)
            },
            border: TableBorder.all(
              color: Colors.grey.shade400.withValues(alpha: 0.5),
            ),
            children: [
                  TableRow(
                      key: ValueKey('Header Table Last Sale'),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                      ),
                      children: [
                        TableCell(
                            child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Tanggal',
                            style: labelStyle,
                          ),
                        )),
                        TableCell(
                            child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'No Transaksi',
                            style: labelStyle,
                          ),
                        )),
                        TableCell(
                            child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Total Item',
                                style: labelStyle,
                              )),
                        )),
                        TableCell(
                            child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Total Transaksi',
                                style: labelStyle,
                              )),
                        )),
                      ]),
                ] +
                sales
                    .mapIndexed<TableRow>(
                      (index, sale) => TableRow(
                          key: ValueKey(sale.code),
                          decoration: BoxDecoration(
                              color: index.isEven
                                  ? colorScheme.tertiaryContainer
                                  : colorScheme.secondaryContainer),
                          children: [
                            TableCell(
                                verticalAlignment:
                                    TableCellVerticalAlignment.top,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SelectableText(
                                      dateTimeLocalFormat(sale.datetime)),
                                )),
                            TableCell(
                                verticalAlignment:
                                    TableCellVerticalAlignment.top,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: InkWell(
                                      onTap: () => _openSaleDetail(sale),
                                      child: Text(sale.code)),
                                )),
                            TableCell(
                                verticalAlignment:
                                    TableCellVerticalAlignment.top,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Align(
                                      alignment: Alignment.centerRight,
                                      child: SelectableText(
                                          numberFormat(sale.totalItem))),
                                )),
                            TableCell(
                                verticalAlignment:
                                    TableCellVerticalAlignment.top,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Align(
                                      alignment: Alignment.centerRight,
                                      child: SelectableText(
                                          moneyFormat(sale.grandtotal))),
                                )),
                          ]),
                    )
                    .toList(),
          ),
      ],
    );
  }

  void _openSaleDetail(Sale sale) {
    final tabManager = context.read<TabManager>();
    if (isDesktop()) {
      tabManager.setSafeAreaContent('Penjualan ${sale.code}',
          SaleFormPage(sale: sale, key: ObjectKey(sale)));
    } else {
      tabManager.addTab('Penjualan ${sale.code}',
          SaleFormPage(sale: sale, key: ObjectKey(sale)));
    }
  }
}
