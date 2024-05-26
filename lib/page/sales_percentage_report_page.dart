import 'package:fe_pos/model/item.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/model/item_sales_percentage_report.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/custom_data_table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/tool/file_saver.dart';

class SalesPercentageReportPage extends StatefulWidget {
  const SalesPercentageReportPage({super.key});

  @override
  State<SalesPercentageReportPage> createState() =>
      _SalesPercentageReportPageState();
}

class _SalesPercentageReportPageState extends State<SalesPercentageReportPage>
    with AutomaticKeepAliveClientMixin, LoadingPopup {
  static const TextStyle _filterLabelStyle =
      TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  late Server server;
  String? _reportType;
  bool _isDisplayTable = false;
  double minimumColumnWidth = 150;
  late final SyncDataTableSource<ItemSalesPercentageReport> _source;
  late Flash flash;
  String _storeStockComparison = '';
  String _storeStockValue = '';
  String _warehouseStockComparison = '';
  String _warehouseStockValue = '';
  List _brands = [];
  List _suppliers = [];
  List _items = [];
  List _itemTypes = [];
  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    server = context.read<Server>();
    final setting = context.read<Setting>();
    _source = SyncDataTableSource<ItemSalesPercentageReport>(
        columns: setting.tableColumn('itemSalesPercentageReport'));
    flash = Flash(context);
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  void _displayReport() async {
    showLoadingPopup();
    _reportType = 'json';
    _requestReport()
        .then(_displayDatatable,
            onError: ((error, stackTrace) =>
                server.defaultErrorResponse(context: context, error: error)))
        .whenComplete(() => hideLoadingPopup());
  }

  void _downloadReport() async {
    flash.show(
      const Text('Dalam proses.'),
      MessageType.info,
    );
    _reportType = 'xlsx';
    _requestReport().then(_downloadResponse,
        onError: ((error, stackTrace) =>
            server.defaultErrorResponse(context: context, error: error)));
  }

  Future _requestReport({int? page, int? per}) async {
    String warehouseStock = '$_warehouseStockComparison-$_warehouseStockValue';
    String storeStock = '$_storeStockComparison-$_storeStockValue';
    if (warehouseStock == '-') {
      warehouseStock = '';
    }
    if (storeStock == '-') {
      storeStock = '';
    }
    return server.get('item_sales_percentage_reports',
        queryParam: {
          'suppliers[]': _suppliers,
          'brands[]': _brands,
          'item_types[]': _itemTypes,
          'item_codes[]': _items,
          'report_type': _reportType,
          'warehouse_stock': warehouseStock,
          'store_stock': storeStock,
          if (page != null) 'page': page.toString(),
          if (per != null) 'per': per.toString()
        },
        type: _reportType ?? 'json');
  }

  void _downloadResponse(response) async {
    flash.hide();
    if (response.statusCode != 200) {
      flash.show(const Text('gagal simpan ke excel'), MessageType.failed);
      return;
    }
    String filename = response.headers.value('content-disposition') ?? '';
    if (filename.isEmpty) {
      return;
    }
    filename = filename.substring(
        filename.indexOf('filename="') + 10, filename.indexOf('xlsx";') + 4);
    var downloader = const FileSaver();
    downloader.download(filename, response.data, 'xlsx',
        onSuccess: (String path) {
      flash.showBanner(
          messageType: MessageType.success,
          title: 'Sukses download',
          description: 'sukses disimpan di $path');
    });
  }

  void _displayDatatable(response) async {
    flash.hide();
    if (response.statusCode != 200) {
      return;
    }
    var data = response.data;
    setState(() {
      var models = data['data'].map<ItemSalesPercentageReport>((row) {
        return ItemSalesPercentageReport.fromJson(row);
      }).toList();
      _source.paginatorController?.goToFirstPage();
      _source.setData(models);
      _isDisplayTable = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final padding = MediaQuery.of(context).padding;
    final size = MediaQuery.of(context).size;
    double tableHeight = size.height - padding.top - padding.bottom - 150;
    tableHeight = tableHeight > 600 ? 600 : tableHeight;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Form(
              key: _formKey,
              child: Wrap(
                direction: Axis.horizontal,
                runSpacing: 10,
                spacing: 10,
                children: [
                  Container(
                      padding: const EdgeInsets.only(right: 10),
                      constraints: const BoxConstraints(maxWidth: 350),
                      child: AsyncDropdownMultiple2<Brand>(
                        label: const Text('Merek :', style: _filterLabelStyle),
                        key: const ValueKey('brandSelect'),
                        textOnSearch: (Brand brand) => brand.name,
                        converter: Brand.fromJson,
                        attributeKey: 'merek',
                        path: '/brands',
                        onSaved: (value) => _brands =
                            value?.map<String>((e) => e.name).toList() ?? [],
                      )),
                  Container(
                      padding: const EdgeInsets.only(right: 10),
                      constraints: const BoxConstraints(maxWidth: 350),
                      child: AsyncDropdownMultiple2<ItemType>(
                        label: const Text('Jenis/Departemen :',
                            style: _filterLabelStyle),
                        key: const ValueKey('brandSelect'),
                        textOnSearch: (itemType) =>
                            "${itemType.name} - ${itemType.description}",
                        textOnSelected: (itemType) => itemType.name,
                        converter: ItemType.fromJson,
                        attributeKey: 'jenis',
                        path: '/item_types',
                        onSaved: (value) => _itemTypes =
                            value?.map<String>((e) => e.name).toList() ?? [],
                      )),
                  Container(
                    padding: const EdgeInsets.only(right: 10),
                    constraints: const BoxConstraints(maxWidth: 350),
                    child: AsyncDropdownMultiple2<Supplier>(
                      label: const Text('Supplier :', style: _filterLabelStyle),
                      key: const ValueKey('supplierSelect'),
                      attributeKey: 'nama',
                      path: '/suppliers',
                      textOnSearch: (supplier) =>
                          "${supplier.code} - ${supplier.name}",
                      textOnSelected: (supplier) => supplier.code,
                      converter: Supplier.fromJson,
                      onSaved: (value) => _suppliers =
                          value?.map<String>((e) => e.code).toList() ?? [],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(right: 10),
                    constraints: const BoxConstraints(maxWidth: 350),
                    child: AsyncDropdownMultiple2(
                      label: const Text('Item :', style: _filterLabelStyle),
                      key: const ValueKey('itemSelect'),
                      attributeKey: 'namaitem',
                      path: '/items',
                      textOnSearch: (item) => "${item.code} - ${item.name}",
                      textOnSelected: (item) => item.code,
                      converter: Item.fromJson,
                      onSaved: (value) => _items =
                          value?.map<String>((e) => e.code).toList() ?? [],
                    ),
                  ),
                  SizedBox(
                    width: 350,
                    height: 50,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Stok Gudang:',
                          style: _filterLabelStyle,
                        ),
                        SizedBox(
                          width: 110,
                          height: 90,
                          child: DropdownButtonFormField(
                            decoration: const InputDecoration(
                                contentPadding: EdgeInsets.all(12),
                                border: OutlineInputBorder()),
                            onChanged: (value) =>
                                _warehouseStockComparison = value ?? '',
                            items: const [
                              DropdownMenuItem(value: '', child: Text('')),
                              DropdownMenuItem(
                                  value: 'eq', child: Text('Sama')),
                              DropdownMenuItem(value: 'lt', child: Text('<')),
                              DropdownMenuItem(value: 'gt', child: Text('>')),
                              DropdownMenuItem(value: 'lte', child: Text('<=')),
                              DropdownMenuItem(value: 'gte', child: Text('>=')),
                              DropdownMenuItem(
                                  value: 'nt', child: Text('Bukan')),
                            ],
                            validator: (value) {
                              if (_warehouseStockValue
                                      .toString()
                                      .trim()
                                      .isNotEmpty &&
                                  value.toString().trim().isEmpty) {
                                return 'perbandingan harus diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(
                            width: 80,
                            height: 90,
                            child: TextFormField(
                                keyboardType: TextInputType.number,
                                onChanged: (value) =>
                                    _warehouseStockValue = value,
                                decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.all(12),
                                    border: OutlineInputBorder()),
                                key: const ValueKey('warehouseStock'),
                                validator: (value) {
                                  if (value.toString().trim().isEmpty &&
                                      _warehouseStockComparison
                                          .toString()
                                          .trim()
                                          .isNotEmpty) {
                                    return 'harus isi dengan angka';
                                  }
                                  return null;
                                })),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 350,
                    height: 50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Stok Toko:', style: _filterLabelStyle),
                        SizedBox(
                          width: 110,
                          height: 90,
                          child: DropdownButtonFormField(
                            decoration: const InputDecoration(
                                contentPadding: EdgeInsets.all(12),
                                border: OutlineInputBorder()),
                            onChanged: (value) =>
                                _storeStockComparison = value ?? '',
                            items: const [
                              DropdownMenuItem(value: '', child: Text('')),
                              DropdownMenuItem(
                                  value: 'eq', child: Text('Sama')),
                              DropdownMenuItem(value: 'lt', child: Text('<')),
                              DropdownMenuItem(value: 'gt', child: Text('>')),
                              DropdownMenuItem(value: 'lte', child: Text('<=')),
                              DropdownMenuItem(value: 'gte', child: Text('>=')),
                              DropdownMenuItem(
                                  value: 'nt', child: Text('Bukan')),
                            ],
                            validator: (value) {
                              if (_storeStockValue
                                      .toString()
                                      .trim()
                                      .isNotEmpty &&
                                  value.toString().trim().isEmpty) {
                                return 'perbandingan harus diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(
                            width: 80,
                            height: 90,
                            child: TextFormField(
                                onChanged: (value) => _storeStockValue = value,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.all(12),
                                    border: OutlineInputBorder()),
                                key: const ValueKey('storeStock'),
                                validator: (value) {
                                  if (value.toString().trim().isEmpty &&
                                      _storeStockComparison
                                          .toString()
                                          .trim()
                                          .isNotEmpty) {
                                    return 'harus isi dengan angka';
                                  }
                                  return null;
                                })),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Wrap(
              runSpacing: 10,
              spacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      _displayReport();
                    }
                  },
                  child: const Text('Tampilkan'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      _downloadReport();
                    }
                  },
                  child: const Text('Download'),
                ),
              ],
            ),
            Visibility(visible: _isDisplayTable, child: const Divider()),
            Visibility(
              visible: _isDisplayTable,
              child: SizedBox(
                height: tableHeight,
                child: SyncDataTable(
                  controller: _source,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
