import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/sync_data_table.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';
import 'package:fe_pos/model/sales_transaction_report.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
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
  late DateTimeRange<Date> range;
  late Server server;
  late Flash flash;
  late List<TableColumn> columns;
  List<SalesTransactionReport> salesTransactionReports = [];
  late final TableController stateManager;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    final today = Date.today();
    range = DateTimeRange<Date>(
      start: today.beginningOfMonth(),
      end: today.endOfMonth(),
    );
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
    server
        .get(
          'ipos/sales/daily_transaction_report',
          queryParam: {
            'start_date': range.start.toIso8601String(),
            'end_date': range.end.toIso8601String(),
          },
        )
        .then((response) {
          if (response.statusCode != 200) return;
          var data = response.data['data'];
          setState(() {
            salesTransactionReports = data
                .map<SalesTransactionReport>(
                  (line) => SalesTransactionReportClass().fromJson(line),
                )
                .toList();
            stateManager.setModels(salesTransactionReports);
          });
        }, onError: (error, trace) => defaultErrorResponse(error: error))
        .whenComplete(() => stateManager.setShowLoading(false));
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    double height =
        MediaQuery.sizeOf(context).height - padding.top - padding.bottom - 250;
    height = height < 285 ? 285 : height;
    super.build(context);
    return VerticalBodyScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 350,
            child: DateRangeFormField<Date>(
              rangeType: DateRangeType(),
              initialValue: range,
              onChanged: (newRange) {
                range =
                    newRange ??
                    DateTimeRange(start: Date.today(), end: Date.today());
                _refreshTable(range);
              },
            ),
          ),
          const Divider(),
          SizedBox(
            height: height,
            child: SyncDataTable<SalesTransactionReport>(
              rows: salesTransactionReports,
              columns: columns,
              fixedLeftColumns: 2,
              onLoaded: (state) => stateManager = state,
              showSummary: true,
            ),
          ),
        ],
      ),
    );
  }
}
