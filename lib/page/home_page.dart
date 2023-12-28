import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _panels = <Widget>[
    SalesTodayReport(),
    ItemSalesTodayReport(
        key: ValueKey('brand'),
        groupKey: 'brand',
        limit: 5,
        label: 'Merek Terjual Terbanyak'),
    ItemSalesTodayReport(
        key: ValueKey('item_type'),
        groupKey: 'item_type',
        limit: 5,
        label: 'Departemen Terjual Terbanyak'),
    ItemSalesTodayReport(
        key: ValueKey('supplier'),
        groupKey: 'supplier',
        limit: 5,
        label: 'Supplier Terjual Terbanyak'),
  ];

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        itemBuilder: (context, index) => Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                border: Border.all(color: colorScheme.outline, width: 2)),
            child: _panels[index]),
        itemCount: _panels.length,
        separatorBuilder: (context, index) => const SizedBox(
          height: 10,
        ),
      ),
    );
  }
}

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
    sessionState.server.get('sales/today_report', queryParam: {
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

  void arrangeDate(String rangeType) {
    startTime = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);
    endTime = DateTime.now()
        .copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
    switch (rangeType) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var labelStyle = TextStyle(color: colorScheme.onPrimaryContainer);
    var valueStyle = TextStyle(
        color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w400);

    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Laporan penjualan',
                style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold),
              ),
              IconButton(
                  tooltip: 'Refresh Laporan',
                  alignment: Alignment.centerRight,
                  onPressed: () => refreshReport(),
                  color: colorScheme.onPrimaryContainer,
                  icon: const Icon(Icons.refresh_rounded))
            ],
          ),
          Text(
            _rangeFormat(),
            textAlign: TextAlign.right,
            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
          ),
          const SizedBox(
            height: 5,
          ),
          DropdownMenu(
            width: 140,
            inputDecorationTheme: const InputDecorationTheme(
                filled: true,
                fillColor: Color.fromARGB(255, 221, 219, 219),
                contentPadding: EdgeInsets.all(5),
                border: OutlineInputBorder()),
            textStyle: const TextStyle(fontSize: 16),
            enableSearch: false,
            initialSelection: 'day',
            dropdownMenuEntries: const [
              DropdownMenuEntry(
                value: 'day',
                label: 'Hari ini',
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
            ],
            onSelected: ((value) => setState(() {
                  arrangeDate(value ?? '');
                  refreshReport();
                })),
          ),
          if (controller.isAnimating)
            Center(
              child: CircularProgressIndicator(
                value: controller.value,
                semanticsLabel: 'Dalam proses data',
              ),
            ),
          const Divider(),
          if (!controller.isAnimating)
            Table(
              columnWidths: const {
                0: FixedColumnWidth(150),
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

class ItemSalesTodayReport extends StatefulWidget {
  final String groupKey;
  final int limit;
  final String label;
  const ItemSalesTodayReport({
    super.key,
    required this.label,
    required this.groupKey,
    required this.limit,
  });

  @override
  State<ItemSalesTodayReport> createState() => _ItemSalesTodayReportState();
}

class _ItemSalesTodayReportState extends State<ItemSalesTodayReport>
    with TickerProviderStateMixin {
  List results = [];
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

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void arrangeDate(String rangeType) {
    startTime = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);
    endTime = DateTime.now()
        .copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
    switch (rangeType) {
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
    }
  }

  void refreshReport() {
    controller.reset();
    controller.forward();
    var sessionState = context.read<SessionState>();
    sessionState.server.get('item_sales/today_report', queryParam: {
      'group_key': widget.groupKey,
      'limit': widget.limit.toString(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
    }).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          results = response.data['data'];
        });
      }
    },
        onError: (error, stack) => sessionState.server.defaultResponse(
            context: context,
            error: error)).whenComplete(() => controller.stop());
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

  String _rangeFormat() {
    return "${setting.dateTimeFormat(startTime)} - ${setting.dateTimeFormat(endTime)}";
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var style = TextStyle(
        fontWeight: FontWeight.w500, color: colorScheme.onSecondaryContainer);
    int index = 0;
    Size size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    double width = size.width - padding.left - padding.right - 50;
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
            Text(
              widget.label,
              style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold),
            ),
            IconButton(
                color: colorScheme.onPrimaryContainer,
                tooltip: 'Refresh Laporan',
                alignment: Alignment.centerRight,
                onPressed: () => refreshReport(),
                icon: const Icon(Icons.refresh_rounded))
          ],
        ),
        Text(
          _rangeFormat(),
          textAlign: TextAlign.right,
          style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
        ),
        const SizedBox(
          height: 5,
        ),
        DropdownMenu(
          width: 140,
          inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color.fromARGB(255, 221, 219, 219),
              contentPadding: EdgeInsets.all(5),
              border: OutlineInputBorder()),
          textStyle: const TextStyle(fontSize: 16),
          enableSearch: false,
          initialSelection: 'day',
          dropdownMenuEntries: const [
            DropdownMenuEntry(
              value: 'day',
              label: 'Hari ini',
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
          ],
          onSelected: ((value) => setState(() {
                arrangeDate(value ?? '');
                refreshReport();
              })),
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
        if (results.isNotEmpty && !controller.isAnimating)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Table(
                  border: TableBorder.all(
                    color: Colors.grey.shade400.withOpacity(0.5),
                  ),
                  columnWidths: const {
                    0: FixedColumnWidth(35),
                    // 3: FixedColumnWidth(35),
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
                                'QTY',
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
                                        row['identifier'],
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
                                        setting.moneyFormat(
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
                                        setting.numberFormat(row['quantity']),
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
                                        setting
                                            .moneyFormat(row['discount_total']),
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
        if (results.isEmpty && !controller.isAnimating)
          Text('belum ada transaksi',
              style: TextStyle(color: colorScheme.onPrimaryContainer)),
      ],
    );
  }
}
