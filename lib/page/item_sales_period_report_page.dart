import 'dart:io';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/model/item_sales_period_report.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/custom_data_table.dart';
import 'package:fe_pos/widget/date_range_picker.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/widget/dropdown_remote_connection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:bs_flutter_selectbox/bs_flutter_selectbox.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/web_downloader.dart';

class ItemSalesPeriodReportPage extends StatefulWidget {
  const ItemSalesPeriodReportPage({super.key});

  @override
  State<ItemSalesPeriodReportPage> createState() =>
      _ItemSalesPeriodReportPageState();
}

class _ItemSalesPeriodReportPageState extends State<ItemSalesPeriodReportPage>
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
      TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
  late Server server;
  String? _reportType;
  bool _isDisplayTable = false;
  final _dataSource = CustomDataTableSource();
  DateTimeRange _dateRange = DateTimeRange(
      start: DateTime.now().copyWith(hour: 0, minute: 0, second: 0),
      end: DateTime.now().copyWith(hour: 23, minute: 59, second: 59));
  late Flash flash;
  @override
  void initState() {
    SessionState sessionState = context.read<SessionState>();
    flash = Flash(context);
    server = sessionState.server;
    super.initState();
  }

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
    List items =
        _itemSelectWidget.getSelectedAll().map((e) => e.getValue()).toList();
    log('supplier $suppliers, brand $brands, item_types: $itemTypes, items: $items');
    return server.get('item_sales/period_report',
        queryParam: {
          'suppliers[]': suppliers,
          'brands[]': brands,
          'item_types[]': itemTypes,
          'items[]': items,
          'report_type': _reportType,
          'start_time': _dateRange.start.toIso8601String(),
          'end_time': _dateRange.end.toIso8601String(),
          if (page != null) 'page': page.toString(),
          if (per != null) 'per': per.toString()
        },
        type: _reportType ?? 'json');
  }

  void _downloadResponse(response) async {
    flash.hide();
    if (response.statusCode != 200) {
      return;
    }
    String filename = response.headers.value('content-disposition') ?? '';
    if (filename.isEmpty) {
      return;
    }
    filename = filename.substring(
        filename.indexOf('filename="') + 10, filename.indexOf('xlsx";') + 4);
    if (response.statusCode == 200) {
      _saveXlsxPick(filename, response.data);
    } else {
      flash.show(const Text('gagal simpan ke excel'), MessageType.failed);
    }
  }

  void _displayDatatable(response) async {
    flash.hide();
    if (response.statusCode != 200) {
      return;
    }
    var data = response.data;
    setState(() {
      var rawData = data['data'].map<ItemSalesPeriodReport>((row) {
        return ItemSalesPeriodReport.fromJson(row);
      }).toList();
      _dataSource.setData(rawData);
      _isDisplayTable = true;
    });
  }

  void _saveXlsxPick(String filename, List<int> bytes) async {
    String? outputFile;
    if (kIsWeb) {
      var webDownloader = const WebDownloader();
      webDownloader.download(filename, bytes);
      return;
    } else if (Platform.isIOS) {
      Directory? dir = await getDownloadsDirectory();
      outputFile = "${dir?.path}/$filename";
    } else if (Platform.isAndroid) {
      Directory? dir = Directory('/storage/emulated/0/Download');
      if (!dir.existsSync()) {
        dir = await getExternalStorageDirectory();
      }
      outputFile = "${dir?.path}/$filename";
    } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Please select an output file:',
          fileName: filename,
          type: FileType.custom,
          allowedExtensions: ['xlsx']);
    }

    if (outputFile != null) {
      File file = File(outputFile);
      file.writeAsBytesSync(bytes);
      flash.showBanner(
          messageType: MessageType.success,
          title: 'Sukses download',
          description: 'sukses disimpan di ${file.path}');
    }
  }

  List<BsSelectBoxOption> convertToOptions(List list) {
    return list
        .map(
          ((row) => BsSelectBoxOption(
              value: row['id'],
              text: Tooltip(
                  message: row['name'],
                  child: Text(row['name'].substring(
                      0, row['name'].length < 30 ? row['name'].length : 30))))),
        )
        .toList();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    DropdownRemoteConnection connection =
        DropdownRemoteConnection(server, context);
    final padding = MediaQuery.of(context).padding;
    double tableHeight =
        MediaQuery.of(context).size.height - padding.top - padding.bottom - 150;
    tableHeight = tableHeight > 600 ? 600 : tableHeight;
    var setting = context.read<Setting>();
    _dataSource.columns = setting.tableColumn('itemSalesPeriodReport');

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
                  width: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                          padding: EdgeInsets.only(left: 5, bottom: 5),
                          child: Text('Tanggal :', style: _filterLabelStyle)),
                      DateRangePicker(
                        startDate: _dateRange.start,
                        endDate: _dateRange.end,
                        onChanged: (range) => _dateRange = range,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(right: 10),
                  constraints:
                      const BoxConstraints(maxHeight: 100, maxWidth: 320),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                            padding: EdgeInsets.only(left: 5, bottom: 5),
                            child: Text('Merek :', style: _filterLabelStyle)),
                        Flexible(
                            child: BsSelectBox(
                          key: const ValueKey('brandSelect'),
                          searchable: true,
                          controller: _brandSelectWidget,
                          serverSide: (params) async {
                            var list = await connection.getData('/brands',
                                query: params['searchValue'].toString());
                            return BsSelectBoxResponse(
                                options: convertToOptions(list));
                          },
                        )),
                      ]),
                ),
                Container(
                    padding: const EdgeInsets.only(right: 10),
                    constraints:
                        const BoxConstraints(maxHeight: 100, maxWidth: 320),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 5, bottom: 5),
                            child: Text('Jenis/Departemen :',
                                style: _filterLabelStyle),
                          ),
                          Flexible(
                              child: BsSelectBox(
                            key: const ValueKey('itemTypeSelect'),
                            searchable: true,
                            controller: _itemTypeSelectWidget,
                            serverSide: (params) async {
                              var list = await connection.getData('/item_types',
                                  query: params['searchValue'].toString());
                              return BsSelectBoxResponse(
                                  options: convertToOptions(list));
                            },
                          )),
                        ])),
                Container(
                    padding: const EdgeInsets.only(right: 10),
                    constraints:
                        const BoxConstraints(maxHeight: 100, maxWidth: 320),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 5, bottom: 5),
                            child: Text('Supplier :', style: _filterLabelStyle),
                          ),
                          Flexible(
                              child: BsSelectBox(
                            key: const ValueKey('supplierSelect'),
                            searchable: true,
                            controller: _supplierSelectWidget,
                            serverSide: (params) async {
                              var list = await connection.getData('/suppliers',
                                  query: params['searchValue'].toString());
                              return BsSelectBoxResponse(
                                  options: convertToOptions(list));
                            },
                          )),
                        ])),
                Container(
                    padding: const EdgeInsets.only(right: 10),
                    constraints:
                        const BoxConstraints(maxHeight: 100, maxWidth: 320),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 5, bottom: 5),
                            child: Text('Item :', style: _filterLabelStyle),
                          ),
                          Flexible(
                              child: BsSelectBox(
                            key: const ValueKey('itemSelect'),
                            searchable: true,
                            controller: _itemSelectWidget,
                            serverSide: (params) async {
                              var list = await connection.getData('/items',
                                  query: params['searchValue'].toString());
                              return BsSelectBoxResponse(
                                  options: convertToOptions(list));
                            },
                          )),
                        ])),
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
            if (_isDisplayTable) const Divider(),
            if (_isDisplayTable)
              SizedBox(
                height: tableHeight,
                child: CustomDataTable(
                  controller: _dataSource,
                  fixedLeftColumns: 1,
                  columns: _dataSource.columns,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
