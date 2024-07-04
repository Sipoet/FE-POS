import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/app_updater.dart';
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
    with AppUpdater<HomePage>, AutomaticKeepAliveClientMixin {
  final TransactionReportController controller = TransactionReportController(
      DateTimeRange(start: DateTime.now(), end: DateTime.now()));
  bool _isCustom = false;
  late final List<Widget> _panels;
  late final Setting setting;
  final pickerController = PickerController(
      DateTimeRange(start: DateTime.now(), end: DateTime.now()));
  @override
  void initState() {
    setting = context.read<Setting>();
    final server = context.read<Server>();
    checkUpdate(server);
    _panels = [
      if (setting.isAuthorize('sale', 'transactionReport'))
        SalesTransactionReportWidget(
          controller: controller,
        ),
      if (setting.isAuthorize('saleItem', 'transactionReport'))
        ItemSalesTransactionReportWidget(
            key: const ValueKey('brand'),
            controller: controller,
            groupKey: 'brand',
            limit: '5',
            label: 'Merek Terjual Terbanyak'),
      if (setting.isAuthorize('saleItem', 'transactionReport'))
        ItemSalesTransactionReportWidget(
            key: const ValueKey('item_type'),
            controller: controller,
            groupKey: 'item_type',
            limit: '5',
            label: 'Departemen Terjual Terbanyak'),
      if (setting.isAuthorize('saleItem', 'transactionReport'))
        ItemSalesTransactionReportWidget(
            key: const ValueKey('supplier'),
            groupKey: 'supplier',
            controller: controller,
            limit: '5',
            label: 'Supplier Terjual Terbanyak'),
    ];
    arrangeDate('day');

    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  void arrangeDate(String rangeType) {
    var startTime = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);
    var endTime = DateTime.now()
        .copyWith(hour: 6, minute: 59, second: 59, millisecond: 999)
        .add(const Duration(days: 1));
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
    var range = DateTimeRange(start: startTime, end: endTime);
    controller.changeDate(range);
    pickerController.changeDate(range);
    _isCustom = rangeType == 'custom';
  }

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
                    constraints: const BoxConstraints(maxWidth: 400),
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
