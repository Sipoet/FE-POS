import 'package:fe_pos/model/sales_transaction_report.dart';
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
    extends State<SalesTransactionReportWidget> with TickerProviderStateMixin {
  late SalesTransactionReport salesTransactionReport;
  late Future requestController;
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
        } else if (status == AnimationStatus.dismissed) {
          _controller.forward();
        }
      });
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

  void refreshReport() {
    _controller.reset();
    _controller.forward();
    var sessionState = context.read<SessionState>();
    requestController = sessionState.server
        .get('sales/transaction_report', queryParam: {
      'start_time': _dateRange.start.toIso8601String(),
      'end_time': _dateRange.end.toIso8601String()
    }).then((response) {
      if (response.statusCode == 200) {
        var data = response.data['data'];
        data['start_time'] = _dateRange.start.toIso8601String();
        data['end_time'] = _dateRange.end.toIso8601String();
        setState(() {
          salesTransactionReport = SalesTransactionReport.fromJson(data);
        });
      }
    },
            onError: (error, stack) => sessionState.server.defaultResponse(
                context: context,
                error: error)).whenComplete(() => _controller.stop());
  }

  @override
  void dispose() {
    requestController.ignore();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var labelStyle = TextStyle(color: colorScheme.onPrimaryContainer);
    var valueStyle = TextStyle(
        color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w400);
    Size size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    double width = size.width - padding.left - padding.right - 50;
    double headerLabelWidth = width - 40;

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
                  'Laporan penjualan',
                  style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold),
                ),
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
                0: FlexColumnWidth(0.7),
                1: FixedColumnWidth(10)
              },
              children: [
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      'Total Penjualan',
                      style: labelStyle,
                    ),
                  ),
                  const Text(':'),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      setting.moneyFormat(salesTransactionReport.totalSales),
                      textAlign: TextAlign.right,
                      style: valueStyle,
                    ),
                  )
                ]),
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      'Total Transaksi',
                      style: labelStyle,
                    ),
                  ),
                  const Text(':'),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      setting.numberFormat(
                          salesTransactionReport.totalTransaction),
                      textAlign: TextAlign.right,
                      style: valueStyle,
                    ),
                  )
                ]),
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      'Total Diskon',
                      style: labelStyle,
                    ),
                  ),
                  const Text(':'),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      setting.moneyFormat(salesTransactionReport.totalDiscount),
                      textAlign: TextAlign.right,
                      style: valueStyle,
                    ),
                  )
                ]),
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      'Total Tunai',
                      style: labelStyle,
                    ),
                  ),
                  const Text(':'),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      setting.moneyFormat(salesTransactionReport.totalCash),
                      textAlign: TextAlign.right,
                      style: valueStyle,
                    ),
                  )
                ]),
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      'Total Debit',
                      style: labelStyle,
                    ),
                  ),
                  const Text(':'),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      setting.moneyFormat(salesTransactionReport.totalDebit),
                      textAlign: TextAlign.right,
                      style: valueStyle,
                    ),
                  )
                ]),
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      'Total Kredit',
                      style: labelStyle,
                    ),
                  ),
                  const Text(':'),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      setting.moneyFormat(salesTransactionReport.totalCredit),
                      textAlign: TextAlign.right,
                      style: valueStyle,
                    ),
                  )
                ]),
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      'Total QRIS',
                      style: labelStyle,
                    ),
                  ),
                  const Text(':'),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      setting.moneyFormat(salesTransactionReport.totalQRIS),
                      textAlign: TextAlign.right,
                      style: valueStyle,
                    ),
                  )
                ]),
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      'Total Online',
                      style: labelStyle,
                    ),
                  ),
                  const Text(':'),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      setting.moneyFormat(salesTransactionReport.totalOnline),
                      textAlign: TextAlign.right,
                      style: valueStyle,
                    ),
                  )
                ]),
              ],
            ),
        ]);
  }
}
