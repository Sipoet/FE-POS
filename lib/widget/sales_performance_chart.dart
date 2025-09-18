import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';
import 'package:fe_pos/tool/custom_type.dart';

class SalesPerformanceChart extends StatefulWidget {
  final List<Widget> filterForm;

  final SalesChartController controller;
  final String Function(double valueX, SalesChartController control) xFormat;
  final String Function(double valueY) yFormat;
  final String Function(double valueY) spotYFormat;
  final String title;
  final String xTitle;
  final int xTitleDividerTotal;

  SalesPerformanceChart({
    super.key,
    this.filterForm = const [],
    SalesChartController? controller,
    this.title = '',
    this.xTitle = '',
    this.xTitleDividerTotal = 4,
    required this.xFormat,
    required this.yFormat,
    required this.spotYFormat,
  }) : controller = controller ?? SalesChartController();

  @override
  State<SalesPerformanceChart> createState() => _SalesPerformanceChartState();
}

class _SalesPerformanceChartState extends State<SalesPerformanceChart> {
  static const TextStyle _filterLabelStyle =
      TextStyle(fontSize: 14, fontWeight: FontWeight.bold);

  String _lastBottomText = '';
  SalesChartController get controller => widget.controller;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
            child: Text(widget.title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        SizedBox(
          height: 25,
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: widget.filterForm,
        ),
        const SizedBox(height: 10),
        Visibility(
            visible: controller.filteredDetails.isNotEmpty,
            child: RichText(
                text: TextSpan(
                    text: 'Filter: ',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                    children: [
                  TextSpan(
                      text: controller.filteredDetails.join(', '),
                      style: TextStyle(fontWeight: FontWeight.normal))
                ]))),
        const SizedBox(height: 10),
        Visibility(
          visible: !controller.isLoading && controller.lines.isEmpty,
          child: Center(child: Text('Data Tidak Ditemukan')),
        ),
        Visibility(
          visible: !controller.isLoading && controller.lines.isNotEmpty,
          child: Column(
            children: [
              Center(
                child: Text(
                  "Tanggal: ${controller.startDate?.format(pattern: 'dd/MM/y')} - ${controller.endDate?.format(pattern: 'dd/MM/y')}",
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 50.0),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: controller.lineTitles
                      .mapIndexed((int index, LineTitle lineTitle) {
                    return Tooltip(
                      message: lineTitle.description,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 10,
                            color: getLineColor(index),
                          ),
                          const SizedBox(width: 5),
                          Text(lineTitle.name),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(right: 20, bottom: 10),
                child: SizedBox(
                  height: 500,
                  child: LineChart(LineChartData(
                    minY: 0,
                    lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                      fitInsideHorizontally: true,
                      maxContentWidth: 220,
                      getTooltipColor: (touchedSpot) => Colors.grey.shade900,
                      getTooltipItems: (touchedSpots) => touchedSpots
                          .mapIndexed<LineTooltipItem>(
                              (int index, LineBarSpot spot) {
                        final formattedYValue = widget.spotYFormat(spot.y);
                        if (index == 0) {
                          return LineTooltipItem(
                              "- ${xFormatDetail(spot.x).toString()} -",
                              TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white),
                              textAlign: TextAlign.right,
                              children: [
                                TextSpan(
                                    text:
                                        "\n ${controller._lineTitles[spot.barIndex].name}: $formattedYValue",
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 16,
                                        color: getLineColor(spot.barIndex))),
                              ]);
                        }

                        return LineTooltipItem(
                          "${controller._lineTitles[spot.barIndex].name}: $formattedYValue",
                          TextStyle(
                              height: formattedYValue.isEmpty ? 0 : null,
                              fontWeight: FontWeight.normal,
                              fontSize: formattedYValue.isEmpty ? 0 : 16,
                              color: getLineColor(spot.barIndex)),
                          textAlign: TextAlign.right,
                        );
                      }).toList(),
                    )),
                    lineBarsData: controller.lines
                        .mapIndexed(
                          (int index, List<FlSpot> spots) => LineChartBarData(
                            color: getLineColor(index),
                            barWidth: 2,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(show: false),
                            isCurved: false,
                            spots: spots,
                          ),
                        )
                        .toList(),
                    titlesData: FlTitlesData(
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: false, reservedSize: 50)),
                      bottomTitles: AxisTitles(
                        axisNameWidget: Text(
                          widget.xTitle,
                          style: _filterLabelStyle,
                        ),
                        axisNameSize: 22,
                        sideTitles: SideTitles(
                            getTitlesWidget: getBottomTitles,
                            showTitles: true,
                            maxIncluded: true,
                            minIncluded: true,
                            reservedSize: 35),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                            getTitlesWidget: getLeftTitles,
                            showTitles: true,
                            // maxIncluded: true,
                            minIncluded: false,
                            reservedSize: 50),
                      ),
                    ),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(
                        show: true,
                        border: Border(
                            left: BorderSide(color: Colors.black87),
                            bottom: BorderSide(color: Colors.black87),
                            top: BorderSide.none,
                            right: BorderSide.none)),
                  )),
                ),
              ),
            ],
          ),
        ),
        Visibility(
          visible: controller.isLoading,
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      ],
    );
  }

  Color getLineColor(int index) {
    return Colors.primaries[index % Colors.primaries.length];
  }

  SideTitleWidget getBottomTitles(double valueX, TitleMeta meta) {
    final text = bottomText(valueX, meta);
    return SideTitleWidget(
      meta: meta,
      fitInside:
          SideTitleFitInsideData.fromTitleMeta(meta, distanceFromEdge: 0),
      space: 10,
      child: Text(text),
    );
  }

  String xFormatDetail(double valueX) {
    return widget.xFormat(valueX, controller);
  }

  String bottomText(double valueX, TitleMeta meta) {
    if (valueX == meta.min) {
      _lastBottomText = xFormatDetail(valueX);
      return _lastBottomText;
    }
    if ((meta.max - valueX).abs() <= 0.01) {
      _lastBottomText = xFormatDetail(meta.max);
      return _lastBottomText;
    }

    if (xFormatDetail(valueX) == xFormatDetail(meta.max)) {
      return '';
    }
    double lengthSep = (((meta.max - meta.min) / widget.xTitleDividerTotal) *
            (controller.visibleBottomTitles.length + 1))
        .ceilToDouble();
    if (controller.visibleBottomTitles.contains(valueX)) {
      return xFormatDetail(valueX);
    }
    if (controller.visibleBottomTitles.length <= widget.xTitleDividerTotal &&
        _lastBottomText != xFormatDetail(valueX) &&
        (valueX - meta.min) >= (lengthSep - 0.01)) {
      controller.visibleBottomTitles.add(valueX);
      _lastBottomText = xFormatDetail(valueX);

      return _lastBottomText;
    }
    return '';
  }

  Widget getLeftTitles(double valueY, TitleMeta meta) {
    final text = widget.yFormat(valueY);
    return SideTitleWidget(
      meta: meta,
      space: 5,
      child: Text(text),
    );
  }
}

class LineTitle {
  final String name;
  final String description;
  const LineTitle({required this.name, this.description = ''});
}

class SalesChartController with ChangeNotifier {
  bool _isLoading = false;
  List<List<FlSpot>> _lines = [];
  List<LineTitle> _lineTitles = [];
  List<String> _identifierList = [];
  List<String> _filteredDetails = [];
  List visibleBottomTitles = [];

  DateTime? _startDate;
  DateTime? _endDate;

  get isLoading => _isLoading;
  List<List<FlSpot>> get lines => _lines;
  List<LineTitle> get lineTitles => _lineTitles;
  List<String> get identifierList => _identifierList;
  List<String> get filteredDetails => _filteredDetails;

  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  set isLoading(value) {
    _isLoading = value;
    notifyListeners();
  }

  void setChartData({
    required Map<LineTitle, List<FlSpot>> lines,
    required List<String> identifierList,
    required DateTime startDate,
    required DateTime endDate,
    List<String> filteredDetails = const [],
  }) {
    visibleBottomTitles.clear();
    _lines = lines.values.toList();
    _lineTitles = lines.keys.toList();
    _identifierList = identifierList;
    _startDate = startDate;
    _endDate = endDate;
    _filteredDetails = filteredDetails;
    notifyListeners();
  }
}
