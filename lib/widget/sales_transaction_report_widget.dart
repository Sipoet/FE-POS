import 'package:fe_pos/model/sales_transaction_report.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/transaction_report_controller.dart';
export 'package:fe_pos/tool/transaction_report_controller.dart';

class SalesTransactionReportWidget extends StatefulWidget {
  const SalesTransactionReportWidget({super.key, this.controller});
  final TransactionReportController? controller;
  @override
  State<SalesTransactionReportWidget> createState() =>
      _SalesTransactionReportWidgetState();
}

class _SalesTransactionReportWidgetState
    extends State<SalesTransactionReportWidget>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        DefaultResponse,
        TextFormatter {
  late SalesTransactionReport salesTransactionReport;
  CancelToken cancelToken = CancelToken();
  late final Setting setting;
  late AnimationController _controller;
  DateTimeRange _dateRange = DateTimeRange(
      start: DateTime.now().copyWith(hour: 0, minute: 0, second: 0),
      end: DateTime.now()
          .copyWith(hour: 23, minute: 59, second: 59, millisecond: 999));
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
        .get('sales/transaction_report',
            queryParam: {
              'start_time': _dateRange.start.toIso8601String(),
              'end_time': _dateRange.end.toIso8601String()
            },
            cancelToken: cancelToken)
        .then((response) {
      if (response.statusCode == 200) {
        var data = response.data['data'];
        data['start_time'] = _dateRange.start.toIso8601String();
        data['end_time'] = _dateRange.end.toIso8601String();
        setState(() {
          salesTransactionReport = SalesTransactionReport.fromJson(data);
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
    final colorScheme = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(color: colorScheme.onPrimaryContainer);
    final valueStyle = TextStyle(
        color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Laporan penjualan',
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
              2: FixedColumnWidth(180),
              1: FixedColumnWidth(10),
            },
            children: [
              TableRow(children: [
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      'Total Penjualan',
                      style: labelStyle,
                    ),
                  ),
                ),
                TableCell(
                  child: const Text(':'),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      moneyFormat(salesTransactionReport.totalSales),
                      textAlign: TextAlign.right,
                      style: valueStyle,
                    ),
                  ),
                ),
              ]),
              TableRow(
                  decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      border: Border.symmetric(
                          horizontal: BorderSide(color: colorScheme.outline))),
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          'Omzet Kotor',
                          style: labelStyle,
                        ),
                      ),
                    ),
                    TableCell(child: const Text(':')),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          moneyFormat(salesTransactionReport.grossProfit),
                          textAlign: TextAlign.right,
                          style: valueStyle,
                        ),
                      ),
                    )
                  ]),
              TableRow(children: [
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      'Jumlah Transaksi',
                      style: labelStyle,
                    ),
                  ),
                ),
                TableCell(child: const Text(':')),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      numberFormat(salesTransactionReport.totalTransaction),
                      textAlign: TextAlign.right,
                      style: valueStyle,
                    ),
                  ),
                ),
              ]),
              TableRow(
                  decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      border: Border.symmetric(
                          horizontal: BorderSide(color: colorScheme.outline))),
                  children: [
                    TableCell(
                        child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Text(
                        'Total Diskon',
                        style: labelStyle,
                      ),
                    )),
                    TableCell(child: const Text(':')),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          moneyFormat(salesTransactionReport.totalDiscount),
                          textAlign: TextAlign.right,
                          style: valueStyle,
                        ),
                      ),
                    )
                  ]),
              TableRow(children: [
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      'Total Tunai',
                      style: labelStyle,
                    ),
                  ),
                ),
                TableCell(child: const Text(':')),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      moneyFormat(salesTransactionReport.totalCash),
                      textAlign: TextAlign.right,
                      style: valueStyle,
                    ),
                  ),
                )
              ]),
              TableRow(
                  decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      border: Border.symmetric(
                          horizontal: BorderSide(color: colorScheme.outline))),
                  children: [
                    TableCell(
                        child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Text(
                        'Total Kartu Debit',
                        style: labelStyle,
                      ),
                    )),
                    TableCell(child: const Text(':')),
                    TableCell(
                        child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Text(
                        moneyFormat(salesTransactionReport.totalDebit),
                        textAlign: TextAlign.right,
                        style: valueStyle,
                      ),
                    ))
                  ]),
              TableRow(children: [
                TableCell(
                    child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    'Total Kartu Kredit',
                    style: labelStyle,
                  ),
                )),
                TableCell(child: const Text(':')),
                TableCell(
                    child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    moneyFormat(salesTransactionReport.totalCredit),
                    textAlign: TextAlign.right,
                    style: valueStyle,
                  ),
                ))
              ]),
              TableRow(
                  decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      border: Border.symmetric(
                          horizontal: BorderSide(color: colorScheme.outline))),
                  children: [
                    TableCell(
                        child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Text(
                        'Total QRIS',
                        style: labelStyle,
                      ),
                    )),
                    TableCell(child: const Text(':')),
                    TableCell(
                        child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Text(
                        moneyFormat(salesTransactionReport.totalQRIS),
                        textAlign: TextAlign.right,
                        style: valueStyle,
                      ),
                    ))
                  ]),
              TableRow(children: [
                TableCell(
                    child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    'Total Online Transfer',
                    style: labelStyle,
                  ),
                )),
                TableCell(child: const Text(':')),
                TableCell(
                    child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    moneyFormat(salesTransactionReport.totalOnline),
                    textAlign: TextAlign.right,
                    style: valueStyle,
                  ),
                ))
              ]),
            ],
          ),
      ],
    );
  }
}
