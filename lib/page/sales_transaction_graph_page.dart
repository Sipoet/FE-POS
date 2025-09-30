import 'package:dropdown_search/dropdown_search.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';
import 'package:fe_pos/model/item.dart';
import 'package:fe_pos/widget/sales_performance_chart.dart';
import 'package:fe_pos/widget/sync_data_table.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        PlatformChecker {
  late final Server server;
  late final Setting setting;
  late Flash flash;
  String _groupPeriod = 'daily';
  String _generatedGroupPeriod = 'daily';

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
  String _groupType = 'period';
  List<String> _lastPurchaseYears = [];

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
    });
    if (response.statusCode != 200) {
      setState(() {
        salesReportController.isLoading = false;
      });
      if (response.statusCode == 409) {
        flash.showBanner(
            messageType: ToastificationType.error,
            title: 'Gagal Ambil data',
            description: response.data['message']);
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
        name = detail['name'] ?? '';
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
      salesReportController.setChartData(
          lines: lines,
          filteredDetails: filteredDetails,
          identifierList: identifierList,
          startDate: startDate,
          endDate: endDate);
      salesReportController.isLoading = false;
    });
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
      final x = convertDateToCoordData(e[0].toString(), identifierList);
      final y = e[1];
      return FlSpot(x, y);
    }).toList();
  }

  double convertDateToCoordData(String dateStr, List identifierList) {
    return identifierList.indexOf(dateStr).toDouble();
  }

  String xFormatBasedPeriod(
      double valueX, List identifierList, DateTime startDate) {
    final datePk = identifierList[valueX.round()];
    DateTime date = DateTime.tryParse(datePk) ?? DateTime.now();
    switch (_generatedGroupPeriod) {
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

  String _tooltipFormat(double value) {
    if (value == 0) {
      return '';
    }
    switch (fieldKey) {
      case 'sales_quantity':
        return numberFormat(value);
      case 'sales_through_rate':
        return "${numberFormat(value)}%";
      case 'sales_total':
      case 'cash_total':
      case 'debit_total':
      case 'credit_total':
      case 'qris_total':
      case 'online_total':
      case 'gross_profit':
      case 'sales_discount_amount':
        return moneyFormat(value, decimalDigits: 0);
      default:
        return numberFormat(value);
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
          Text(
            'Grafik Penjualan',
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
                datePickerOnly: true,
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
              dropdownMenuEntries: [
                DropdownMenuEntry(value: 'period', label: 'waktu'),
                DropdownMenuEntry(value: 'item', label: 'Item'),
                DropdownMenuEntry(value: 'supplier', label: 'Supplier'),
                DropdownMenuEntry(
                    value: 'item_type', label: 'Jenis/Departemen'),
                DropdownMenuEntry(value: 'brand', label: 'Merek'),
              ],
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
                  converter: ItemType.fromJson,
                  attributeKey: 'jenis',
                  path: '/item_Types',
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
                  converter: Supplier.fromJson,
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
                  converter: Brand.fromJson,
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
                  converter: Item.fromJson,
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
          ]),
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
                    value: 'sales_total', label: 'Total Penjualan(Rp)'),
                DropdownMenuEntry(
                    value: 'sales_quantity', label: 'Jumlah Penjualan'),
                DropdownMenuEntry(
                    value: 'sales_discount_amount', label: 'Total Diskon(Rp)'),
                DropdownMenuEntry(value: 'gross_profit', label: 'Gross Profit'),
                DropdownMenuEntry(
                    value: 'sales_through_rate',
                    label: 'Kecepatan Penjualan(%)'),
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
          ElevatedButton(onPressed: _refreshGraph, child: Text('Generate')),
          const SizedBox(
            height: 10,
          ),
          SizedBox(height: height, child: SyncDataTable()),
          const SizedBox(
            height: 10,
          ),
          Card(
            child: SalesPerformanceChart(
                controller: salesReportController,
                xFormat: (double valueX, SalesChartController control) =>
                    xFormatBasedPeriod(valueX, control.identifierList,
                        control.startDate ?? DateTime.now()),
                yFormat: compactNumberFormat,
                spotYFormat: _tooltipFormat),
          ),
        ],
      ),
    );
  }
}
