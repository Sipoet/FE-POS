import 'package:dropdown_search/dropdown_search.dart';
import 'package:fe_pos/model/sales_group_report.dart';
import 'package:fe_pos/model/item.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';
import 'package:fe_pos/widget/sync_data_table.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:fe_pos/tool/file_saver.dart';

class SalesGroupReportPage extends StatefulWidget {
  const SalesGroupReportPage({super.key});

  @override
  State<SalesGroupReportPage> createState() => _SalesGroupReportPageState();
}

class _SalesGroupReportPageState extends State<SalesGroupReportPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  static const TextStyle _filterLabelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );
  late Server server;
  String? _reportType;
  late SyncTableController _source;
  late Flash flash;
  DateTimeRange<Date>? _dateRange;
  List _brands = [];
  List _suppliers = [];
  List _itemTypes = [];
  List _groupKeys = [];
  final groupList = [
    'supplier_name',
    'brand_name',
    'item_type_name',
    'last_purchase_year',
  ];
  final _cancelToken = CancelToken();
  final _formState = GlobalKey<FormState>();
  late final List<TableColumn> _tableColumns;
  late final Setting _setting;
  @override
  void initState() {
    server = context.read<Server>();
    _setting = context.read<Setting>();
    flash = Flash();
    _tableColumns = _setting.tableColumn('salesGroupReport');
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  void _displayReport() async {
    _source.setShowLoading(true);
    _reportType = 'json';
    _requestReport().then(
      _displayDatatable,
      onError: ((error, stackTrace) => defaultErrorResponse(error: error)),
    );
  }

  void _downloadReport() async {
    flash.show(const Text('Dalam proses.'), ToastificationType.info);
    _reportType = 'xlsx';
    _requestReport().then(
      _downloadResponse,
      onError: ((error, stackTrace) => defaultErrorResponse(error: error)),
    );
  }

  Future _requestReport({int? page, int? per}) async {
    return server.get(
      'item_reports/grouped_report',
      queryParam: {
        'start_date': _dateRange?.start.toIso8601String(),
        'end_date': _dateRange?.end.toIso8601String(),
        'suppliers[]': _suppliers,
        'brands[]': _brands,
        'item_types[]': _itemTypes,
        'report_type': _reportType,
        'group_names[]': _groupKeys,
        if (page != null) 'page': page.toString(),
        if (per != null) 'per': per.toString(),
      },
      type: _reportType ?? 'json',
      cancelToken: _cancelToken,
    );
  }

  void _downloadResponse(response) async {
    flash.hide();
    if (response.statusCode != 200) {
      flash.show(const Text('gagal simpan ke excel'), ToastificationType.error);
      return;
    }
    String filename = response.headers.value('content-disposition') ?? '';
    if (filename.isEmpty) {
      return;
    }
    filename = filename.substring(
      filename.indexOf('filename="') + 10,
      filename.indexOf('xlsx";') + 4,
    );

    var downloader = const FileSaver();
    downloader.download(
      filename,
      response.data,
      'xlsx',
      onSuccess: (String path) {
        flash.showBanner(
          messageType: ToastificationType.success,
          title: 'Sukses download',
          description: 'sukses disimpan di $path',
        );
      },
    );
  }

  void _displayDatatable(response) async {
    _source.setShowLoading(false);
    if (response.statusCode != 200) {
      return;
    }
    final tabManager = context.read<TabManager>();
    var data = response.data;
    setState(() {
      var rawData = data['data'].map<SalesGroupReport>((row) {
        return SalesGroupReportClass().fromJson(row);
      }).toList();

      _source.setTableColumns(
        whitelistColumns,
        fixedLeftColumns: _groupKeys.length,
        tabManager: tabManager,
      );
      _source.setModels(rawData);
    });
  }

  List<TableColumn> get whitelistColumns => () {
    List<TableColumn> columns = List.from(_tableColumns);
    columns.removeWhere(
      (tableColumn) =>
          groupList.contains(tableColumn.name) &&
          !_groupKeys.contains(tableColumn.name),
    );
    columns.sort((columnA, columnB) {
      final index = _groupKeys.indexOf(columnA.name);
      final index2 = _groupKeys.indexOf(columnB.name);
      if (index >= 0 && index2 >= 0) {
        return index.compareTo(index2);
      } else if (index >= 0) {
        return -1;
      } else if (index2 >= 0) {
        return 1;
      } else {
        return columns.indexOf(columnA).compareTo(columns.indexOf(columnB));
      }
    });
    return columns;
  }();

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return VerticalBodyScroll(
      child: Form(
        key: _formState,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 350,
              child: DropdownSearch<String>.multiSelection(
                decoratorProps: const DropDownDecoratorProps(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text('Group Berdasarkan', style: _filterLabelStyle),
                  ),
                ),
                items: (searchText, props) => groupList,
                onChanged: (value) => _groupKeys = value,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'harus diisi';
                  }
                  return null;
                },
                itemAsString: (item) {
                  return _setting.columnName('salesGroupReport', item);
                },
              ),
            ),
            const Text(
              'Filter',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              direction: Axis.horizontal,
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 350,
                  child: DateRangeFormField(
                    label: const Text('Periode :', style: _filterLabelStyle),
                    rangeType: DateRangeType(),
                    allowClear: true,
                    onChanged: (range) => _dateRange = range,
                  ),
                ),
                SizedBox(
                  width: 350,
                  child: AsyncDropdownMultiple<Brand>(
                    label: const Text('Merek :', style: _filterLabelStyle),
                    key: const ValueKey('brandSelect'),
                    textOnSearch: (Brand brand) => brand.name,
                    modelClass: BrandClass(),
                    attributeKey: 'merek',
                    onSaved: (value) => _brands = value == null
                        ? []
                        : value.map<String>((e) => e.name).toList(),
                  ),
                ),
                SizedBox(
                  width: 350,
                  child: AsyncDropdownMultiple<ItemType>(
                    label: const Text(
                      'Jenis/Departemen :',
                      style: _filterLabelStyle,
                    ),
                    key: const ValueKey('itemTypeSelect'),
                    textOnSearch: (itemType) =>
                        "${itemType.name} - ${itemType.description}",
                    textOnSelected: (itemType) => itemType.name,
                    modelClass: ItemTypeClass(),
                    attributeKey: 'jenis',

                    onSaved: (value) => _itemTypes = value == null
                        ? []
                        : value.map<String>((e) => e.name).toList(),
                  ),
                ),
                SizedBox(
                  width: 350,
                  child: AsyncDropdownMultiple<Supplier>(
                    label: const Text('Supplier :', style: _filterLabelStyle),
                    key: const ValueKey('supplierSelect'),
                    attributeKey: 'nama',

                    textOnSearch: (supplier) =>
                        "${supplier.code} - ${supplier.name}",
                    textOnSelected: (supplier) => supplier.code,
                    modelClass: SupplierClass(),
                    onSaved: (value) => _suppliers = value == null
                        ? []
                        : value.map<String>((e) => e.code).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              runSpacing: 10,
              spacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_formState.currentState!.validate()) {
                      _formState.currentState!.save();
                      _displayReport();
                    }
                  },
                  child: const Text('Tampilkan'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formState.currentState!.validate()) {
                      _formState.currentState!.save();
                      _downloadReport();
                    }
                  },
                  child: const Text('Download'),
                ),
              ],
            ),
            const Divider(),
            SizedBox(
              height: bodyScreenHeight,
              child: SyncDataTable<SalesGroupReport>(
                showSummary: true,
                showFilter: false,
                columns: _tableColumns,
                onLoaded: (stateManager) => _source = stateManager,
                fixedLeftColumns: _groupKeys.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
