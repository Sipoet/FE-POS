import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/model/item_sales_period_report.dart';
import 'package:fe_pos/model/item.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/sync_data_table.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/tool/file_saver.dart';

class ItemSalesPeriodReportPage extends StatefulWidget {
  const ItemSalesPeriodReportPage({super.key});

  @override
  State<ItemSalesPeriodReportPage> createState() =>
      _ItemSalesPeriodReportPageState();
}

class _ItemSalesPeriodReportPageState extends State<ItemSalesPeriodReportPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  static const TextStyle _filterLabelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );
  late Server server;
  String? _reportType;
  late final TableController _source;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().copyWith(hour: 0, minute: 0, second: 0),
    end: DateTime.now().copyWith(hour: 23, minute: 59, second: 59),
  );
  late Flash flash;
  List _items = [];
  List _itemTypes = [];
  List _suppliers = [];
  List _brands = [];
  bool? _isConsignment;
  late final Setting _setting;
  @override
  void initState() {
    flash = Flash();
    server = context.read<Server>();
    _setting = context.read<Setting>();

    super.initState();
  }

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
      'ipos/sale_items/period_report',
      queryParam: {
        'suppliers[]': _suppliers,
        'brands[]': _brands,
        'item_types[]': _itemTypes,
        'items[]': _items,
        'report_type': _reportType,
        'start_time': _dateRange.start.toIso8601String(),
        'end_time': _dateRange.end.toIso8601String(),
        if (_isConsignment != null) 'is_consignment': _isConsignment.toString(),
        if (page != null) 'page': page.toString(),
        if (per != null) 'per': per.toString(),
      },
      type: _reportType ?? 'json',
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

    var fileSaver = const FileSaver();
    fileSaver.download(
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
    var data = response.data;
    setState(() {
      var rawData = data['data'].map<ItemSalesPeriodReport>((row) {
        return ItemSalesPeriodReportClass().fromJson(row);
      }).toList();
      _source.setModels(rawData);
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return VerticalBodyScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            direction: Axis.horizontal,
            runSpacing: 10,
            spacing: 10,
            children: [
              SizedBox(
                width: 350,
                child: DateRangeFormField(
                  label: const Text('Tanggal :', style: _filterLabelStyle),
                  rangeType: DateTimeRangeType(),
                  initialValue: _dateRange,
                  onChanged: (range) => _dateRange =
                      range ??
                      DateTimeRange(start: DateTime.now(), end: DateTime.now()),
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 350),
                child: AsyncDropdownMultiple<Brand>(
                  label: const Text('Merek :', style: _filterLabelStyle),
                  key: const ValueKey('brandSelect'),
                  textOnSearch: (Brand brand) => brand.name,
                  modelClass: BrandClass(),
                  attributeKey: 'merek',
                  onChanged: (value) =>
                      _brands = value.map<String>((e) => e.name).toList(),
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 350),
                child: AsyncDropdownMultiple<ItemType>(
                  label: const Text(
                    'Jenis/Departemen :',
                    style: _filterLabelStyle,
                  ),
                  key: const ValueKey('brandSelect'),
                  textOnSearch: (itemType) =>
                      "${itemType.name} - ${itemType.description}",
                  textOnSelected: (itemType) => itemType.name,
                  modelClass: ItemTypeClass(),
                  attributeKey: 'jenis',
                  onChanged: (value) =>
                      _itemTypes = value.map<String>((e) => e.name).toList(),
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 350),
                child: AsyncDropdownMultiple<Supplier>(
                  label: const Text('Supplier :', style: _filterLabelStyle),
                  key: const ValueKey('supplierSelect'),
                  attributeKey: 'nama',
                  textOnSearch: (supplier) =>
                      "${supplier.code} - ${supplier.name}",
                  textOnSelected: (supplier) => supplier.code,
                  modelClass: SupplierClass(),
                  onChanged: (value) =>
                      _suppliers = value.map<String>((e) => e.code).toList(),
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 350),
                child: AsyncDropdownMultiple<Item>(
                  label: const Text('Item :', style: _filterLabelStyle),
                  key: const ValueKey('itemSelect'),
                  attributeKey: 'namaitem',
                  textOnSearch: (item) => "${item.code} - ${item.name}",
                  textOnSelected: (item) => item.code,
                  modelClass: ItemClass(),
                  onChanged: (value) =>
                      _items = value.map<String>((e) => e.code).toList(),
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 350),
                child: CheckboxListTile(
                  tristate: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _isConsignment,
                  title: const Text('Konsinyasi?', style: _filterLabelStyle),
                  onChanged: (value) => setState(() {
                    _isConsignment = value;
                  }),
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
                onPressed: () => {_displayReport()},
                child: const Text('Tampilkan'),
              ),
              ElevatedButton(
                onPressed: () => {_downloadReport()},
                child: const Text('Download'),
              ),
            ],
          ),
          const Divider(),
          SizedBox(
            height: bodyScreenHeight,
            child: SyncDataTable<ItemSalesPeriodReport>(
              onLoaded: (stateManager) => _source = stateManager,
              columns: _setting.tableColumn('itemSalesPeriodReport'),
              showSummary: true,
              showFilter: true,
              fixedLeftColumns: 1,
            ),
          ),
        ],
      ),
    );
  }
}
