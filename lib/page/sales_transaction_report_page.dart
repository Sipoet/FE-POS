import 'package:fe_pos/tool/datatable.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/widget/date_range_picker.dart';
import 'package:fe_pos/model/sales_transaction_report.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:data_table_2/data_table_2.dart';

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
  String _sortKey = 'start_time';
  bool _sortAscending = true;
  int _columnIndex = 0;
  bool _isDisplayTable = false;
  late List<DataColumn2> _columns;
  List requestControllers = [];
  final dataSource = SalesTransactionDataSource();
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
    dataSource.setKeys([
      'start_time',
      'sales_total',
      'num_of_transaction',
      'discount_total',
      'cash_total',
      'debit_total',
      'credit_total',
      'qris_total',
      'online_total',
    ]);
    _columns = [
      DataColumn2(
        tooltip: 'Tanggal',
        fixedWidth: 160,
        onSort: ((columnIndex, ascending) {
          setState(() {
            _sortKey = 'start_time';
            _columnIndex = columnIndex;
            _sortAscending = ascending;
          });
          dataSource.sortData('start_time', _sortAscending);
        }),
        label: const Text(
          'Tanggal',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn2(
        tooltip: 'Total Penjualan',
        fixedWidth: 200,
        onSort: ((columnIndex, ascending) {
          setState(() {
            _sortKey = 'sales_total';
            _columnIndex = columnIndex;
            _sortAscending = ascending;
          });
          dataSource.sortData('sales_total', _sortAscending);
        }),
        label: const Text(
          'Total Penjualan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn2(
        tooltip: 'Total Transaksi',
        fixedWidth: 185,
        onSort: ((columnIndex, ascending) {
          setState(() {
            _sortKey = 'num_of_transaction';
            _columnIndex = columnIndex;
            _sortAscending = ascending;
          });
          dataSource.sortData('num_of_transaction', _sortAscending);
        }),
        label: const Text(
          'Total Transaksi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn2(
        tooltip: 'Total Diskon',
        fixedWidth: 200,
        onSort: ((columnIndex, ascending) {
          setState(() {
            _sortKey = 'discount_total';
            _columnIndex = columnIndex;
            _sortAscending = ascending;
          });
          dataSource.sortData('discount_total', _sortAscending);
        }),
        label: const Text(
          'Total Diskon',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn2(
        tooltip: 'Total Tunai',
        fixedWidth: 200,
        onSort: ((columnIndex, ascending) {
          setState(() {
            _sortKey = 'cash_total';
            _columnIndex = columnIndex;
            _sortAscending = ascending;
          });
          dataSource.sortData('cash_total', _sortAscending);
        }),
        label: const Text(
          'Total Tunai',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn2(
        tooltip: 'Total Debit',
        fixedWidth: 200,
        onSort: ((columnIndex, ascending) {
          setState(() {
            _sortKey = 'debit_total';
            _columnIndex = columnIndex;
            _sortAscending = ascending;
          });
          dataSource.sortData('debit_total', _sortAscending);
        }),
        label: const Text(
          'Total Debit',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn2(
        tooltip: 'Total Kredit',
        fixedWidth: 200,
        onSort: ((columnIndex, ascending) {
          setState(() {
            _sortKey = 'credit_total';
            _columnIndex = columnIndex;
            _sortAscending = ascending;
          });
          dataSource.sortData('credit_total', _sortAscending);
        }),
        label: const Text(
          'Total Kredit',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn2(
        tooltip: 'Total QRIS',
        fixedWidth: 200,
        onSort: ((columnIndex, ascending) {
          setState(() {
            _sortKey = 'qris_total';
            _columnIndex = columnIndex;
            _sortAscending = ascending;
          });
          dataSource.sortData('qris_total', _sortAscending);
        }),
        label: const Text(
          'Total QRIS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn2(
        tooltip: 'Total Online',
        fixedWidth: 200,
        onSort: ((columnIndex, ascending) {
          setState(() {
            _sortKey = 'online_total';
            _columnIndex = columnIndex;
            _sortAscending = ascending;
          });
          dataSource.sortData('online_total', _sortAscending);
        }),
        label: const Text(
          'Total Online',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    ];
    dataSource.setData([], 'item_code', true);
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
        data['start_time'] = rowDateRange.start.toIso8601String();
        data['end_time'] = rowDateRange.end.toIso8601String();
        rows.add(SalesTransactionReport.fromJson(data));
        dataSource.setData(rows, _sortKey, _sortAscending);
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
    ColorScheme colorScheme = Theme.of(context).colorScheme;
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
                  range = newRange;
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
                child: PaginatedDataTable2(
                  source: dataSource,
                  fixedLeftColumns: 1,
                  sortColumnIndex: _columnIndex,
                  sortAscending: _sortAscending,
                  border: TableBorder.all(
                      width: 1,
                      color: colorScheme.onSecondary.withOpacity(0.3)),
                  empty: const Text('Data tidak ditemukan'),
                  columns: _columns,
                  minWidth: 4000,
                  headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                    return colorScheme.onSecondaryContainer.withOpacity(0.08);
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SalesTransactionDataSource extends Datatable {}
