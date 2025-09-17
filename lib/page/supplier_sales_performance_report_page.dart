import 'package:dropdown_search/dropdown_search.dart';
import 'package:fe_pos/model/item.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/sales_performance_chart.dart';
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
  List<Supplier> _comparatorSuppliers = [];
  Supplier? _supplier;
  List<ItemType> _itemTypes = [];
  late final Server server;
  bool _separatePurchaseYear = false;
  String _valueType = 'sales_total';
  String _groupPeriod = 'daily';
  List<Color> lineColors = [];
  String _rangePeriod = 'month';

  final periodList = ['day', 'week', 'month', 'year', '5_year', 'all'];
  List<bool> _selectedPeriod = [false, false, true, false, false, false];
  List<bool> _selectedPeriod2 = [false, false, true, false, false, false];
  String _rangePeriod2 = 'month';
  String _valueType2 = 'sales_total';

  final _formKey = GlobalKey<FormState>();

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
                    child: AsyncDropdown<Supplier>(
                        label: const Text('Pilih Supplier'),
                        allowClear: false,
                        textOnSearch: (supplier) =>
                            "${supplier.code} - ${supplier.name}",
                        path: '/suppliers',
                        onChanged: (value) => _supplier = value,
                        validator: (model) {
                          if (model == null) {
                            return 'harus diisi';
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
                        setState(() {
                          _hasGenerateOnce = true;
                          _generatedGroupedPeriod = _groupPeriod;
                        });
                        generateCompareReport();
                        generateGroupByItemTypeReport();
                      }
                    },
                    child: const Text('Generate Report'),
                  ),
                  const Divider(),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Visibility(
              visible: _hasGenerateOnce,
              child: Column(
                children: [
                  Card(child: groupByItemTypeChart()),
                  Card(child: groupByBrandChart()),
                  Card(child: compareSupplierChart()),
                ],
              ),
            ),

            // LineChat
          ],
        ),
      ),
    );
  }

  final supplierChartController = SalesChartController();
  Widget compareSupplierChart() {
    return SalesPerformanceChart(
        title: 'Grafik Perbandingan Supplier',
        controller: supplierChartController,
        xTitle: _generatedGroupedPeriod == 'weekly' ? 'MINGGU' : 'PERIODE',
        filterForm: [
          SizedBox(
            width: 350,
            child: AsyncDropdownMultiple<Supplier>(
                label: const Text('Perbandingan Supplier'),
                textOnSearch: (supplier) =>
                    "${supplier.code} - ${supplier.name}",
                path: '/suppliers',
                onChanged: (value) {
                  _comparatorSuppliers = value;
                  generateCompareReport();
                },
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
          DropdownMenu(
            dropdownMenuEntries: [
              DropdownMenuEntry(
                  value: 'sales_quantity', label: 'Jumlah Penjualan'),
              DropdownMenuEntry(
                  value: 'sales_total', label: 'Total Penjualan (Rp)'),
              DropdownMenuEntry(
                  value: 'sales_discount_amount', label: 'Total Diskon (Rp)'),
              DropdownMenuEntry(
                  value: 'sales_through_rate', label: 'Kecepatan Penjualan(%)'),
            ],
            label: const Text('Nilai Berdasarkan', style: _filterLabelStyle),
            onSelected: (value) {
              setState(() {
                _valueType = value ?? _valueType;
              });
              generateCompareReport();
            },
            initialSelection: _valueType,
            width: 300,
            inputDecorationTheme: InputDecorationTheme(
                isDense: true, border: OutlineInputBorder()),
          ),
          SizedBox(
            width: 400,
            height: 90,
            child: Stack(
              children: [
                Text(
                  'Periode',
                  style: _filterLabelStyle,
                ),
                Positioned(
                  top: 20,
                  child: ToggleButtons(
                    onPressed: (int index) {
                      final rangePeriodBefore = _rangePeriod;
                      if (rangePeriodBefore != periodList[index]) {
                        setState(() {
                          _selectedPeriod = List.generate(
                              periodList.length, (idx) => index == idx);
                          _rangePeriod = periodList[index];
                        });
                        generateCompareReport();
                      }
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
                ),
              ],
            ),
          ),
        ],
        xFormat: (double valueX, SalesChartController control) =>
            xFormatBasedPeriod(valueX, control.identifierList,
                control.startDate ?? DateTime.now()),
        spotYFormat: (value) => _tooltipFormat(value, _valueType),
        yFormat: compactNumberFormat);
  }

  Widget groupByBrandChart() {
    return Visibility(child: Text(''));
  }

  final SalesChartController itemTypeChartController = SalesChartController();
  Widget groupByItemTypeChart() {
    return SalesPerformanceChart(
        title: 'Grafik Jenis/Departemen Berdasarkan Supplier',
        controller: itemTypeChartController,
        xTitle: _generatedGroupedPeriod == 'weekly' ? 'MINGGU' : 'PERIODE',
        filterForm: [
          DropdownMenu(
            dropdownMenuEntries: [
              DropdownMenuEntry(
                  value: 'sales_quantity', label: 'Jumlah Penjualan'),
              DropdownMenuEntry(
                  value: 'sales_total', label: 'Total Penjualan (Rp)'),
              DropdownMenuEntry(
                  value: 'sales_discount_amount', label: 'Total Diskon (Rp)'),
              DropdownMenuEntry(
                  value: 'sales_through_rate', label: 'Kecepatan Penjualan(%)'),
            ],
            label: const Text('Nilai Berdasarkan', style: _filterLabelStyle),
            onSelected: (value) {
              setState(() {
                _valueType2 = value ?? _valueType2;
              });
              generateGroupByItemTypeReport();
            },
            initialSelection: _valueType2,
            width: 300,
            inputDecorationTheme: InputDecorationTheme(
                isDense: true, border: OutlineInputBorder()),
          ),
          SizedBox(
            width: 400,
            height: 90,
            child: Stack(
              children: [
                Text(
                  'Periode',
                  style: _filterLabelStyle,
                ),
                Positioned(
                  top: 20,
                  child: ToggleButtons(
                    onPressed: (int index) {
                      final rangePeriodBefore = _rangePeriod2;
                      if (rangePeriodBefore != periodList[index]) {
                        setState(() {
                          _selectedPeriod2 = List.generate(
                              periodList.length, (idx) => index == idx);
                          _rangePeriod2 = periodList[index];
                        });
                        generateGroupByItemTypeReport();
                      }
                    },
                    color: Colors.grey,
                    selectedColor: Colors.black,
                    fillColor: Colors.blue.shade200,
                    borderRadius: BorderRadius.circular(5),
                    hoverColor: Colors.green.shade300,
                    isSelected: _selectedPeriod2,
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
                ),
              ],
            ),
          ),
        ],
        xFormat: (double valueX, SalesChartController control) =>
            xFormatBasedPeriod(valueX, control.identifierList,
                control.startDate ?? DateTime.now()),
        spotYFormat: (value) => _tooltipFormat(value, _valueType2),
        yFormat: compactNumberFormat);
  }

  String _tooltipFormat(double value, String valueType) {
    switch (valueType) {
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

  void generateCompareReport() async {
    final response = await fetchCompareData();
    if (response.statusCode != 200) {
      setState(() {
        supplierChartController.isLoading = false;
      });
      return;
    }
    final data = response.data;
    final metadata = data['metadata'];
    final startDate = DateTime.parse(metadata['start_date']);
    final endDate = DateTime.parse(metadata['end_date']);
    final identifierList =
        metadata['identifier_list'].map<String>((e) => e.toString()).toList();
    final filteredDetails = getFilteredTitle(data);

    Map<LineTitle, List<FlSpot>> lines = {};
    for (var detail in data['data']) {
      String name, description;
      if (detail['last_purchase_year'] == null) {
        name = detail['supplier_code'];
        description = detail['supplier_name'];
      } else {
        name = "${detail['supplier_code']} (${detail['last_purchase_year']})";
        description =
            "${detail['supplier_name']} (${detail['last_purchase_year']})";
      }
      LineTitle lineTitle = LineTitle(name: name, description: description);
      lines[lineTitle] = convertDataToSpots(detail['spots'], identifierList);
    }
    setState(() {
      supplierChartController.setChartData(
          lines: lines,
          filteredDetails: filteredDetails,
          identifierList: identifierList,
          startDate: startDate,
          endDate: endDate);
      supplierChartController.isLoading = false;
    });
  }

  void generateGroupByItemTypeReport() async {
    setState(() {
      itemTypeChartController.isLoading = true;
    });
    final response = await fetchGroupByItemTypeData();
    if (response.statusCode != 200) {
      setState(() {
        itemTypeChartController.isLoading = false;
      });
      return;
    }
    final data = response.data;
    final metadata = data['metadata'];
    final startDate = DateTime.parse(metadata['start_date']);
    final endDate = DateTime.parse(metadata['end_date']);
    final identifierList =
        metadata['identifier_list'].map<String>((e) => e.toString()).toList();
    final filteredDetails = getFilteredTitle(data);
    Map<LineTitle, List<FlSpot>> lines = {};
    for (var detail in data['data']) {
      String name, description;
      if (detail['last_purchase_year'] == null) {
        name = detail['item_type_name'];
        description = detail['item_type_description'];
      } else {
        name = "${detail['item_type_name']} (${detail['last_purchase_year']})";
        description =
            "${detail['item_type_description']} (${detail['last_purchase_year']})";
      }
      LineTitle lineTitle = LineTitle(name: name, description: description);
      lines[lineTitle] = convertDataToSpots(detail['spots'], identifierList);
    }
    setState(() {
      itemTypeChartController.setChartData(
          lines: lines,
          filteredDetails: filteredDetails,
          identifierList: identifierList,
          startDate: startDate,
          endDate: endDate);
      itemTypeChartController.isLoading = false;
    });
  }

  String xFormatBasedPeriod(
      double valueX, List identifierList, DateTime startDate) {
    final datePk = identifierList[valueX.round()];
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
        if (date.year == startDate.year) {
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

  Map<String, List<FlSpot>> getLines(List data, List identifierList) {
    Map<String, List<FlSpot>> lines = {};
    for (var detail in data) {
      String name;
      if (detail['last_purchase_year'] == null) {
        name = detail['item_type_name'];
      } else {
        name = "${detail['item_type_name']} (${detail['last_purchase_year']})";
      }
      lines[name] = convertDataToSpots(detail['spots'], identifierList);
    }
    return lines;
  }

  Color getLineColor(int index) {
    return Colors.primaries[index % Colors.primaries.length];
  }

  List<FlSpot> convertDataToSpots(List data, List identifierList) {
    return data.map<FlSpot>((e) {
      final x = convertDateToCoordData(e[0].toString(), identifierList);
      final y = e[1];
      return FlSpot(x, y);
    }).toList();
  }

  double convertDateToCoordData(String dateStr, List identifierList) {
    return identifierList.indexOf(dateStr).toDouble();
  }

  List<String> getFilteredTitle(data) {
    List<String> filteredDetails = [];
    final metadata = data['metadata'];

    if (metadata['brand_names']?.isNotEmpty ?? false) {
      filteredDetails.add("Merek ${metadata['brand_names'].join(', ')}");
    }
    if (metadata['item_type_names']?.isNotEmpty ?? false) {
      filteredDetails
          .add("Jenis/ Departmen: ${metadata['item_type_names'].join(', ')}");
    }
    if (metadata['last_purchase_years']?.isNotEmpty ?? false) {
      filteredDetails.add(
          "Tahun Beli Terakhir: ${metadata['last_purchase_years'].join(', ')}");
    }
    return filteredDetails;
  }

  Future fetchCompareData() async {
    var supplierCodes =
        _comparatorSuppliers.map<String>((e) => e.code).toList();
    if (_supplier != null && !supplierCodes.contains(_supplier!.code)) {
      supplierCodes.add(_supplier!.code);
    }
    return server
        .get('supplier_sales_performance_reports/compare', queryParam: {
      'brands[]': _brands.map<String>((e) => e.name).toList(),
      'suppliers[]': supplierCodes,
      'item_types[]': _itemTypes.map<String>((e) => e.name).toList(),
      'range_period': _rangePeriod,
      'group_period': _groupPeriod,
      'value_type': _valueType,
      'last_purchase_years[]':
          _lastPurchaseYears.map<String>((e) => e.toString()).toList(),
      'separate_purchase_year': _separatePurchaseYear ? '1' : '0',
    });
  }

  Future fetchGroupByItemTypeData() async {
    return server.get('supplier_sales_performance_reports/group_by_item_type',
        queryParam: {
          'brands[]': _brands.map<String>((e) => e.name).toList(),
          'supplier_code': _supplier?.code,
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
