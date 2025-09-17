import 'package:collection/collection.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:fe_pos/model/item.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SupplierSalesPerformanceReportPage extends StatefulWidget {
  const SupplierSalesPerformanceReportPage({super.key});

  @override
  State<SupplierSalesPerformanceReportPage> createState() =>
      _SupplierSalesPerformanceReportPageState();
}

class _SupplierSalesPerformanceReportPageState
    extends State<SupplierSalesPerformanceReportPage>
    with TextFormatter, PlatformChecker {
  static const TextStyle _filterLabelStyle =
      TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
  List<Brand> _brands = [];
  List<Supplier> _suppliers = [];
  List<ItemType> _itemTypes = [];
  late final Server server;
  bool _separatePurchaseYear = false;
  String _valueType = 'sales_total';
  String _groupPeriod = 'daily';
  List<Color> lineColors = [];
  List<LineChartBarData> _lineBarsData = [];
  String _rangePeriod = 'month';
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;
  final periodList = ['day', 'week', 'month', 'year', '5_year', 'all'];
  List<bool> _selectedPeriod = [false, false, true, false, false, false];
  List<String> _lineTitles = [];
  final _formKey = GlobalKey<FormState>();
  List<String> _identifierList = [];
  List<String> _lastPurchaseYears = [];
  bool _hasGenerateOnce = false;
  String _generatedGroupedPeriod = '';
  @override
  void initState() {
    server = context.read<Server>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final yearNow = DateTime.now().year;
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 350,
                    child: AsyncDropdownMultiple<Supplier>(
                        label: const Text('Pilih Supplier'),
                        textOnSearch: (supplier) =>
                            "${supplier.code} - ${supplier.name}",
                        path: '/suppliers',
                        onChanged: (value) => _suppliers = value,
                        validator: (models) {
                          if (models == null || models.isEmpty) {
                            return 'harus diisi';
                          }
                          if (models.length > 10) {
                            return 'Maksimal 10 supplier';
                          }
                          return null;
                        },
                        converter: Supplier.fromJson),
                  ),
                  const SizedBox(height: 10),
                  Text('Filter',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                          width: 300,
                          child: AsyncDropdownMultiple<Brand>(
                            label:
                                const Text('Merek :', style: _filterLabelStyle),
                            key: const ValueKey('brandSelect'),
                            textOnSearch: (Brand brand) => brand.name,
                            converter: Brand.fromJson,
                            attributeKey: 'merek',
                            path: '/brands',
                            onChanged: (value) => _brands = value,
                          )),
                      SizedBox(
                          width: 300,
                          child: AsyncDropdownMultiple<ItemType>(
                            label: const Text('Jenis/Departemen :',
                                style: _filterLabelStyle),
                            key: const ValueKey('itemTypeSelect'),
                            textOnSearch: (itemType) =>
                                "${itemType.name} - ${itemType.description}",
                            textOnSelected: (itemType) => itemType.name,
                            converter: ItemType.fromJson,
                            attributeKey: 'jenis',
                            path: '/item_types',
                            onChanged: (value) => _itemTypes = value,
                          )),
                      SizedBox(
                          width: 300,
                          child: DropdownSearch<String>.multiSelection(
                            selectedItems: _lastPurchaseYears,
                            onChanged: (value) => _lastPurchaseYears = value,
                            popupProps: isMobile()
                                ? PopupPropsMultiSelection.dialog(
                                    showSearchBox: true,
                                    showSelectedItems: true,
                                    disableFilter: true,
                                  )
                                : PopupPropsMultiSelection.menu(
                                    showSearchBox: true,
                                    showSelectedItems: true,
                                    disableFilter: true,
                                  ),
                            decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                    label: Text(
                                      'Tahun Beli Terakhir',
                                      style: _filterLabelStyle,
                                    ),
                                    border: const OutlineInputBorder())),
                            items: (searchText, loadProps) {
                              return List<String>.generate(50,
                                      (index) => (yearNow - index).toString())
                                  .where((year) =>
                                      year.contains(searchText) ||
                                      searchText.isEmpty)
                                  .toList();
                            },
                          )),
                      DropdownMenu(
                        dropdownMenuEntries: [
                          DropdownMenuEntry(value: 'hourly', label: 'Jam'),
                          DropdownMenuEntry(value: 'daily', label: 'Harian'),
                          DropdownMenuEntry(value: 'weekly', label: 'Minggu'),
                          DropdownMenuEntry(
                              value: 'dow', label: 'Hari dalam minggu'),
                          DropdownMenuEntry(value: 'monthly', label: 'Bulan'),
                          DropdownMenuEntry(value: 'yearly', label: 'Tahun'),
                        ],
                        label: const Text('Group Periode Berdasarkan',
                            style: _filterLabelStyle),
                        onSelected: (value) {
                          setState(() {
                            _groupPeriod = value ?? _groupPeriod;
                          });
                        },
                        initialSelection: _groupPeriod,
                        width: 300,
                        inputDecorationTheme: InputDecorationTheme(
                            isDense: true, border: OutlineInputBorder()),
                      ),
                      SizedBox(
                        width: 250,
                        child: CheckboxListTile.adaptive(
                            title: Text('Pisah tahun beli'),
                            value: _separatePurchaseYear,
                            onChanged: (value) => setState(() {
                                  _separatePurchaseYear = value ?? false;
                                })),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        generateReport();
                      }
                    },
                    child: const Text('Generate Report'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Visibility(
              visible: _isLoading,
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
            Visibility(
              visible: !_isLoading && _hasGenerateOnce,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownMenu(
                    dropdownMenuEntries: [
                      DropdownMenuEntry(
                          value: 'sales_quantity', label: 'Jumlah Penjualan'),
                      DropdownMenuEntry(
                          value: 'sales_total', label: 'Total Penjualan (Rp)'),
                      DropdownMenuEntry(
                          value: 'sales_discount_amount',
                          label: 'Total Diskon (Rp)'),
                      DropdownMenuEntry(
                          value: 'sales_through_rate',
                          label: 'Kecepatan Penjualan(%)'),
                    ],
                    label: const Text('Nilai Berdasarkan',
                        style: _filterLabelStyle),
                    onSelected: (value) {
                      setState(() {
                        _valueType = value ?? _valueType;
                      });
                      generateReport();
                    },
                    initialSelection: _valueType,
                    width: 300,
                    inputDecorationTheme: InputDecorationTheme(
                        isDense: true, border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  ToggleButtons(
                    onPressed: (int index) {
                      setState(() {
                        _selectedPeriod = List.generate(
                            periodList.length, (idx) => index == idx);
                        _rangePeriod = periodList[index];
                      });
                      generateReport();
                    },
                    color: Colors.grey,
                    selectedColor: Colors.black,
                    fillColor: Colors.blue.shade200,
                    borderRadius: BorderRadius.circular(5),
                    hoverColor: Colors.green.shade300,
                    isSelected: _selectedPeriod,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Text('1 Hari'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Text('1 Minggu'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Text('1 Bulan'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Text('1 Tahun'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Text('5 Tahun'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Text('Semua'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Visibility(
                      visible: filteredDetails.isNotEmpty,
                      child: RichText(
                          text: TextSpan(
                              text: 'Filter: ',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                              children: [
                            TextSpan(
                                text: filteredDetails.join(', '),
                                style: TextStyle(fontWeight: FontWeight.normal))
                          ]))),
                  Center(
                    child: Text(
                        "Tanggal: ${_startDate?.format(pattern: 'dd/MM/y')} - ${_endDate?.format(pattern: 'dd/MM/y')}"),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 50.0),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: _lineTitles.mapIndexed((index, title) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 20,
                              height: 10,
                              color: Colors
                                  .primaries[index % Colors.primaries.length],
                            ),
                            const SizedBox(width: 5),
                            Text(title),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Visibility(
                    visible: _lineBarsData.isEmpty,
                    child: Center(child: Text('Data Tidak Ditemukan')),
                  ),
                  Visibility(
                    visible: _lineBarsData.isNotEmpty,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20, bottom: 10),
                      child: SizedBox(
                        height: 500,
                        child: LineChart(LineChartData(
                          minY: 0,
                          lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                            fitInsideHorizontally: true,
                            getTooltipColor: (touchedSpot) =>
                                Colors.grey.shade200,
                            getTooltipItems: (touchedSpots) => touchedSpots
                                .mapIndexed<LineTooltipItem>(
                                    (int index, LineBarSpot spot) {
                              if (index == 0) {
                                return LineTooltipItem(
                                    "- ${xFormatBasedPeriod(spot.x).toString()} -",
                                    TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black),
                                    textAlign: TextAlign.left,
                                    children: [
                                      TextSpan(
                                          text: "\n ${_tooltipFormat(spot.y)}",
                                          style: TextStyle(
                                              fontWeight: FontWeight.normal,
                                              fontSize: 16,
                                              color:
                                                  getLineColor(spot.barIndex))),
                                    ]);
                              }
                              return LineTooltipItem(
                                _tooltipFormat(spot.y),
                                TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16,
                                    color: getLineColor(spot.barIndex)),
                                textAlign: TextAlign.left,
                              );
                            }).toList(),
                          )),
                          lineBarsData: _lineBarsData,
                          titlesData: FlTitlesData(
                            topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: false, reservedSize: 50)),
                            bottomTitles: AxisTitles(
                              axisNameWidget: Text(
                                _generatedGroupedPeriod == 'weekly'
                                    ? 'MINGGU'
                                    : 'PERIODE',
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
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _tooltipFormat(double value) {
    switch (_valueType) {
      case 'sales_quantity':
        return numberFormat(value);
      case 'sales_through_rate':
        return "${numberFormat(value)}%";
      case 'sales_total':
      case 'sales_discount_amount':
        return moneyFormat(value);
      default:
        return numberFormat(value);
    }
  }

  void generateReport() async {
    setState(() {
      _isLoading = true;
      _hasGenerateOnce = true;
      _visibleBottomTitles.clear();
    });
    final response = await fetchData();
    if (response.statusCode == 200) {
      final data = response.data;
      final metadata = data['metadata'];
      setState(() {
        _generatedGroupedPeriod = _groupPeriod;
        _startDate = DateTime.parse(metadata['start_date']);
        _endDate = DateTime.parse(metadata['end_date']);
        _identifierList = metadata['identifier_list']
            .map<String>((e) => e.toString())
            .toList();
        setLineData(data);
        setTitle(data);
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  int bottomDividerTotal = 6;

  final Set<double> _visibleBottomTitles = {};
  String _lastBottomText = '';

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

  String bottomText(double valueX, TitleMeta meta) {
    if (valueX == meta.min) {
      _lastBottomText = xFormatBasedPeriod(valueX);
      return _lastBottomText;
    }
    if ((meta.max - valueX).abs() <= 0.01) {
      _lastBottomText = xFormatBasedPeriod(meta.max);
      return _lastBottomText;
    }

    if (xFormatBasedPeriod(valueX) == xFormatBasedPeriod(meta.max)) {
      return '';
    }
    double lengthSep = (((meta.max - meta.min) / bottomDividerTotal) *
            (_visibleBottomTitles.length + 1))
        .ceilToDouble();
    debugPrint(
        "lengthSep: $lengthSep valuex ${valueX}  text ${xFormatBasedPeriod(valueX)}");
    if (_visibleBottomTitles.contains(valueX)) {
      return xFormatBasedPeriod(valueX);
    }
    if (_visibleBottomTitles.length <= bottomDividerTotal &&
        _lastBottomText != xFormatBasedPeriod(valueX) &&
        (valueX - meta.min) >= (lengthSep - 0.01)) {
      _visibleBottomTitles.add(valueX);
      _lastBottomText = xFormatBasedPeriod(valueX);

      return _lastBottomText;
    }
    return '';
  }

  String xFormatBasedPeriod(double valueX) {
    final datePk = _identifierList[valueX.round()];
    DateTime date = DateTime.tryParse(datePk) ?? DateTime.now();
    switch (_generatedGroupedPeriod) {
      case 'hourly':
        return TimeOfDay(hour: int.parse(datePk), minute: 0).format24Hour();
      case 'dow':
        return [
          'Min',
          'Sen',
          'Sel',
          'Rab',
          'Kam',
          'Jum',
          'Sab',
        ][int.parse(datePk)];
      case 'daily':
        if (date.year == _startDate!.year) {
          return date.format(pattern: 'dd MMM');
        } else {
          return date.format(pattern: 'dd MMM yy');
        }
      case 'weekly':
        final arr = datePk.split('-');
        return "${arr[1]} ${arr[0]}";
      case 'monthly':
        return date.format(pattern: 'MMM yy');
      case 'yearly':
        return datePk.toString();
      default:
        return '';
    }
  }

  Widget getLeftTitles(double valueY, TitleMeta meta) {
    final text = compactNumberFormat(valueY);
    return SideTitleWidget(
      meta: meta,
      space: 5,
      child: Text(text),
    );
  }

  void setLineData(data) {
    _lineBarsData = [];

    List<LineChartBarData> lineBarsData = [];
    for (var row in data['data']) {
      lineBarsData.add(LineChartBarData(
        color: getLineColor(lineBarsData.length),
        barWidth: 2,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
        isCurved: false,
        spots: convertDataToSpots(row['spots']),
      ));
    }

    _lineBarsData = lineBarsData;
  }

  Color getLineColor(int index) {
    return Colors.primaries[index % Colors.primaries.length];
  }

  List<FlSpot> convertDataToSpots(List data) {
    return data.map<FlSpot>((e) {
      final x = convertDateToCoordData(e[0].toString());
      final y = e[1];
      return FlSpot(x, y);
    }).toList();
  }

  double convertDateToCoordData(String dateStr) {
    return _identifierList.indexOf(dateStr).toDouble();
  }

  List<String> filteredDetails = [];

  void setTitle(data) {
    filteredDetails = [];
    final metadata = data['metadata'];

    if (metadata['brand_names'].isNotEmpty) {
      filteredDetails.add("Merek ${metadata['brand_names'].join(', ')}");
    }
    if (metadata['item_type_names'].isNotEmpty) {
      filteredDetails
          .add("Jenis/ Departmen: ${metadata['item_type_names'].join(', ')}");
    }
    _lineTitles = data['data'].map<String>((detail) {
      if (detail['last_purchase_year'] == null) {
        return "${detail['supplier_code']}-${detail['supplier_name']}";
      } else {
        return "${detail['supplier_code']}-${detail['supplier_name']} (${detail['last_purchase_year']})";
      }
    }).toList();
  }

  Future fetchData() async {
    return server.get('item_sales_performance_reports/supplier', queryParam: {
      'brands[]': _brands.map<String>((e) => e.name).toList(),
      'suppliers[]': _suppliers.map<String>((e) => e.code).toList(),
      'item_types[]': _itemTypes.map<String>((e) => e.name).toList(),
      'range_period': _rangePeriod,
      'group_period': _groupPeriod,
      'value_type': _valueType,
      'last_purchase_years[]':
          _lastPurchaseYears.map<String>((e) => e.toString()).toList(),
      'separate_purchase_year': _separatePurchaseYear ? '1' : '0',
    });
  }
}
