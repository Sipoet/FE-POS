import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:fe_pos/model/sales_transaction_report.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/app_updater.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/widget/last_sales_transaction_widget.dart';
import 'package:fe_pos/widget/period_sales_goal.dart';
import 'package:fe_pos/widget/sales_traffic_report_widget.dart';
import 'package:fe_pos/widget/sales_transaction_report_widget.dart';
import 'package:fe_pos/widget/item_sales_transaction_report_widget.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AppUpdater, AutomaticKeepAliveClientMixin, DefaultResponse {
  final TransactionReportController controller = TransactionReportController(
      DateTimeRange(start: DateTime.now(), end: DateTime.now()));
  bool _isCustom = false;
  late List<Widget> _panels;
  late final Setting setting;
  final pickerController = DateRangeEditingController(
      DateTimeRange(start: DateTime.now(), end: DateTime.now()));
  Money? totalSales;
  final Period period = Period.week;

  @override
  void initState() {
    setting = context.read<Setting>();
    final server = context.read<Server>();
    checkUpdate(server);
    // if (setting.isAuthorize('sale', 'transactionReport')) {
    //   getPeriodSalesTotal(period, server);
    // }
    _panels = [
      if (setting.isAuthorize('sale', 'transactionReport'))
        SalesTransactionReportWidget(
          controller: controller,
        ),
      if (setting.isAuthorize('sale', 'index'))
        LastSalesTransactionWidget(
          controller: controller,
          limit: 5,
        ),
      if (setting.isAuthorize('saleTrafficReport', 'index'))
        SalesTrafficReportWidget(
          controller: controller,
        ),
    ];
    if (setting.isAuthorize('saleItem', 'transactionReport')) {
      _panels += [
        ItemSalesTransactionReportWidget(
            key: const ValueKey('brand'),
            controller: controller,
            groupKey: 'brand',
            limit: '5',
            label: 'Merek Terjual Terbanyak'),
        ItemSalesTransactionReportWidget(
            key: const ValueKey('item_type'),
            controller: controller,
            groupKey: 'item_type',
            limit: '5',
            label: 'Departemen Terjual Terbanyak'),
        ItemSalesTransactionReportWidget(
            key: const ValueKey('supplier'),
            groupKey: 'supplier',
            controller: controller,
            limit: '5',
            label: 'Supplier Terjual Terbanyak'),
      ];
    }
    final now = DateTime.now();

    var startTime = DateTime.now()
        .copyWith(hour: separateHourWithinDay, minute: 0, second: 0);
    if (now.hour < separateHourWithinDay) {
      startTime = startTime.subtract(const Duration(days: 1));
    }
    var endTime = startTime
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));
    _rangeDateList = {
      'day': DateTimeRange(
        start: startTime,
        end: endTime,
      ),
      'yesterday': DateTimeRange(
          start: startTime.subtract(const Duration(days: 1)),
          end: endTime.subtract(const Duration(days: 1))),
      '2 day Ago': DateTimeRange(
          start: startTime.subtract(const Duration(days: 2)),
          end: endTime.subtract(const Duration(days: 2))),
      'week': DateTimeRange(
        start: startTime.subtract(const Duration(days: 7)),
        end: endTime,
      ),
      'weekAgo': DateTimeRange(
        start: startTime.subtract(const Duration(days: 14)),
        end: endTime.subtract(const Duration(days: 7)),
      ),
      'month': DateTimeRange(
        start: startTime.copyWith(day: 1),
        end: endTime
            .copyWith(day: 4)
            .add(const Duration(days: 28))
            .copyWith(day: 1)
            .subtract(const Duration(days: 1)),
      ),
      'monthAgo': DateTimeRange(
        start: startTime
            .copyWith(day: 1)
            .subtract(const Duration(days: 1))
            .copyWith(day: 1),
        end: endTime.copyWith(day: 1).subtract(const Duration(days: 1)),
      ),
      'year': DateTimeRange(
        start: startTime.copyWith(month: 1, day: 1),
        end: endTime.copyWith(month: 12, day: 31),
      ),
      'yearAgo': DateTimeRange(
        start: startTime.copyWith(year: startTime.year - 1, month: 1, day: 1),
        end: endTime.copyWith(year: startTime.year - 1, month: 12, day: 31),
      ),
      'custom': DateTimeRange(
        start: startTime,
        end: endTime,
      ),
    };

    arrangeDate('day');

    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  int separateHourWithinDay = 7;

  late final Map<String, DateTimeRange> _rangeDateList;
  void arrangeDate(String rangeType) {
    _isCustom = rangeType == 'custom';
    if (!_isCustom) {
      DateTimeRange range = _rangeDateList[rangeType] ??
          DateTimeRange(start: DateTime.now(), end: DateTime.now());
      controller.changeDate(range);
      pickerController.value = range;
    }
  }

  void getPeriodSalesTotal(Period period, Server server) {
    late Date startDate;
    late Date endDate;
    switch (period) {
      case Period.day:
        startDate = Date.today();
        endDate = Date.today();
        break;
      case Period.month:
        startDate = Date.today().beginningOfMonth();
        endDate = Date.today().endOfMonth();
        break;
      case Period.year:
        startDate = Date.today().beginningOfYear();
        endDate = Date.today().endOfYear();
        break;
      case Period.week:
        startDate = Date.today().beginningOfWeek();
        endDate = Date.today().endOfWeek();
        break;
    }
    server.get('sales/transaction_report', queryParam: {
      'start_time': startDate.toDateTime().toIso8601String(),
      'end_time': endDate
          .add(const Duration(days: 1))
          .toDateTime()
          .copyWith(hour: 6, minute: 59, second: 59, millisecond: 99)
          .toIso8601String()
    }).then((response) {
      if (mounted && response.statusCode == 200) {
        var data = response.data['data'];
        final salesTransactionReport =
            SalesTransactionReportClass().fromJson(data);
        setState(() {
          totalSales = salesTransactionReport.totalSales;
          _panels.insert(
              0,
              PeriodSalesGoal(
                totalSales: totalSales ?? const Money(0),
                period: period,
                expectedSales: const Money(140000000),
                salesTransactionReports: const [],
              ));
        });
      }
    }, onError: (error, stack) => defaultErrorResponse(error: error));
  }

  final textController = BoardDateTimeTextController();
  @override
  Widget build(BuildContext context) {
    super.build(context);
    var colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              children: [
                DropdownMenu(
                  menuHeight: 250,
                  inputDecorationTheme: const InputDecorationTheme(
                    contentPadding: EdgeInsets.only(left: 10),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  menuStyle: MenuStyle(
                      backgroundColor: WidgetStatePropertyAll(
                          colorScheme.secondaryContainer),
                      surfaceTintColor: WidgetStatePropertyAll(
                          colorScheme.onSecondaryContainer),
                      shadowColor: WidgetStatePropertyAll(colorScheme.outline)),
                  textStyle: TextStyle(
                      fontSize: 16, color: colorScheme.onPrimaryContainer),
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
                      value: '2 day Ago',
                      label: '2 Hari yang lalu',
                    ),
                    DropdownMenuEntry(
                      value: 'week',
                      label: 'Minggu ini',
                    ),
                    DropdownMenuEntry(
                      value: 'weekAgo',
                      label: 'Minggu yang lalu',
                    ),
                    DropdownMenuEntry(
                      value: 'month',
                      label: 'Bulan ini',
                    ),
                    DropdownMenuEntry(
                      value: 'monthAgo',
                      label: 'Bulan yang lalu',
                    ),
                    DropdownMenuEntry(
                      value: 'year',
                      label: 'Tahun ini',
                    ),
                    DropdownMenuEntry(
                      value: 'yearAgo',
                      label: 'Tahun yang lalu',
                    ),
                    DropdownMenuEntry(
                      value: 'custom',
                      label: 'Kustom',
                    ),
                  ],
                  onSelected: ((value) => setState(() {
                        arrangeDate(value ?? '');
                      })),
                ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 350),
                  child: DateRangeFormField(
                    enabled: _isCustom,
                    textStyle: const TextStyle(
                        fontSize: 16, fontStyle: FontStyle.italic),
                    initialDateRange: controller.range,
                    controller: pickerController,
                    onChanged: (DateTimeRange? range) {
                      if (range == null) {
                        return;
                      }
                      controller.changeDate(range);
                    },
                  ),
                ),
                IconButton.filled(
                    onPressed: () {
                      controller.changeDate(controller.range);
                    },
                    tooltip: 'Refresh Laporan',
                    icon: const Icon(
                      Icons.refresh,
                    )),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) => Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        border:
                            Border.all(color: colorScheme.outline, width: 1)),
                    child: _panels[index]),
                itemCount: _panels.length,
                separatorBuilder: (context, index) => const SizedBox(
                  height: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
