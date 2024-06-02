import 'package:dropdown_search/dropdown_search.dart';
import 'package:fe_pos/model/sales_group_by_supplier.dart';
import 'package:fe_pos/model/item.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/custom_data_table.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:fe_pos/tool/file_saver.dart';

class SalesGroupBySupplierReportPage extends StatefulWidget {
  const SalesGroupBySupplierReportPage({super.key});

  @override
  State<SalesGroupBySupplierReportPage> createState() =>
      _SalesGroupBySupplierReportPageState();
}

class _SalesGroupBySupplierReportPageState
    extends State<SalesGroupBySupplierReportPage>
    with AutomaticKeepAliveClientMixin {
  static const TextStyle _filterLabelStyle =
      TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
  late Server server;
  String? _reportType;
  bool _isDisplayTable = false;
  late SyncDataTableSource<SalesGroupBySupplier> _source;
  late Flash flash;
  List _brands = [];
  List _suppliers = [];
  List _itemTypes = [];
  List _groupKeys = [];
  final groupList = ['supplier_name', 'brand_name', 'item_type_name'];
  final _cancelToken = CancelToken();
  final _formState = GlobalKey<FormState>();
  late final List<TableColumn> _tableColumns;
  @override
  void initState() {
    server = context.read<Server>();
    final setting = context.read<Setting>();
    flash = Flash(context);
    _tableColumns = setting.tableColumn('salesGroupBySupplierReport');
    _source = SyncDataTableSource<SalesGroupBySupplier>(columns: _tableColumns);
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
    return server.get('item_sales_percentage_reports/grouped_report',
        queryParam: {
          'suppliers[]': _suppliers,
          'brands[]': _brands,
          'item_types[]': _itemTypes,
          'report_type': _reportType,
          'group_names[]': _groupKeys,
          if (page != null) 'page': page.toString(),
          if (per != null) 'per': per.toString()
        },
        type: _reportType ?? 'json',
        cancelToken: _cancelToken);
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
      var rawData = data['data'].map<SalesGroupBySupplier>((row) {
        return SalesGroupBySupplier.fromJson(row);
      }).toList();

      _source =
          SyncDataTableSource<SalesGroupBySupplier>(columns: whitelistColumns);
      _source.setData(rawData);
      _isDisplayTable = true;
    });
  }

  List<TableColumn> get whitelistColumns => () {
        List<TableColumn> columns = List.from(_tableColumns);
        columns.removeWhere(
          (tableColumn) =>
              groupList.contains(tableColumn.key) &&
              !_groupKeys.contains(tableColumn.key),
        );
        columns.sort((columnA, columnB) {
          final index = _groupKeys.indexOf(columnA.key);
          final index2 = _groupKeys.indexOf(columnB.key);
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

    final padding = MediaQuery.of(context).padding;
    double tableHeight =
        MediaQuery.of(context).size.height - padding.top - padding.bottom - 150;
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
              key: _formState,
              child: Wrap(
                direction: Axis.horizontal,
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                      width: 350,
                      child: DropdownSearch.multiSelection(
                        dropdownDecoratorProps: const DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                                border: OutlineInputBorder(),
                                label: Text(
                                  'Group Berdasarkan',
                                  style: _filterLabelStyle,
                                ))),
                        items: groupList,
                        onChanged: (value) => _groupKeys = value,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'harus diisi';
                          }
                          return null;
                        },
                        itemAsString: (item) {
                          if (item == 'supplier_name') {
                            return 'Supplier';
                          } else if (item == 'brand_name') {
                            return 'Merek';
                          } else if (item == 'item_type_name') {
                            return 'Jenis/Departemen';
                          }
                          return '';
                        },
                      )),
                  SizedBox(
                      width: 350,
                      child: AsyncDropdownMultiple2<Brand>(
                        label: const Text('Merek :', style: _filterLabelStyle),
                        key: const ValueKey('brandSelect'),
                        textOnSearch: (Brand brand) => brand.name,
                        converter: Brand.fromJson,
                        attributeKey: 'merek',
                        path: '/brands',
                        onSaved: (value) => _brands = value == null
                            ? []
                            : value.map<String>((e) => e.name).toList(),
                      )),
                  SizedBox(
                      width: 350,
                      child: AsyncDropdownMultiple2<ItemType>(
                        label: const Text('Jenis/Departemen :',
                            style: _filterLabelStyle),
                        key: const ValueKey('itemTypeSelect'),
                        textOnSearch: (itemType) =>
                            "${itemType.name} - ${itemType.description}",
                        textOnSelected: (itemType) => itemType.name,
                        converter: ItemType.fromJson,
                        attributeKey: 'jenis',
                        path: '/item_types',
                        onSaved: (value) => _itemTypes = value == null
                            ? []
                            : value.map<String>((e) => e.name).toList(),
                      )),
                  SizedBox(
                    width: 350,
                    child: AsyncDropdownMultiple2<Supplier>(
                      label: const Text('Supplier :', style: _filterLabelStyle),
                      key: const ValueKey('supplierSelect'),
                      attributeKey: 'nama',
                      path: '/suppliers',
                      textOnSearch: (supplier) =>
                          "${supplier.code} - ${supplier.name}",
                      textOnSelected: (supplier) => supplier.code,
                      converter: Supplier.fromJson,
                      onSaved: (value) => _suppliers = value == null
                          ? []
                          : value.map<String>((e) => e.code).toList(),
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
            Visibility(visible: _isDisplayTable, child: const Divider()),
            Visibility(
              visible: _isDisplayTable,
              child: SizedBox(
                height: tableHeight,
                child: SyncDataTable(
                  controller: _source,
                  fixedLeftColumns: _groupKeys.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
