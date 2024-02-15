import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/model/item_sales_percentage_report.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/custom_data_table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/file_saver.dart';

class SalesPercentageReportPage extends StatefulWidget {
  const SalesPercentageReportPage({super.key});

  @override
  State<SalesPercentageReportPage> createState() =>
      _SalesPercentageReportPageState();
}

class _SalesPercentageReportPageState extends State<SalesPercentageReportPage>
    with AutomaticKeepAliveClientMixin {
  final BsSelectBoxController _brandSelectWidget =
      BsSelectBoxController(multiple: true, processing: true);

  final BsSelectBoxController _supplierSelectWidget =
      BsSelectBoxController(multiple: true, processing: true);

  final BsSelectBoxController _itemTypeSelectWidget =
      BsSelectBoxController(multiple: true, processing: true);

  final BsSelectBoxController _itemSelectWidget =
      BsSelectBoxController(multiple: true, processing: true);

  static const TextStyle _filterLabelStyle =
      TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  late Server server;
  String? _reportType;
  bool _isDisplayTable = false;
  double minimumColumnWidth = 150;
  final dataSource = CustomDataTableSource<ItemSalesPercentageReport>();
  late Flash flash;
  late final Setting setting;
  String _storeStockComparison = '';
  String _storeStockValue = '';
  String _warehouseStockComparison = '';
  String _warehouseStockValue = '';
  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    SessionState sessionState = context.read<SessionState>();
    server = sessionState.server;
    setting = context.read<Setting>();
    flash = Flash(context);
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  void _displayReport() async {
    flash.show(
      const Text('Dalam proses.'),
      MessageType.info,
    );
    _reportType = 'json';
    _requestReport().then(_displayDatatable,
        onError: ((error, stackTrace) =>
            server.defaultErrorResponse(context: context, error: error)));
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
    List brands = _brandSelectWidget
        .getSelectedAll()
        .map((e) => e.getValue().trim())
        .toList();
    List suppliers = _supplierSelectWidget
        .getSelectedAll()
        .map((e) => e.getValue().trim())
        .toList();
    List itemTypes = _itemTypeSelectWidget
        .getSelectedAll()
        .map((e) => e.getValue().trim())
        .toList();
    List items = _itemSelectWidget
        .getSelectedAll()
        .map((e) => e.getValue().trim())
        .toList();
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
          'suppliers[]': suppliers,
          'brands[]': brands,
          'item_types[]': itemTypes,
          'item_codes[]': items,
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
      dataSource.setData(models);
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
    dataSource.columns = setting.tableColumn('itemSalesPercentageReport');
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
                children: [
                  Container(
                      padding: const EdgeInsets.only(right: 10),
                      constraints: const BoxConstraints(maxWidth: 350),
                      child: AsyncDropdownFormField(
                        label: const Text('Merek :', style: _filterLabelStyle),
                        key: const ValueKey('brandSelect'),
                        controller: _brandSelectWidget,
                        path: '/brands',
                      )),
                  Container(
                      padding: const EdgeInsets.only(right: 10),
                      constraints: const BoxConstraints(maxWidth: 350),
                      child: AsyncDropdownFormField(
                        label: const Text('Jenis/Departemen :',
                            style: _filterLabelStyle),
                        key: const ValueKey('brandSelect'),
                        controller: _itemTypeSelectWidget,
                        path: '/item_types',
                      )),
                  Container(
                    padding: const EdgeInsets.only(right: 10),
                    constraints: const BoxConstraints(maxWidth: 350),
                    child: AsyncDropdownFormField(
                      label: const Text('Supplier :', style: _filterLabelStyle),
                      key: const ValueKey('supplierSelect'),
                      controller: _supplierSelectWidget,
                      path: '/suppliers',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(right: 10),
                    constraints: const BoxConstraints(maxWidth: 350),
                    child: AsyncDropdownFormField(
                      label: const Text('Item :', style: _filterLabelStyle),
                      key: const ValueKey('itemSelect'),
                      controller: _itemSelectWidget,
                      path: '/items',
                    ),
                  ),
                  Container(
                    width: 350,
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stok Gudang:',
                          style: _filterLabelStyle,
                        ),
                        SizedBox(
                          width: 110,
                          child: DropdownButtonFormField(
                            decoration: const InputDecoration(
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
                            child: TextFormField(
                                keyboardType: TextInputType.number,
                                onChanged: (value) =>
                                    _warehouseStockValue = value,
                                decoration: const InputDecoration(
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
                  Container(
                    width: 350,
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Stok Toko:', style: _filterLabelStyle),
                        SizedBox(
                          width: 110,
                          child: DropdownButtonFormField(
                            decoration: const InputDecoration(
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
                            child: TextFormField(
                                onChanged: (value) => _storeStockValue = value,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
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
                      _displayReport();
                    }
                  },
                  child: const Text('Tampilkan'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
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
                child: CustomDataTable(
                  controller: dataSource,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
