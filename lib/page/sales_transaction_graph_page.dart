import 'package:dropdown_search/dropdown_search.dart';
import 'package:fe_pos/model/hash_model.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';
import 'package:fe_pos/model/item.dart';
import 'package:fe_pos/widget/sales_performance_chart.dart';
import 'package:fe_pos/widget/sync_data_table.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
        PlatformChecker {
  late final Server server;
  late final Setting setting;
  late Flash flash;
  String _groupPeriod = 'daily';
  String _generatedGroupPeriod = 'daily';
  PlutoGridStateManager? _source;

  String fieldKey = 'sales_total';
  static const TextStyle _filterLabelStyle =
      TextStyle(fontSize: 14, fontWeight: FontWeight.bold);

  DateTimeRange _dateRange = DateTimeRange(
      start: DateTime.now().beginningOfMonth(),
      end: DateTime.now().endOfMonth());
  final salesReportController = SalesChartController();
  final yearNow = DateTime.now().year;
  List<ItemType> _itemTypes = [];
  List<Supplier> _suppliers = [];
  List<Brand> _brands = [];
  List<Item> _items = [];
  bool _separatePurchaseYear = false;
  String _groupType = 'period';
  List<String> _lastPurchaseYears = [];

  List<TableColumn> _columns = [];

  @override
  bool get wantKeepAlive => true;
  static const Map<String, String> groupKeyLocales = {
    'period': 'waktu',
    'item': 'Item',
    'supplier': 'Supplier',
    'item_type': 'Jenis/Departemen',
    'brand': 'Merek',
  };
  static const Map<String, String> fieldKeyLocales = {
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

  late final TabManager tabManager;

  @override
  void initState() {
    flash = Flash();
    server = context.read<Server>();
    setting = context.read<Setting>();
    tabManager = context.read<TabManager>();
    super.initState();
    Future.delayed(Duration.zero, () => _refreshGraph());
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future _refreshGraph() async {
    await _fetchGraph();
  }

  Future _fetchGraph() async {
    setState(() {
      salesReportController.isLoading = true;
    });
    final response = await server
        .get('item_sales_performance_reports/group_by', queryParam: {
      'start_date': _dateRange.start.toIso8601String(),
      'end_date': _dateRange.end.toIso8601String(),
      'item_type_names[]': _itemTypes.map<String>((e) => e.name).toList(),
      'supplier_codes[]': _suppliers.map<String>((e) => e.code).toList(),
      'item_codes[]': _items.map<String>((e) => e.code).toList(),
      'brand_names[]': _brands.map<String>((e) => e.name).toList(),
      'group_type': _groupType,
      'group_period': _groupPeriod,
      'value_type': fieldKey,
      'separate_purchase_year': _separatePurchaseYear ? '1' : '0',
      'last_purchase_years[]': _lastPurchaseYears,
    });
    if (response.statusCode != 200) {
      setState(() {
        salesReportController.isLoading = false;
      });
      if (response.statusCode == 409) {
        flash.showBanner(
            messageType: ToastificationType.error,
            title: response.data['message'],
            description: response.data['errors'].join(','));
      }
      return;
    }
    _generatedGroupPeriod = _groupPeriod;
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
        name = (detail['name'] ?? '').toString();
        description = detail['description'] ?? '';
      } else {
        name = "${detail['name']} (${detail['last_purchase_year']})";
        description =
            "${detail['description']} (${detail['last_purchase_year']})";
      }
      LineTitle lineTitle = LineTitle(name: name, description: description);
      lines[lineTitle] = convertDataToSpots(detail['spots'], identifierList);
    }
    setState(() {
      _columns = [
        TableColumn<HashModel>(
            clientWidth: 180,
            name: 'group_key',
            canFilter: true,
            renderBody: (model) => Text(model.cell.value.toString()),
            humanizeName: groupKeyLocales[_groupType] ?? ''),
        if (_groupType != 'period' || _groupPeriod != 'dow')
          TableColumn(
              clientWidth: 180,
              name: 'description',
              canFilter: true,
              renderBody: (model) =>
                  Text(model.row.cells['description']?.value.toString() ?? ''),
              humanizeName: 'Deskripsi'),
        if (_separatePurchaseYear)
          TableColumn<HashModel>(
              clientWidth: 180,
              name: 'last_purchase_year',
              type: TableColumnType.text,
              humanizeName: 'Tahun Beli Terakhir'),
        if (fieldKey == 'sales_through_rate')
          TableColumn<HashModel>(
              clientWidth: 180,
              name: 'start_stock',
              type: TableColumnType.number,
              humanizeName: 'Stok Awal'),
        if (fieldKey == 'sales_through_rate')
          TableColumn<HashModel>(
              clientWidth: 200,
              name: 'increase_period_stock',
              type: TableColumnType.number,
              humanizeName: 'Tambahan Stok(Periode)'),
        if (fieldKey == 'sales_through_rate')
          TableColumn<HashModel>(
              clientWidth: 180,
              name: 'sales_quantity',
              type: TableColumnType.number,
              humanizeName: 'Jumlah Penjualan'),
        TableColumn(
            clientWidth: 220,
            name: 'total',
            type: basedValueType(),
            canSort: true,
            humanizeName: fieldKeyLocales[fieldKey] ?? ''),
      ];
      final groupModels = convertResponseToHashModels(data);

      if (_source != null) {
        _source?.setTableColumns(_columns, tabManager: tabManager);
        _source?.setModels(groupModels, _columns);
        _source?.sortAscending(_source!.columns.first);
      }

      salesReportController.setChartData(
          lines: lines,
          filteredDetails: filteredDetails,
          identifierList: identifierList,
          startDate: startDate,
          endDate: endDate);
      salesReportController.isLoading = false;
    });
  }

  List<HashModel> convertResponseToHashModels(Map data) {
    List<HashModel> models = [];
    List identifierList = data['metadata']['identifier_list'];
    DateTime startDate = DateTime.parse(data['metadata']['start_date']);
    if (_groupType == 'period') {
      for (var detail in data['data']) {
        for (var spot in detail['spots']) {
          models.add(HashModel(data: {
            'group_key': datePkFormat(
                spot[0].toString(), identifierList, startDate,
                shortText: false),
            'value': spot[0],
            'total': spot[1],
            'description': detail['description'] ?? '',
            'last_purchase_year': detail['last_purchase_year'].toString(),
          }));
        }
      }
      models.sort((a, b) => b.data['total'].compareTo(a.data['total']));
      return models;
    } else {
      for (var detail in data['data']) {
        List spots = detail['spots'];
        var total = spots
            .map<double>((e) => (e[1] ?? 0).toDouble())
            .reduce((value, element) => value + element);
        if (fieldKey == 'sales_through_rate' && spots.isNotEmpty) {
          total = total / spots.length;
        }
        models.add(HashModel(data: {
          'group_key': detail['name'],
          'total': total,
          'sales_quantity': detail['sales_quantity'],
          'start_stock': detail['start_stock'],
          'increase_period_stock': detail['increase_period_stock'],
          'description': detail['description'],
          'last_purchase_year': detail['last_purchase_year'].toString(),
        }));
      }
      models.sort((a, b) => b.data['total'].compareTo(a.data['total']));
      return models;
    }
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
    if (metadata['supplier_codes']?.isNotEmpty ?? false) {
      filteredDetails.add("Supplier: ${metadata['supplier_codes'].join(', ')}");
    }
    if (metadata['item_codes']?.isNotEmpty ?? false) {
      filteredDetails.add("Item: ${metadata['item_codes'].join(', ')}");
    }
    if (metadata['last_purchase_years']?.isNotEmpty ?? false) {
      filteredDetails.add(
          "Tahun Beli Terakhir: ${metadata['last_purchase_years'].join(', ')}");
    }
    return filteredDetails;
  }

  List<FlSpot> convertDataToSpots(List data, List identifierList) {
    return data.map<FlSpot>((e) {
      final double x = convertDateToCoordData(e[0].toString(), identifierList);
      final double y = e[1] ?? 0.0;
      return FlSpot(x, y);
    }).toList();
  }

  double convertDateToCoordData(String dateStr, List identifierList) {
    return identifierList.indexOf(dateStr).toDouble();
  }

  String xFormatBasedPeriod(
      double valueX, List identifierList, DateTime startDate) {
    final datePk = identifierList[valueX.round()];
    return datePkFormat(datePk, identifierList, startDate);
  }

  String datePkFormat(String datePk, List identifierList, DateTime startDate,
      {bool shortText = true}) {
    DateTime date = DateTime.tryParse(datePk) ?? DateTime.now();
    switch (_generatedGroupPeriod) {
      case 'hourly':
        return TimeOfDay(hour: int.parse(datePk), minute: 0).format24Hour();
      case 'dow':
        if (shortText) {
          return [
            'Min',
            'Sen',
            'Sel',
            'Rab',
            'Kam',
            'Jum',
            'Sab',
          ][int.parse(datePk)];
        } else {
          return [
            '(7)Minggu',
            '(1)Senin',
            '(2)Selasa',
            '(3)Rabu',
            '(4)Kamis',
            '(5)Jumat',
            '(6)Sabtu',
          ][int.parse(datePk)];
        }

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

  String _tooltipFormat(double value) {
    switch (fieldKey) {
      case 'sales_quantity':
        return numberFormat(value);
      case 'sales_through_rate':
        return percentageFormat(value);
      default:
        return moneyFormat(value);
    }
  }

  TableColumnType basedValueType() {
    switch (fieldKey) {
      case 'sales_quantity':
        return TableColumnType.number;
      case 'sales_through_rate':
        return TableColumnType.percentage;
      default:
        return TableColumnType.money;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return VerticalBodyScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Laporan Periode Penjualan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const SizedBox(
            height: 15,
          ),
          Wrap(spacing: 10, runSpacing: 10, children: [
            SizedBox(
              width: 300,
              child: DateRangeFormField(
                label: Text('Rentang Periode'),
                rangeType: DateRangeType(),
                initialDateRange: _dateRange,
                onChanged: (range) => _dateRange = range ?? _dateRange,
                allowClear: false,
              ),
            ),
            DropdownMenu(
              dropdownMenuEntries: [
                DropdownMenuEntry(value: 'hourly', label: 'Jam'),
                DropdownMenuEntry(value: 'daily', label: 'Harian'),
                DropdownMenuEntry(value: 'weekly', label: 'Minggu'),
                DropdownMenuEntry(value: 'dow', label: 'Hari dalam minggu'),
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
            DropdownMenu(
              dropdownMenuEntries: groupKeyLocales.entries
                  .map<DropdownMenuEntry>(
                    (entry) =>
                        DropdownMenuEntry(value: entry.key, label: entry.value),
                  )
                  .toList(),
              label:
                  const Text('Dipisah Berdasarkan', style: _filterLabelStyle),
              onSelected: (value) {
                setState(() {
                  _groupType = value ?? _groupType;
                });
              },
              initialSelection: _groupType,
              width: 300,
              inputDecorationTheme: InputDecorationTheme(
                  isDense: true, border: OutlineInputBorder()),
            ),
            SizedBox(
                width: 300,
                child: AsyncDropdownMultiple<ItemType>(
                  label: const Text('Jenis/Departemen :',
                      style: _filterLabelStyle),
                  key: const ValueKey('itemTypeSelect'),
                  textOnSearch: (ItemType itemType) => itemType.name,
                  modelClass: ItemTypeClass(),
                  attributeKey: 'jenis',
                  path: '/item_types',
                  onChanged: (value) => _itemTypes = value,
                )),
            SizedBox(
                width: 300,
                child: AsyncDropdownMultiple<Supplier>(
                  label: const Text('Supplier :', style: _filterLabelStyle),
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
                child: AsyncDropdownMultiple<Brand>(
                  label: const Text('Merek :', style: _filterLabelStyle),
                  key: const ValueKey('brandSelect'),
                  textOnSearch: (brand) => brand.name,
                  textOnSelected: (brand) => brand.name,
                  modelClass: BrandClass(),
                  attributeKey: 'nama',
                  path: '/brands',
                  onChanged: (value) => _brands = value,
                )),
            SizedBox(
                width: 300,
                child: AsyncDropdownMultiple<Item>(
                  label: const Text('Item :', style: _filterLabelStyle),
                  key: const ValueKey('itemSelect'),
                  textOnSearch: (item) => "${item.code} - ${item.name}",
                  textOnSelected: (item) => item.code,
                  modelClass: ItemClass(),
                  attributeKey: 'kode',
                  path: '/items',
                  onChanged: (value) => _items = value,
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
                    return List<String>.generate(
                            50, (index) => (yearNow - index).toString())
                        .where((year) =>
                            year.contains(searchText) || searchText.isEmpty)
                        .toList();
                  },
                )),
            SizedBox(
              width: 250,
              child: CheckboxListTile.adaptive(
                  title: Text('Pisah tahun beli'),
                  value: _separatePurchaseYear,
                  onChanged: (value) => setState(() {
                        _separatePurchaseYear = value ?? false;
                      })),
            ),
          ]),
          const SizedBox(
            height: 10,
          ),
          DropdownMenu<String>(
              label: Text('Berdasarkan'),
              initialSelection: fieldKey,
              onSelected: (value) => setState(() {
                    fieldKey = value ?? 'sales_total';
                  }),
              dropdownMenuEntries: fieldKeyLocales.entries
                  .map<DropdownMenuEntry<String>>(
                    (entry) => DropdownMenuEntry<String>(
                        value: entry.key, label: entry.value),
                  )
                  .toList()),
          const SizedBox(
            height: 10,
          ),
          ElevatedButton(onPressed: _refreshGraph, child: Text('Generate')),
          const SizedBox(
            height: 10,
          ),
          Text('Grouped Result',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(
              height: bodyScreenHeight,
              child: SyncDataTable<HashModel>(
                columns: _columns,
                isPaginated: true,
                onLoaded: (stateManager) => _source = stateManager,
                showSummary: true,
              )),
          const SizedBox(
            height: 10,
          ),
          Card(
            child: SalesPerformanceChart(
                controller: salesReportController,
                xFormat: (double valueX, SalesChartController control) =>
                    xFormatBasedPeriod(valueX, control.identifierList,
                        control.startDate ?? DateTime.now()),
                yFormat: fieldKey == 'sales_through_rate'
                    ? percentageFormat
                    : compactNumberFormat,
                spotYFormat: _tooltipFormat),
          ),
        ],
      ),
    );
  }
}
