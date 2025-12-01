import 'package:dropdown_search/dropdown_search.dart';
import 'package:fe_pos/model/item.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/sales_performance_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ItemTypeSalesPerformanceReportPage extends StatefulWidget {
  const ItemTypeSalesPerformanceReportPage({super.key});

  @override
  State<ItemTypeSalesPerformanceReportPage> createState() =>
      _ItemTypeSalesPerformanceReportPageState();
}

class _ItemTypeSalesPerformanceReportPageState
    extends State<ItemTypeSalesPerformanceReportPage>
    with TextFormatter, PlatformChecker {
  static const TextStyle _filterLabelStyle =
      TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
  List<Brand> _brands = [];
  ItemType? _itemType;
  List<Supplier> _suppliers = [];
  late final Server server;
  bool _separatePurchaseYear = false;
  String _groupPeriod = 'monthly';
  final supplierChartController = SalesChartController();
  final brandChartController = SalesChartController();
  final itemTypeChartController = SalesChartController();

  final periodList = [
    'today',
    'week',
    'month',
    '3_month',
    '6_month',
    'year',
    '5_year',
    'all'
  ];
  static const Map<String, String> valueTypeLocales = {
    'sales_total': 'Total Penjualan(Rp)',
    'sales_quantity': 'Total Transaksi',
    'sales_discount_amount': 'Total Diskon(Rp)',
    'gross_profit': 'Gross Profit(Rp)',
    'sales_through_rate': 'Kecepatan Penjualan(%)',
    'cash_total': 'Total Tunai(Rp)',
    'debit_total': 'Total Kartu Debit(Rp)',
    'credit_total': 'Total Kartu Kredit(Rp)',
    'qris_total': 'Total Qris(Rp)',
    'online_total': 'Total Online Transfer(Rp)',
  };
  final List<Widget> rangePeriodEntries = [
    Padding(
      padding: const EdgeInsets.all(5.0),
      child: Text('Hari Ini'),
    ),
    Padding(
      padding: const EdgeInsets.all(5.0),
      child: Text('Minggu'),
    ),
    Padding(
      padding: const EdgeInsets.all(5.0),
      child: Text('Bulan'),
    ),
    Padding(
      padding: const EdgeInsets.all(5.0),
      child: Text('3 Bulan'),
    ),
    Padding(
      padding: const EdgeInsets.all(5.0),
      child: Text('6 Bulan'),
    ),
    Padding(
      padding: const EdgeInsets.all(5.0),
      child: Text('Tahun ini'),
    ),
    Padding(
      padding: const EdgeInsets.all(5.0),
      child: Text('5 Tahun'),
    ),
    Padding(
      padding: const EdgeInsets.all(5.0),
      child: Text('Semua'),
    ),
  ];

  Map itemTypeChartFilter = {
    'rangePeriod': 5,
    'valueType': 'sales_total',
    'item_types': <ItemType>[],
  };
  Map supplierChartFilter = {
    'rangePeriod': 5,
    'valueType': 'sales_total',
  };
  Map brandChartFilter = {
    'rangePeriod': 5,
    'valueType': 'sales_total',
  };

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
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
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
                    child: AsyncDropdown<ItemType>(
                        label: const Text('Pilih Jenis/Departemen'),
                        allowClear: false,
                        textOnSearch: (itemType) =>
                            "${itemType.name} - ${itemType.description}",
                        path: '/item_types',
                        onChanged: (value) => _itemType = value,
                        validator: (model) {
                          if (model == null) {
                            return 'harus diisi';
                          }
                          return null;
                        },
                        modelClass: ItemTypeClass()),
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
                            modelClass: BrandClass(),
                            attributeKey: 'merek',
                            path: '/brands',
                            onChanged: (value) => _brands = value,
                          )),
                      SizedBox(
                          width: 300,
                          child: AsyncDropdownMultiple<Supplier>(
                            label: const Text('Supplier :',
                                style: _filterLabelStyle),
                            key: const ValueKey('supplierSelect'),
                            textOnSearch: (supplier) =>
                                "${supplier.code} - ${supplier.name}",
                            textOnSelected: (supplier) => supplier.code,
                            modelClass: SupplierClass(),
                            attributeKey: 'kode',
                            path: '/suppliers',
                            onChanged: (value) => _suppliers = value,
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
                        });
                        generateCompareReport();
                        generateGroupBySupplierReport();
                        generateGroupByBrandReport();
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
                  Card(child: groupBySupplierChart()),
                  Card(child: groupByBrandChart()),
                  Card(child: compareItemTypeChart()),
                ],
              ),
            ),

            // LineChat
          ],
        ),
      ),
    );
  }

  Widget compareItemTypeChart() {
    return SalesPerformanceChart(
        title: 'Grafik Perbandingan Jenis/Departemen',
        controller: itemTypeChartController,
        xTitle: _generatedGroupedPeriod == 'weekly' ? 'MINGGU' : 'PERIODE',
        filterForm: [
          SizedBox(
            width: 350,
            child: AsyncDropdownMultiple<ItemType>(
                label: const Text('Perbandingan Jenis/Departemen'),
                textOnSearch: (itemType) =>
                    "${itemType.name} - ${itemType.description}",
                path: '/item_types',
                onChanged: (value) {
                  itemTypeChartFilter['item_types'] = value;
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
                selecteds: itemTypeChartFilter['item_types'],
                modelClass: ItemTypeClass()),
          ),
          DropdownMenu(
            dropdownMenuEntries: valueTypeLocales.entries
                .map<DropdownMenuEntry>(
                    (e) => DropdownMenuEntry(value: e.key, label: e.value))
                .toList(),
            label: const Text('Nilai Berdasarkan', style: _filterLabelStyle),
            onSelected: (value) {
              setState(() {
                itemTypeChartFilter['valueType'] =
                    value ?? itemTypeChartFilter['valueType'];
              });
              generateCompareReport();
            },
            initialSelection: itemTypeChartFilter['valueType'],
            width: 300,
            inputDecorationTheme: InputDecorationTheme(
                isDense: true, border: OutlineInputBorder()),
          ),
          SizedBox(
            width: 500,
            height: 90,
            child: Stack(
              children: [
                Text(
                  'Rentang Periode',
                  style: _filterLabelStyle,
                ),
                Positioned(
                  top: 20,
                  child: ToggleButtons(
                    onPressed: (int index) {
                      if (itemTypeChartFilter['rangePeriod'] != index) {
                        setState(() {
                          itemTypeChartFilter['rangePeriod'] = index;
                        });
                        generateCompareReport();
                      }
                    },
                    color: Colors.grey,
                    selectedColor: Colors.black,
                    fillColor: Colors.blue.shade200,
                    borderRadius: BorderRadius.circular(5),
                    hoverColor: Colors.green.shade300,
                    isSelected: List.generate(periodList.length,
                        (idx) => itemTypeChartFilter['rangePeriod'] == idx),
                    children: rangePeriodEntries,
                  ),
                ),
              ],
            ),
          ),
        ],
        xFormat: (double valueX, SalesChartController control) =>
            xFormatBasedPeriod(valueX, control.identifierList,
                control.startDate ?? DateTime.now()),
        spotYFormat: (value) =>
            _tooltipFormat(value, itemTypeChartFilter['valueType']),
        yFormat: yFormat(itemTypeChartFilter['valueType']));
  }

  Widget groupByBrandChart() {
    return SalesPerformanceChart(
        title: 'Grafik Berdasarkan Merek',
        controller: brandChartController,
        xTitle: _generatedGroupedPeriod == 'weekly' ? 'MINGGU' : 'PERIODE',
        filterForm: [
          DropdownMenu(
            dropdownMenuEntries: valueTypeLocales.entries
                .map<DropdownMenuEntry>(
                    (e) => DropdownMenuEntry(value: e.key, label: e.value))
                .toList(),
            label: const Text('Nilai Berdasarkan', style: _filterLabelStyle),
            onSelected: (value) {
              setState(() {
                brandChartFilter['valueType'] =
                    value ?? brandChartFilter['valueType'];
              });
              generateGroupByBrandReport();
            },
            initialSelection: brandChartFilter['valueType'],
            width: 300,
            inputDecorationTheme: InputDecorationTheme(
                isDense: true, border: OutlineInputBorder()),
          ),
          SizedBox(
            width: 500,
            height: 90,
            child: Stack(
              children: [
                Text(
                  'Rentang Periode',
                  style: _filterLabelStyle,
                ),
                Positioned(
                  top: 20,
                  child: ToggleButtons(
                    onPressed: (int index) {
                      if (brandChartFilter['rangePeriod'] != index) {
                        setState(() {
                          brandChartFilter['rangePeriod'] = index;
                        });
                        generateGroupByBrandReport();
                      }
                    },
                    color: Colors.grey,
                    selectedColor: Colors.black,
                    fillColor: Colors.blue.shade200,
                    borderRadius: BorderRadius.circular(5),
                    hoverColor: Colors.green.shade300,
                    isSelected: List.generate(periodList.length,
                        (idx) => idx == brandChartFilter['rangePeriod']),
                    children: rangePeriodEntries,
                  ),
                ),
              ],
            ),
          ),
        ],
        xFormat: (double valueX, SalesChartController control) =>
            xFormatBasedPeriod(valueX, control.identifierList,
                control.startDate ?? DateTime.now()),
        spotYFormat: (value) =>
            _tooltipFormat(value, brandChartFilter['valueType']),
        yFormat: yFormat(brandChartFilter['valueType']));
  }

  Widget groupBySupplierChart() {
    return SalesPerformanceChart(
        title: 'Grafik Berdasarkan Supplier',
        controller: supplierChartController,
        xTitle: _generatedGroupedPeriod == 'weekly' ? 'MINGGU' : 'PERIODE',
        filterForm: [
          DropdownMenu(
            dropdownMenuEntries: valueTypeLocales.entries
                .map<DropdownMenuEntry>(
                    (e) => DropdownMenuEntry(value: e.key, label: e.value))
                .toList(),
            label: const Text('Nilai Berdasarkan', style: _filterLabelStyle),
            onSelected: (value) {
              setState(() {
                supplierChartFilter['valueType'] =
                    value ?? supplierChartFilter['valueType'];
              });
              generateGroupBySupplierReport();
            },
            initialSelection: supplierChartFilter['valueType'],
            width: 300,
            inputDecorationTheme: InputDecorationTheme(
                isDense: true, border: OutlineInputBorder()),
          ),
          SizedBox(
            width: 500,
            height: 90,
            child: Stack(
              children: [
                Text(
                  'Rentang Periode',
                  style: _filterLabelStyle,
                ),
                Positioned(
                  top: 20,
                  child: ToggleButtons(
                    onPressed: (int index) {
                      if (supplierChartFilter['rangePeriod'] != index) {
                        setState(() {
                          supplierChartFilter['rangePeriod'] = index;
                        });
                        generateGroupBySupplierReport();
                      }
                    },
                    color: Colors.grey,
                    selectedColor: Colors.black,
                    fillColor: Colors.blue.shade200,
                    borderRadius: BorderRadius.circular(5),
                    hoverColor: Colors.green.shade300,
                    isSelected: List.generate(periodList.length,
                        (idx) => supplierChartFilter['rangePeriod'] == idx),
                    children: rangePeriodEntries,
                  ),
                ),
              ],
            ),
          ),
        ],
        xFormat: (double valueX, SalesChartController control) =>
            xFormatBasedPeriod(valueX, control.identifierList,
                control.startDate ?? DateTime.now()),
        spotYFormat: (value) =>
            _tooltipFormat(value, supplierChartFilter['valueType']),
        yFormat: yFormat(supplierChartFilter['valueType']));
  }

  String Function(double) yFormat(valueType) {
    if (valueType == 'sales_through_rate') {
      return percentageFormat;
    } else {
      return compactNumberFormat;
    }
  }

  String _tooltipFormat(double value, String valueType) {
    switch (valueType) {
      case 'sales_quantity':
        return numberFormat(value);
      case 'sales_through_rate':
        return percentageFormat(value);
      default:
        return moneyFormat(value);
    }
  }

  LineTitle createLineTitle(Map detail) {
    String name, description;
    if (detail['last_purchase_year'] == null) {
      name = detail['name'] ?? '';
      description = detail['description'] ?? '';
    } else {
      name = "${detail['name']} (${detail['last_purchase_year']})";
      description =
          "${detail['description']} (${detail['last_purchase_year']})";
    }
    return LineTitle(name: name, description: description);
  }

  void generateCompareReport() async {
    _generatedGroupedPeriod = _groupPeriod;
    setState(() {
      supplierChartController.isLoading = true;
    });
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
      LineTitle lineTitle = createLineTitle(detail);
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

  void generateGroupBySupplierReport() async {
    _generatedGroupedPeriod = _groupPeriod;
    setState(() {
      supplierChartController.isLoading = true;
    });
    final response = await fetchGroupBySupplierData();
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
      LineTitle lineTitle = createLineTitle(detail);
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

  void generateGroupByBrandReport() async {
    _generatedGroupedPeriod = _groupPeriod;
    setState(() {
      brandChartController.isLoading = true;
    });
    final response = await fetchGroupByBrandData();
    if (response.statusCode != 200) {
      setState(() {
        brandChartController.isLoading = false;
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
      LineTitle lineTitle = createLineTitle(detail);
      lines[lineTitle] = convertDataToSpots(detail['spots'], identifierList);
    }
    setState(() {
      brandChartController.setChartData(
          lines: lines,
          filteredDetails: filteredDetails,
          identifierList: identifierList,
          startDate: startDate,
          endDate: endDate);
      brandChartController.isLoading = false;
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

  DateTimeRange convertToTimeRange(int rangePeriod) {
    DateTime end = DateTime.now().subtract(const Duration(days: 1)).endOfDay();
    switch (rangePeriod) {
      case 0:
        return DateTimeRange(
            start: DateTime.now().beginningOfDay(),
            end: DateTime.now().endOfDay());
      case 1:
        return DateTimeRange(
            start: end.subtract(const Duration(days: 6)).beginningOfDay(),
            end: end);
      case 2:
        return DateTimeRange(
            start: end.subtract(const Duration(days: 30)).beginningOfDay(),
            end: end);
      case 3:
        return DateTimeRange(
            start: end.subtract(const Duration(days: 91)).beginningOfDay(),
            end: end);
      case 4:
        return DateTimeRange(
            start: end.subtract(const Duration(days: 182)).beginningOfDay(),
            end: end);
      case 5:
        return DateTimeRange(
            start: end.subtract(const Duration(days: 365)).beginningOfDay(),
            end: end);
      case 6:
        return DateTimeRange(
            start: end.subtract(const Duration(days: 1826)).beginningOfDay(),
            end: end);
      case 7:
        return DateTimeRange(
            start: DateTime(1000), end: DateTime.now().endOfDay());
      default:
        throw "Invalid range period $rangePeriod";
    }
  }

  Future fetchCompareData() async {
    var itemTypeNames = (itemTypeChartFilter['item_types'] as List<ItemType>)
        .map<String>((e) => e.name)
        .toList();
    if (_itemType != null && !itemTypeNames.contains(_itemType!.name)) {
      itemTypeNames.add(_itemType!.name);
    }
    DateTimeRange range =
        convertToTimeRange(itemTypeChartFilter['rangePeriod']);
    return server.get('item_sales_performance_reports/group_by', queryParam: {
      'brand_names[]': _brands.map<String>((e) => e.name).toList(),
      'supplier_codes[]': _suppliers.map<String>((e) => e.code).toList(),
      'item_type_names[]': itemTypeNames,
      'start_date': range.start.toIso8601String(),
      'end_date': range.end.toIso8601String(),
      'group_period': _groupPeriod,
      'group_type': 'item_type',
      'value_type': itemTypeChartFilter['valueType'],
      'last_purchase_years[]':
          _lastPurchaseYears.map<String>((e) => e.toString()).toList(),
      'separate_purchase_year': _separatePurchaseYear ? '1' : '0',
    });
  }

  Future fetchGroupBySupplierData() async {
    DateTimeRange range =
        convertToTimeRange(supplierChartFilter['rangePeriod']);
    return server.get('item_sales_performance_reports/group_by', queryParam: {
      'brand_names[]': _brands.map<String>((e) => e.name).toList(),
      'supplier_codes[]': _suppliers.map<String>((e) => e.code).toList(),
      'item_type_names[]': [_itemType?.name],
      'start_date': range.start.toIso8601String(),
      'end_date': range.end.toIso8601String(),
      'group_period': _groupPeriod,
      'group_type': 'supplier',
      'value_type': supplierChartFilter['valueType'],
      'last_purchase_years[]':
          _lastPurchaseYears.map<String>((e) => e.toString()).toList(),
      'separate_purchase_year': _separatePurchaseYear ? '1' : '0',
    });
  }

  Future fetchGroupByBrandData() async {
    DateTimeRange range = convertToTimeRange(brandChartFilter['rangePeriod']);
    return server.get('item_sales_performance_reports/group_by', queryParam: {
      'brand_names[]': _brands.map<String>((e) => e.name).toList(),
      'supplier_codes[]': _suppliers.map<String>((e) => e.code).toList(),
      'item_type_names[]': [_itemType?.name],
      'start_date': range.start.toIso8601String(),
      'end_date': range.end.toIso8601String(),
      'group_period': _groupPeriod,
      'group_type': 'brand',
      'value_type': brandChartFilter['valueType'],
      'last_purchase_years[]':
          _lastPurchaseYears.map<String>((e) => e.toString()).toList(),
      'separate_purchase_year': _separatePurchaseYear ? '1' : '0',
    });
  }
}
