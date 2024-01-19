import 'dart:io';
import 'package:fe_pos/tool/datatable.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/model/item_sales_percentage_report.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/widget/dropdown_remote_connection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:bs_flutter_selectbox/bs_flutter_selectbox.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/tool/web_downloader.dart';
import 'package:data_table_2/data_table_2.dart';

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
      TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
  late Server server;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  String? _reportType;
  bool _isDisplayTable = false;
  List<String> _columnOrder = [];
  final Map<String, ColumnDetail> _columnWidth = {};
  double minimumColumnWidth = 150;
  SalesPercentageDataSource dataSource = SalesPercentageDataSource();
  late Flash flash;
  late final Setting setting;
  double _tableWidth = 4000;
  final key = GlobalKey<PaginatedDataTable2State>();

  @override
  void initState() {
    SessionState sessionState = context.read<SessionState>();
    server = sessionState.server;
    setting = context.read<Setting>();
    flash = Flash(context);

    _initTableColumn();
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  void _initTableColumn() async {
    Setting setting = context.read<Setting>();
    List<String> columnNames = setting.columnNames('itemSalesPercentageReport');
    _columnOrder = setting.columnOrder('itemSalesPercentageReport');
    for (String columnName in columnNames) {
      _columnWidth[columnName] =
          ColumnDetail(initX: 0, width: minimumColumnWidth);
    }
    dataSource.columnDetails = _columnWidth;
    dataSource.setData([], _columnOrder[0], true);
    dataSource.setKeys(_columnOrder);
  }

  DataColumn generateColumn(String columnName) {
    ColumnDetail columnDetail = dataSource.columnDetails[columnName] ??
        ColumnDetail(initX: 0, width: minimumColumnWidth);
    return DataColumn2(
      tooltip: columnName,
      onSort: ((columnIndex, ascending) {
        setState(() {
          _sortColumnIndex = columnIndex;
          _sortAscending = ascending;
        });
        dataSource.sortData(_columnOrder[_sortColumnIndex], _sortAscending);
      }),
      label: Stack(
        alignment: AlignmentDirectional.centerStart,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 10,
            width: columnDetail.width - 70,
            child: Text(
              columnName,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      columnDetail.initX = details.globalPosition.dx;
                    });
                  },
                  onPanUpdate: (details) {
                    final increment =
                        details.globalPosition.dx - columnDetail.initX;
                    final newWidth = columnDetail.width + increment;
                    setState(() {
                      columnDetail.initX = details.globalPosition.dx;
                      columnDetail.width = newWidth > minimumColumnWidth
                          ? newWidth
                          : minimumColumnWidth;

                      _tableWidth = calculateTableWidth();
                    });
                  },
                  child: const Icon(
                    Icons.drag_indicator_sharp,
                    size: 20,
                  )))
        ],
      ),
    );
  }

  double calculateTableWidth() {
    double tableWidth = 0;
    for (ColumnDetail columnDetail in dataSource.columnDetails.values) {
      tableWidth += columnDetail.width;
    }
    return tableWidth;
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
    log('supplier $suppliers, brand $brands, item_types: $itemTypes, item_codes: $items');
    return server.get('item_sales_percentage_reports',
        queryParam: {
          'suppliers[]': suppliers,
          'brands[]': brands,
          'item_types[]': itemTypes,
          'item_codes[]': items,
          'report_type': _reportType,
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
      var rawData = data['data'].map<ItemSalesPercentageReport>((row) {
        return ItemSalesPercentageReport.fromJson(row);
      }).toList();
      key.currentState?.pageTo(1);
      dataSource.setData(
          rawData, _columnOrder[_sortColumnIndex], _sortAscending);
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
  Widget build(BuildContext context) {
    super.build(context);
    final padding = MediaQuery.of(context).padding;
    double tableHeight =
        MediaQuery.of(context).size.height - padding.top - padding.bottom - 150;
    tableHeight = tableHeight > 600 ? 600 : tableHeight;
    final DropdownRemoteConnection connection =
        DropdownRemoteConnection(server, context);
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    List<String> columnNames = setting.columnNames('itemSalesPercentageReport');
    List<DataColumn> columns = [];
    for (String columnName in columnNames) {
      columns.add(generateColumn(columnName));
    }

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
                    constraints: const BoxConstraints(maxWidth: 350),
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
                    constraints: const BoxConstraints(maxWidth: 350),
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
                    constraints: const BoxConstraints(maxWidth: 350),
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
            Visibility(visible: _isDisplayTable, child: const Divider()),
            Visibility(
              visible: _isDisplayTable,
              child: SizedBox(
                height: tableHeight,
                child: PaginatedDataTable2(
                  key: key,
                  source: dataSource,
                  fixedLeftColumns: 1,
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  border: TableBorder.all(
                      width: 1, color: colorScheme.outline.withOpacity(0.5)),
                  empty: const Text('Data tidak ditemukan'),
                  columns: columns,
                  minWidth: _tableWidth,
                  headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                    return colorScheme.secondaryContainer.withOpacity(0.08);
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SalesPercentageDataSource extends Datatable {}
