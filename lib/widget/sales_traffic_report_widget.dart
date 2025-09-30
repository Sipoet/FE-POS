import 'package:fe_pos/tool/transaction_report_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/tool/text_formatter.dart';

class SalesTrafficReportWidget extends StatefulWidget {
  final TransactionReportController controller;
  const SalesTrafficReportWidget({super.key, required this.controller});

  @override
  State<SalesTrafficReportWidget> createState() =>
      _SalesTrafficReportWidgetState();
}

class _SalesTrafficReportWidgetState extends State<SalesTrafficReportWidget>
    with TextFormatter, AutomaticKeepAliveClientMixin {
  String _valueType = 'sales_total';
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
  List<LineChartBarData> lineBarsData = [];
  @override
  void initState() {
    widget.controller.addListener(fetchReport);
    fetchReport();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Card(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Trafik Penjualan'),
                  IconButton.filled(
                      tooltip: 'Refresh Laporan',
                      alignment: Alignment.centerRight,
                      onPressed: refreshReport,
                      icon: const Icon(Icons.refresh_rounded))
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Divider(),
              DropdownMenu(
                dropdownMenuEntries: [
                  DropdownMenuEntry(
                      value: 'sales_total', label: 'Total Penjualan'),
                  DropdownMenuEntry(value: 'quantity', label: 'Jumlah Terjual'),
                ],
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  isDense: true,
                ),
                label: const Text('Berdasarkan'),
                onSelected: (value) {
                  setState(() {
                    _valueType = value ?? _valueType;
                  });
                  fetchReport();
                },
                initialSelection: _valueType,
              ),
              SizedBox(
                height: 10,
              ),
              LineChart(
                LineChartData(
                    titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                            axisNameWidget: Text('Title'),
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text('');
                              },
                            ))),
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
                    lineBarsData: lineBarsData),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  String _tooltipFormat(double value) {
    if (_valueType == 'num_of_transaction') {
      return numberFormat(value);
    } else {
      return moneyFormat(value);
    }
  }

  void refreshReport() {}
  void fetchReport() async {}
}
