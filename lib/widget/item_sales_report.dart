import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/widget/date_range_picker.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/model/session_state.dart';

class ItemSalesTodayReport extends StatefulWidget {
  final String groupKey;
  final String limit;
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
  bool _isCustom = false;
  late AnimationController controller;
  DateTime startTime = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);
  DateTime endTime = DateTime.now()
      .copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
  late String limit;
  late Future requestController;
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
    limit = widget.limit;
    setting = context.read<Setting>();
    refreshReport();
    super.initState();
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
    }
    _isCustom = rangeType == 'custom';
  }

  void refreshReport() {
    controller.reset();
    controller.forward();
    var sessionState = context.read<SessionState>();
    requestController = sessionState.server
        .get('item_sales/today_report', queryParam: {
      'group_key': widget.groupKey,
      'limit': limit,
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
                    fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
                color: colorScheme.onPrimaryContainer,
                tooltip: 'Refresh Laporan',
                alignment: Alignment.centerRight,
                onPressed: () => refreshReport(),
                icon: const Icon(Icons.refresh_rounded))
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DropdownMenu(
              width: 160,
              textStyle: TextStyle(
                  fontSize: 18, color: colorScheme.onPrimaryContainer),
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
            DropdownMenu(
              width: 100,
              textStyle: TextStyle(
                  fontSize: 18, color: colorScheme.onPrimaryContainer),
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
          ],
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
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
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
