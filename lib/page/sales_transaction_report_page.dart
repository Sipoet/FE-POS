import 'package:fe_pos/tool/default_response.dart';
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
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late DateTimeRange range;
  late Server server;
  late Flash flash;
  late List<TableColumn> columns;
  List<SalesTransactionReport> salesTransactionReports = [];
  late final PlutoGridStateManager stateManager;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    final today = Date.today();
    var now = DateTime.utc(today.year, today.month, today.day);
    range = DateTimeRange(
        start: beginningOfDay(now.copyWith(day: 1)),
        end: endOfDay(now
            .copyWith(month: now.month + 1, day: 1)
            .subtract(const Duration(days: 1))));
    flash = Flash();
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

  void _refreshTable(DateTimeRange range) {
    stateManager.setShowLoading(true);
    server.get('sales/daily_transaction_report', queryParam: {
      'start_date': range.start.toIso8601String(),
      'end_date': range.end.toIso8601String(),
    }).then((response) {
      if (response.statusCode != 200) return;
      var data = response.data['data'];
      setState(() {
        salesTransactionReports = data
            .map<SalesTransactionReport>(
                (line) => SalesTransactionReport.fromJson(line))
            .toList();
        stateManager.setModels(salesTransactionReports, columns);
        debugPrint('total rows ${salesTransactionReports.length.toString()}');
      });
    },
        onError: (error, trace) =>
            defaultErrorResponse(error: error)).whenComplete(
        () => stateManager.setShowLoading(false));
  }

  DateTime beginningOfDay(DateTime date) {
    return date.copyWith(hour: 0, minute: 0, second: 0);
  }

  DateTime endOfDay(DateTime date) {
    return date.copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    double height =
        MediaQuery.sizeOf(context).height - padding.top - padding.bottom - 250;
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
            const Divider(),
            SizedBox(
              height: height,
              child: SyncDataTable2<SalesTransactionReport>(
                rows: salesTransactionReports,
                columns: columns,
                fixedLeftColumns: 2,
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
