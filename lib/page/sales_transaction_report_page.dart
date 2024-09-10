import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/sync_data_table.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';
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

class _SalesTransactionReportPageState extends State<SalesTransactionReportPage>
    with AutomaticKeepAliveClientMixin {
  late DateTimeRange range;
  late Server server;
  List requestControllers = [];
  late Flash flash;
  late List<TableColumn> columns;
  List<SalesTransactionReport> salesTransactionReports = [];
  late final PlutoGridStateManager? stateManager;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    var now = DateTime.now().toUtc();
    range = DateTimeRange(
        start: beginningOfDay(now.copyWith(day: 1)),
        end: endOfDay(now
            .copyWith(month: now.month + 1, day: 1)
            .subtract(const Duration(days: 1))));
    flash = Flash(context);
    server = context.read<Server>();
    final setting = context.read<Setting>();
    columns = setting.tableColumn('salesTransactionReport');
    super.initState();
    Future.delayed(Duration.zero, () => _refreshTable(range));
  }

  @override
  void dispose() {
    super.dispose();
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
    salesTransactionReports = <SalesTransactionReport>[];

    stateManager?.removeAllRows();

    while (start.isBefore(end)) {
      var rowDateRange =
          DateTimeRange(start: beginningOfDay(start), end: endOfDay(start));

      var request = _requestReport(rowDateRange).then((response) {
        if (response.statusCode != 200) return;
        var data = response.data['data'];
        final salesTransactionReport = SalesTransactionReport.fromJson(data);
        setState(() {
          stateManager?.appendModel(salesTransactionReport);
        });
      },
          onError: (error, trace) =>
              server.defaultErrorResponse(context: context, error: error));
      requestControllers.add(request);
      start = start.add(const Duration(days: 1));
    }
    Future.delayed(const Duration(seconds: 2), (() {
      setState(() {
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
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 350,
              child: DateRangeFormField(
                initialDateRange: range,
                datePickerOnly: true,
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
            const Divider(),
            SizedBox(
              height: 400,
              child: SyncDataTable2<SalesTransactionReport>(
                rows: salesTransactionReports,
                columns: columns,
                fixedLeftColumns: 1,
                onLoaded: (state) => stateManager = state,
                showSummary: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
