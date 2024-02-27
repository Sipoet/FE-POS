import 'package:fe_pos/model/sales_group_by_supplier.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/custom_data_table.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/widget/dropdown_remote_connection.dart';

import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
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
  final BsSelectBoxController _brandSelectWidget =
      BsSelectBoxController(multiple: true, processing: true);

  final BsSelectBoxController _supplierSelectWidget =
      BsSelectBoxController(multiple: true, processing: true);

  final BsSelectBoxController _itemTypeSelectWidget =
      BsSelectBoxController(multiple: true, processing: true);

  static const TextStyle _filterLabelStyle =
      TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
  late Server server;
  String? _reportType;
  bool _isDisplayTable = false;
  final dataSource = CustomDataTableSource<SalesGroupBySupplier>();
  late Flash flash;
  late final Setting setting;

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
    List brands =
        _brandSelectWidget.getSelectedAll().map((e) => e.getValue()).toList();
    List suppliers = _supplierSelectWidget
        .getSelectedAll()
        .map((e) => e.getValue())
        .toList();
    List itemTypes = _itemTypeSelectWidget
        .getSelectedAll()
        .map((e) => e.getValue())
        .toList();

    log('supplier $suppliers, brand $brands, item_types: $itemTypes');
    return server.get('item_sales_percentage_reports/group_by_supplier',
        queryParam: {
          'suppliers[]': suppliers,
          'brands[]': brands,
          'item_types[]': itemTypes,
          'report_type': _reportType,
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
      var rawData = data['data'].map<SalesGroupBySupplier>((row) {
        return SalesGroupBySupplier.fromJson(row);
      }).toList();
      dataSource.setData(rawData);
      _isDisplayTable = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final padding = MediaQuery.of(context).padding;
    double tableHeight =
        MediaQuery.of(context).size.height - padding.top - padding.bottom - 150;
    tableHeight = tableHeight > 600 ? 600 : tableHeight;

    dataSource.columns = setting.tableColumn('salesGroupBySupplierReport');

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              direction: Axis.horizontal,
              children: [
                Container(
                    padding: const EdgeInsets.only(right: 10),
                    constraints: const BoxConstraints(maxWidth: 350),
                    child: AsyncDropdownFormField(
                      label: const Text('Merek :', style: _filterLabelStyle),
                      key: const ValueKey('brandSelect'),
                      controller: _brandSelectWidget,
                      attributeKey: 'merek',
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
                      attributeKey: 'jenis',
                      path: '/item_types',
                    )),
                Container(
                  padding: const EdgeInsets.only(right: 10),
                  constraints: const BoxConstraints(maxWidth: 350),
                  child: AsyncDropdownFormField(
                    label: const Text('Supplier :', style: _filterLabelStyle),
                    key: const ValueKey('supplierSelect'),
                    controller: _supplierSelectWidget,
                    attributeKey: 'nama',
                    path: '/suppliers',
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
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
            Visibility(visible: _isDisplayTable, child: const Divider()),
            Visibility(
              visible: _isDisplayTable,
              child: SizedBox(
                height: tableHeight,
                child: CustomDataTable(
                  controller: dataSource,
                  fixedLeftColumns: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
