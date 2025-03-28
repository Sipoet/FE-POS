import 'package:collection/collection.dart';
import 'package:fe_pos/tool/custom_type.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/color_field.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';
import 'package:fe_pos/model/sales_transaction_report.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fl_chart/fl_chart.dart';

class SalesTransactionGraphPage extends StatefulWidget {
  const SalesTransactionGraphPage({super.key});

  @override
  State<SalesTransactionGraphPage> createState() =>
      _SalesTransactionGraphPageState();
}

class _SalesTransactionGraphPageState extends State<SalesTransactionGraphPage>
    with
        AutomaticKeepAliveClientMixin,
        DefaultResponse,
        TextFormatter,
        LoadingPopup {
  late DateTimeRange range;
  late final Server server;
  late final Setting setting;
  late Flash flash;
  String fieldKey = 'sales_total';
  List<Color> colors = [
    Colors.green,
    Colors.blue,
    Colors.red,
    Colors.yellow,
    Colors.purple,
    Colors.brown,
    Colors.black,
    Colors.orange,
    Colors.cyan,
    Colors.lightGreen,
  ];
  List<DateTimeRange> dateRanges = [
    DateTimeRange(
        start: DateTime.now().beginningOfMonth(),
        end: DateTime.now().endOfMonth()),
  ];
  List<List<SalesTransactionReport>> matrix = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    flash = Flash();
    server = context.read<Server>();
    setting = context.read<Setting>();
    super.initState();
    // Future.delayed(Duration.zero, () => _refreshGraph());
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future _refreshGraph() async {
    showLoadingPopup();
    matrix = [];
    for (final (int index, DateTimeRange dateRange) in dateRanges.indexed) {
      matrix.add(await _fetchGraph(dateRange, index));
    }
    setState(() {
      matrix = matrix;
    });
  }

  Future<List<SalesTransactionReport>> _fetchGraph(
      DateTimeRange range, index) async {
    var response =
        await server.get('sales/daily_transaction_report', queryParam: {
      'start_date': range.start.toIso8601String(),
      'end_date': range.end.toIso8601String(),
    });

    if (response.statusCode != 200) return [];
    var data = response.data['data'] as List;
    return data
        .map<SalesTransactionReport>(
            (line) => SalesTransactionReport.fromJson(line))
        .toList();
  }

  double _valueOf(SalesTransactionReport report, String keyF) {
    var value = report[keyF];
    if (value is double) {
      return value;
    } else if (value is Money || value is Percentage) {
      return value.value;
    } else if (value is int) {
      return value.toDouble();
    } else {
      return double.parse(value);
    }
  }

  // double _dateIndexOf(DateTime date) {
  //   return
  // }

  String _tooltipFormat(double value) {
    if (fieldKey == 'num_of_transaction') {
      return numberFormat(value);
    } else {
      return moneyFormat(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    double height =
        MediaQuery.sizeOf(context).height - padding.top - padding.bottom - 350;
    height = height < 285 ? 285 : height;
    super.build(context);
    return VerticalBodyScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grafik Penjualan'),
              IconButton(
                onPressed: () => setState(() {
                  if (dateRanges.length > 5) {
                    return;
                  }
                  dateRanges.add(DateTimeRange(
                      start: DateTime.now().beginningOfDay(),
                      end: DateTime.now().endOfDay()));
                }),
                icon: Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Table(
            columnWidths: {2: FixedColumnWidth(50.0)},
            children: dateRanges
                .mapIndexed<TableRow>(
                  (index, dateRange) => TableRow(
                    children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: DateRangeFormField(
                              initialDateRange: dateRange,
                              onChanged: (range) => setState(() {
                                    dateRanges[index] = range ?? dateRange;
                                  })),
                        ),
                      ),
                      TableCell(
                        child: ColorField(
                          initialValue: colors[index],
                          onChanged: (Color value) {
                            setState(() {
                              colors[index] = value;
                            });
                          },
                        ),
                      ),
                      TableCell(
                          child: dateRanges.length == 1
                              ? SizedBox()
                              : IconButton(
                                  onPressed: () => setState(() {
                                        dateRanges.removeAt(index);
                                      }),
                                  icon: Icon(Icons.close)))
                    ],
                  ),
                )
                .toList(),
          ),
          const SizedBox(
            height: 10,
          ),
          DropdownMenu(
              label: Text('Berdasarkan'),
              initialSelection: fieldKey,
              onSelected: (value) => setState(() {
                    fieldKey = value ?? 'sales_total';
                  }),
              dropdownMenuEntries: [
                DropdownMenuEntry(
                    value: 'sales_total', label: 'Total Penjualan'),
                DropdownMenuEntry(
                    value: 'num_of_transaction', label: 'Total Transaksi'),
                DropdownMenuEntry(
                    value: 'discount_total', label: 'Total Diskon'),
                DropdownMenuEntry(value: 'gross_profit', label: 'Gross Profit'),
                DropdownMenuEntry(
                    value: 'cash_total', label: 'Total Bayar Tunai'),
                DropdownMenuEntry(
                    value: 'debit_total', label: 'Total Bayar Kartu Debit'),
                DropdownMenuEntry(
                    value: 'credit_total', label: 'Total Bayar Kartu Kredit'),
                DropdownMenuEntry(
                    value: 'qris_total', label: 'Total Bayar dengan Qris'),
                DropdownMenuEntry(
                    value: 'online_total',
                    label: 'Total bayar dengan Online Transfer'),
              ]),
          const SizedBox(
            height: 10,
          ),
          ElevatedButton(
              onPressed: () =>
                  _refreshGraph().whenComplete(() => hideLoadingPopup()),
              child: Text('Refresh')),
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            height: height,
            child: LineChart(
              LineChartData(
                  lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Colors.grey.shade200,
                    getTooltipItems: (touchedSpots) => touchedSpots
                        .map<LineTooltipItem>((spot) => LineTooltipItem(
                            _tooltipFormat(spot.y),
                            TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colors[spot.barIndex])))
                        .toList(),
                  )),
                  lineBarsData: matrix
                      .mapIndexed<LineChartBarData>((index, row) =>
                          LineChartBarData(
                            // isCurved: true,
                            color: colors[index],
                            spots: row
                                .mapIndexed<FlSpot>((int index,
                                        SalesTransactionReport
                                            salesTransactionReport) =>
                                    FlSpot(
                                        (index + 1).toDouble(),
                                        _valueOf(
                                            salesTransactionReport, fieldKey)))
                                .toList(),
                          ))
                      .toList()
                  // read about it in the LineChartData section
                  ),
              duration: Duration(milliseconds: 150),
              curve: Curves.linear,
            ),
          ),
        ],
      ),
    );
  }
}
