import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/widget/date_range_picker.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/model/session_state.dart';

class SalesTodayReport extends StatefulWidget {
  const SalesTodayReport({super.key});

  @override
  State<SalesTodayReport> createState() => _SalesTodayReportState();
}

class _SalesTodayReportState extends State<SalesTodayReport>
    with TickerProviderStateMixin {
  double totalSales = 0.0;
  double totalDebit = 0.0;
  double totalCash = 0.0;
  double totalCredit = 0.0;
  double totalQRIS = 0.0;
  double totalOnline = 0.0;
  double totalDiscount = 0.0;
  int totalTransaction = 0;
  bool _isCustom = false;
  late Future requestController;
  late final Setting setting;
  late AnimationController controller;
  DateTime startTime = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);
  DateTime endTime = DateTime.now()
      .copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller.reset();
          controller.forward();
        } else if (status == AnimationStatus.dismissed) {
          controller.forward();
        }
      });
    setting = context.read<Setting>();
    refreshReport();
    super.initState();
  }

  void refreshReport() {
    controller.reset();
    controller.forward();
    var sessionState = context.read<SessionState>();
    requestController = sessionState.server.get('sales/today_report',
        queryParam: {
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String()
        }).then((response) {
      if (response.statusCode == 200) {
        var data = response.data['data'];
        setState(() {
          totalSales = double.tryParse(data['sales_total']) ?? 0;
          totalDebit = double.tryParse(data['debit_total']) ?? 0;
          totalCredit = double.tryParse(data['credit_total']) ?? 0;
          totalCash = double.tryParse(data['cash_total']) ?? 0;
          totalOnline = double.tryParse(data['online_total']) ?? 0;
          totalQRIS = double.tryParse(data['qris_total']) ?? 0;
          totalDiscount = double.tryParse(data['discount_total']) ?? 0;
          totalTransaction = data['num_of_transaction'] ?? 0;
        });
      }
    },
        onError: (error, stack) => sessionState.server.defaultResponse(
            context: context,
            error: error)).whenComplete(() => controller.stop());
  }

  String _rangeFormat() {
    return "${setting.dateTimeFormat(startTime)} - ${setting.dateTimeFormat(endTime)}";
  }

  @override
  void dispose() {
    requestController.ignore();
    controller.dispose();
    super.dispose();
  }

  void arrangeDate(String rangeType) {
    startTime = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);
    endTime = DateTime.now()
        .copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
    switch (rangeType) {
      case 'yesterday':
        startTime = startTime.subtract(const Duration(days: 1));
        endTime = endTime.subtract(const Duration(days: 1));
        break;
      case 'week':
        startTime = startTime.subtract(const Duration(days: 7));
        break;
      case 'month':
        startTime = startTime.copyWith(day: 1);
        endTime = endTime
            .copyWith(day: 4)
            .add(const Duration(days: 28))
            .copyWith(day: 1)
            .subtract(const Duration(days: 1));
        break;
      case 'year':
        startTime = startTime.copyWith(month: 1, day: 1);
        endTime = endTime.copyWith(month: 12, day: 31);
        break;
    }
    _isCustom = rangeType == 'custom';
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
              IconButton(
                  tooltip: 'Refresh Laporan',
                  alignment: Alignment.centerRight,
                  onPressed: () => refreshReport(),
                  color: colorScheme.onPrimaryContainer,
                  icon: const Icon(Icons.refresh_rounded))
            ],
          ),
          DropdownMenu(
            width: 160,
            textStyle:
                TextStyle(fontSize: 18, color: colorScheme.onPrimaryContainer),
            inputDecorationTheme: const InputDecorationTheme(
                filled: true,
                fillColor: Color.fromARGB(255, 221, 219, 219),
                contentPadding: EdgeInsets.only(left: 10, right: 0),
                border: OutlineInputBorder()),
            enableSearch: false,
            initialSelection: 'day',
            dropdownMenuEntries: const [
              DropdownMenuEntry(
                value: 'day',
                label: 'Hari ini',
              ),
              DropdownMenuEntry(
                value: 'yesterday',
                label: 'Kemarin',
              ),
              DropdownMenuEntry(
                value: 'week',
                label: 'Minggu ini',
              ),
              DropdownMenuEntry(
                value: 'month',
                label: 'Bulan ini',
              ),
              DropdownMenuEntry(
                value: 'year',
                label: 'Tahun ini',
              ),
              DropdownMenuEntry(
                value: 'custom',
                label: 'Custom',
              ),
            ],
            onSelected: ((value) => setState(() {
                  arrangeDate(value ?? '');
                  refreshReport();
                })),
          ),
          const SizedBox(
            height: 10,
          ),
          if (_isCustom)
            DateRangePicker(
              textStyle:
                  const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              startDate: startTime,
              endDate: endTime,
              onChanged: (DateTimeRange range) {
                setState(() {
                  startTime = range.start;
                  endTime = range.end;
                  refreshReport();
                });
              },
            ),
          if (!_isCustom)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                _rangeFormat(),
                style:
                    const TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
              ),
            ),
          const SizedBox(
            height: 10,
          ),
          if (controller.isAnimating)
            Center(
              child: CircularProgressIndicator(
                value: controller.value,
                semanticsLabel: 'Dalam proses data',
              ),
            ),
          if (!controller.isAnimating) const Divider(),
          if (!controller.isAnimating)
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
                      setting.moneyFormat(totalSales),
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
                      setting.numberFormat(totalTransaction),
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
                      setting.moneyFormat(totalDiscount),
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
                      setting.moneyFormat(totalCash),
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
                      setting.moneyFormat(totalDebit),
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
                      setting.moneyFormat(totalCredit),
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
                      setting.moneyFormat(totalQRIS),
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
                      setting.moneyFormat(totalOnline),
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
