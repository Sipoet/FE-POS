import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/custom_data_table.dart';
import 'package:fe_pos/widget/date_range_picker.dart';
import 'package:fe_pos/model/sales_transaction_report.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class SalesTransactionReportPage extends StatefulWidget {
  const SalesTransactionReportPage({super.key});

  @override
  State<SalesTransactionReportPage> createState() =>
      _SalesTransactionReportPageState();
}

class _SalesTransactionReportPageState
    extends State<SalesTransactionReportPage> {
  late DateTimeRange range;
  late Server server;
  bool _isDisplayTable = false;
  List requestControllers = [];
  final dataSource = CustomDataTableSource<SalesTransactionReport>();
  late Flash flash;

  @override
  void initState() {
    var now = DateTime.now().toUtc();
    range = DateTimeRange(
        start: beginningOfDay(now.copyWith(day: 1)),
        end: endOfDay(now
            .copyWith(month: now.month + 1, day: 1)
            .subtract(const Duration(days: 1))));
    SessionState sessionState = context.read<SessionState>();
    flash = Flash(context);
    server = sessionState.server;
    super.initState();
  }

  Future _requestReport(DateTimeRange dateRange) async {
    return server.get('sales/transaction_report', queryParam: {
      'start_time': dateRange.start.toIso8601String(),
      'end_time': dateRange.end.toIso8601String(),
    });
  }

  void _refreshTable(DateTimeRange range) {
    flash.show(
      const Text('Dalam proses.'),
      MessageType.info,
    );
    var start = range.start;
    var end = range.end;
    List<SalesTransactionReport> rows = <SalesTransactionReport>[];
    while (start.isBefore(end)) {
      var rowDateRange =
          DateTimeRange(start: beginningOfDay(start), end: endOfDay(start));

      var request = _requestReport(rowDateRange).then((response) {
        if (response.statusCode != 200) return;
        var data = response.data['data'];
        rows.add(SalesTransactionReport.fromJson(data));
        dataSource.setData(rows);
      },
          onError: (error, trace) =>
              server.defaultErrorResponse(context: context, error: error));
      requestControllers.add(request);
      start = start.add(const Duration(days: 1));
    }
    Future.delayed(const Duration(seconds: 2), (() {
      setState(() {
        _isDisplayTable = true;
        flash.hide();
      });
    }));
  }

  DateTime beginningOfDay(DateTime date) {
    return date.copyWith(hour: 0, minute: 0, second: 0);
  }

  DateTime endOfDay(DateTime date) {
    return date.copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
  }

  @override
  Widget build(BuildContext context) {
    var setting = context.read<Setting>();
    dataSource.columns = setting.tableColumn('salesTransactionReport');
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 350,
              child: DateRangePicker(
                startDate: range.start,
                endDate: range.end,
                onChanged: (newRange) {
                  range = newRange ??
                      DateTimeRange(start: DateTime.now(), end: DateTime.now());
                  _refreshTable(range);
                },
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: () => {_refreshTable(range)},
              child: const Text('Tampilkan'),
            ),
            if (_isDisplayTable) const Divider(),
            if (_isDisplayTable)
              SizedBox(
                height: 600,
                child: CustomDataTable(
                  controller: dataSource,
                  fixedLeftColumns: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
