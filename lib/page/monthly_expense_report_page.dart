import 'package:collection/collection.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:fe_pos/model/monthly_expense_report.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';
import 'package:fe_pos/widget/sales_performance_chart.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MonthlyExpenseReportPage extends StatefulWidget {
  const MonthlyExpenseReportPage({super.key});

  @override
  State<MonthlyExpenseReportPage> createState() =>
      _MonthlyExpenseReportPageState();
}

class _MonthlyExpenseReportPageState extends State<MonthlyExpenseReportPage>
    with TextFormatter {
  static const TextStyle _filterLabelStyle =
      TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
  late final Server server;
  late final Setting setting;
  late Flash flash;
  GroupPeriodMonthlyExpenseReport _groupPeriod =
      GroupPeriodMonthlyExpenseReport.monthly;
  List<MonthlyExpenseReport> _reports = [];
  final _chartController = SalesChartController();

  DateTimeRange _range = DateTimeRange(
      start: DateTime.now().beginningOfYear(),
      end: DateTime.now().endOfMonth());

  List<String> _comparisonKeys = [];
  Map<LineTitle, List<FlSpot>> lines = {};
  Map<dynamic, int> reportIndex = {};
  @override
  void initState() {
    flash = Flash();
    server = context.read<Server>();
    setting = context.read<Setting>();
    super.initState();
  }

  void generateReport() async {
    lines = {};
    var identifierList = ['Total Pengeluaran'];

    _reports = await MonthlyExpenseReportClass().groupBy(
            server: server,
            groupPeriod: _groupPeriod.toString(),
            range: _range) ??
        [];
    if (_reports.isEmpty) {
      return;
    }
    reportIndex = {};
    for (final (int index, MonthlyExpenseReport report) in _reports.indexed) {
      reportIndex[report.datePk] = index;
    }
    lines[LineTitle(name: 'Pengeluaran')] = _reports
        .mapIndexed<FlSpot>((int index, MonthlyExpenseReport e) =>
            FlSpot(index.toDouble(), e.total.value))
        .toList();
    for (final key in _comparisonKeys) {
      final response = await fetchSalesPerformance(key);
      if (response.statusCode != 200) {
        continue;
      }
      final detail = response.data['data'].first;
      LineTitle lineTitle = LineTitle(
          name: key.replaceAll('_', ' '),
          description: detail['description'] ?? '');
      final datePkCast = _groupPeriod == GroupPeriodMonthlyExpenseReport.yearly
          ? (String data) => Date.parse('$data-01-01')
          : (String data) => Date.parse('${data.toString()}-01-01');

      lines[lineTitle] = (detail['spots'] as List).map<FlSpot>((spot) {
        final datePk = datePkCast.call(spot[0].toString());
        int xCoord = reportIndex[datePk] ?? -1;
        if (xCoord == -1) {
          debugPrint('spot x ${spot[0]}');
        }
        return FlSpot(xCoord.toDouble(), spot[1]);
      }).toList();
      identifierList.add(lineTitle.name);
    }
    setState(() {
      _chartController.setChartData(
          lines: lines,
          identifierList: identifierList,
          startDate: _range.start,
          endDate: _range.end);
    });
  }

  Future fetchSalesPerformance(String valueType) async {
    return server.get('item_sales_performance_reports/group_by', queryParam: {
      'start_date': _range.start.toIso8601String(),
      'end_date': _range.end.toIso8601String(),
      'group_period': _groupPeriod.toString(),
      'group_type': 'period',
      'value_type': valueType,
      'separate_purchase_year': '0',
    });
  }

  String xFormat(double value, SalesChartController controller) {
    if (_reports.length > value) {
      final data = _reports[value.toInt()];
      if (_groupPeriod == GroupPeriodMonthlyExpenseReport.yearly) {
        return data.year.toString();
      } else if (_groupPeriod == GroupPeriodMonthlyExpenseReport.monthly) {
        return data.datePk.format(pattern: 'MMM y');
      }
      return data.datePk.format();
    } else {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return VerticalBodyScroll(
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.start,
            children: [
              DropdownMenu<GroupPeriodMonthlyExpenseReport>(
                dropdownMenuEntries: GroupPeriodMonthlyExpenseReport.values
                    .map<DropdownMenuEntry<GroupPeriodMonthlyExpenseReport>>(
                      (entry) =>
                          DropdownMenuEntry<GroupPeriodMonthlyExpenseReport>(
                              value: entry, label: entry.humanize()),
                    )
                    .toList(),
                label:
                    const Text('Dipisah Berdasarkan', style: _filterLabelStyle),
                onSelected: (value) {
                  setState(() {
                    _groupPeriod = value ?? _groupPeriod;
                  });
                },
                initialSelection: _groupPeriod,
                width: 250,
                inputDecorationTheme: InputDecorationTheme(
                    isDense: true, border: OutlineInputBorder()),
              ),
              SizedBox(
                  width: 300,
                  child: DateRangeFormField(
                    onChanged: (range) => _range = range ?? _range,
                    label: Text('Rentang Periode'),
                    rangeType: MonthRangeType(),
                    initialDateRange: _range,
                  )),
              SizedBox(
                width: 250,
                child: DropdownSearch<String>.multiSelection(
                  items: (filter, loadProps) => [
                    'gross_profit',
                    'sales_total',
                  ],
                  itemAsString: (item) => item.replaceAll('_', ' '),
                  decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          label: Text(
                            'Pembandingan dengan(Optional)',
                            style: _filterLabelStyle,
                          ))),
                  onChanged: (value) => _comparisonKeys = value,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          ElevatedButton(onPressed: generateReport, child: Text('Generate')),
          const SizedBox(
            height: 10,
          ),
          SalesPerformanceChart(
              xFormat: xFormat,
              controller: _chartController,
              yFormat: compactNumberFormat,
              spotYFormat: moneyFormat),
        ],
      ),
    );
  }
}

enum GroupPeriodMonthlyExpenseReport {
  yearly,
  monthly;

  static const groupPeriodLocales = {
    yearly: 'Tahun',
    monthly: 'Bulan',
  };

  String humanize() {
    return groupPeriodLocales[this] ?? '';
  }

  @override
  String toString() {
    return super.toString().split('.').last.toSnakeCase();
  }
}
