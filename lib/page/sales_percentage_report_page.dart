import 'dart:convert';
import 'dart:io';
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

class _SalesPercentageReportPageState extends State<SalesPercentageReportPage> {
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
  List<DataColumn> _columns = [];
  List _columnOrder = [];
  SalesPercentageDataSource dataSource = SalesPercentageDataSource();
  @override
  void initState() {
    SessionState sessionState = context.read<SessionState>();
    server = sessionState.server;
    dataSource.setData([], 0, true);
    _fetchTableColumn();
    super.initState();
  }

  void _fetchTableColumn() async {
    var response = await server.get('item_sales_percentage_reports/columns');
    if (response.statusCode != 200) {
      return;
    }
    Map responseBody = jsonDecode(response.body);
    var data = responseBody['data'] ?? {'column_names': [], 'column_order': []};
    _columnOrder = data['column_order'];
    _columns = [];
    setState(() {
      _tableWidth = 50;
      data['column_names'].forEach((columnName) {
        double width = _columnWidth[columnName] ?? 215.0;
        _tableWidth += width;
        _columns.add(DataColumn2(
          fixedWidth: width,
          onSort: ((columnIndex, ascending) {
            setState(() {
              _sortColumnIndex = columnIndex;
              _sortAscending = ascending;
            });
            dataSource.sortData(_sortColumnIndex, _sortAscending);
          }),
          label: Text(
            columnName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ));
      });
    });
  }

  void _displayReport() async {
    displayFlash(const Text('Dalam proses.'),
        duration: const Duration(minutes: 5));
    _reportType = 'json';
    _requestReport().then(_displayDatatable);
  }

  void _downloadReport() async {
    displayFlash(const Text('Dalam proses.'),
        duration: const Duration(minutes: 5));
    _reportType = 'xlsx';
    _requestReport().then(_downloadResponse);
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
    return server.get('item_sales_percentage_reports', queryParam: {
      'suppliers[]': suppliers,
      'brands[]': brands,
      'item_types[]': itemTypes,
      'items[]': items,
      'report_type': _reportType,
      if (page != null) 'page': page.toString(),
      if (per != null) 'per': per.toString()
    });
  }

  void _downloadResponse(response) async {
    hideFlash();
    if (response.statusCode != 200) {
      return;
    }
    String? filename = response.headers['content-disposition'];
    if (filename == null) {
      return;
    }
    filename = filename.substring(
        filename.indexOf('filename="') + 10, filename.indexOf('xlsx";') + 4);
    if (response.statusCode == 200) {
      _saveXlsxPick(filename, response.bodyBytes);
    } else {
      log("Response get ${response.body}");
    }
  }

  final Map _columnWidth = {
    'Nama Item': 300.0,
    'Kode Item': 150.0,
    'Jenis/Departemen': 230.0,
    'Harga Beli Rata-rata': 230.0,
    'Persentase Laku Terjual': 180.0,
  };
  double _tableWidth = 4000;
  void _displayDatatable(response) async {
    hideFlash();
    if (response.statusCode != 200) {
      return;
    }
    var data = jsonDecode(response.body);
    setState(() {
      var rawData = data['data'].map<List<Comparable<Object>>>((row) {
        Map attributes = row['attributes'];
        return _columnOrder
            .map<Comparable<Object>>((key) => attributes[key])
            .toList();
      }).toList();
      dataSource.setData(rawData, _sortColumnIndex, _sortAscending);
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
      Directory? dir = await getExternalStorageDirectory();
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
      log('filename: ${file.path}');
    }
  }

  List<BsSelectBoxOption> convertToOptions(List list) {
    return list
        .map(((row) => BsSelectBoxOption(
            value: row['id'],
            text: Text(row['name'].substring(
                0, row['name'].length < 16 ? row['name'].length : 16)))))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    DropdownRemoteConnection connection = DropdownRemoteConnection(server);
    // Size size = MediaQuery.of(context).size;
    // final padding = MediaQuery.of(context).padding;
    // double height = size.height - padding.top - padding.bottom - 280;
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            direction: Axis.horizontal,
            children: [
              SizedBox(
                width: 310,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                          padding: EdgeInsets.only(left: 5, bottom: 5),
                          child: Text('Merek :', style: _filterLabelStyle)),
                      SizedBox(
                          width: 300,
                          height: 55,
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
              SizedBox(
                  width: 310,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 5, bottom: 5),
                          child: Text('Jenis/Departemen :',
                              style: _filterLabelStyle),
                        ),
                        SizedBox(
                            width: 300,
                            height: 55,
                            child: BsSelectBox(
                              key: const ValueKey('itemTypeSelect'),
                              searchable: true,
                              controller: _itemTypeSelectWidget,
                              serverSide: (params) async {
                                var list = await connection.getData(
                                    '/item_types',
                                    query: params['searchValue'].toString());
                                return BsSelectBoxResponse(
                                    options: convertToOptions(list));
                              },
                            )),
                      ])),
              SizedBox(
                  width: 310,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 5, bottom: 5),
                          child: Text('Supplier :', style: _filterLabelStyle),
                        ),
                        SizedBox(
                            width: 300,
                            child: BsSelectBox(
                              key: const ValueKey('supplierSelect'),
                              searchable: true,
                              controller: _supplierSelectWidget,
                              serverSide: (params) async {
                                var list = await connection.getData(
                                    '/suppliers',
                                    query: params['searchValue'].toString());
                                return BsSelectBoxResponse(
                                    options: convertToOptions(list));
                              },
                            )),
                      ])),
              SizedBox(
                  width: 310,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 5, bottom: 5),
                          child: Text('Item :', style: _filterLabelStyle),
                        ),
                        SizedBox(
                            width: 300,
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
          Row(
            children: [
              ElevatedButton(
                onPressed: () => {_displayReport()},
                child: const Text('Tampilkan'),
              ),
              const SizedBox(
                width: 10,
              ),
              ElevatedButton(
                onPressed: () => {_downloadReport()},
                child: const Text('Download'),
              ),
            ],
          ),
          if (_isDisplayTable) const Divider(),
          if (_isDisplayTable)
            Expanded(
              // constraints: BoxConstraints(maxHeight: height),
              child: PaginatedDataTable2(
                source: dataSource,
                fixedLeftColumns: 1,
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                border: TableBorder.all(
                    width: 1, color: colorScheme.onSecondary.withOpacity(0.3)),
                empty: const Text('Data tidak ditemukan'),
                columns: _columns,
                minWidth: _tableWidth,
                headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                  return colorScheme.onSecondaryContainer.withOpacity(0.08);
                }),
              ),
            ),
        ],
      ),
    );
  }

  void displayFlash(Widget content,
      {Duration duration = const Duration(seconds: 5)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: content,
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
        duration: duration,
        dismissDirection: DismissDirection.up,
        margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 60,
            left: MediaQuery.of(context).size.width - 350,
            right: 50),
      ),
    );
  }

  void hideFlash() {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}

class SalesPercentageDataSource extends DataTableSource {
  late List<List<Comparable<Object>>> sortedData;
  void setData(List<List<Comparable<Object>>> rawData, int sortColumn,
      bool sortAscending) {
    sortedData = rawData.toList();
    sortData(sortColumn, sortAscending);
  }

  void sortData(int sortColumn, bool sortAscending) {
    sortedData.sort((List<Comparable<Object>> a, List<Comparable<Object>> b) {
      final Comparable<Object> cellA = a[sortColumn];
      final Comparable<Object> cellB = b[sortColumn];
      return cellA.compareTo(cellB) * (sortAscending ? 1 : -1);
    });
    notifyListeners();
  }

  @override
  int get rowCount => sortedData.length;

  static DataCell _decorateCell(Object cell) {
    if (cell is double || cell is int) {
      String val = _formatNumber(cell);
      return DataCell(
          Align(alignment: Alignment.centerRight, child: SelectableText(val)));
    } else {
      return DataCell(SelectableText(cell.toString()));
    }
  }

  static String _formatNumber(number) {
    var um = number.toString().split('.');
    int strLength = um[0].length;
    List components = [];
    while (strLength >= 3) {
      components.add(um[0].substring(strLength - 3, strLength));
      components.add(',');
      strLength -= 3;
    }
    if (strLength > 0) {
      components.add(um[0].substring(0, strLength));
    } else {
      components.removeAt(components.length - 1);
    }
    components = components.reversed.toList();
    if (um.length == 2) components.add(".${um[1]}");
    return components.join();
  }

  @override
  DataRow? getRow(int index) {
    return DataRow.byIndex(
      index: index,
      cells: sortedData[index]
          .map<DataCell>((cell) => _decorateCell(cell))
          .toList(),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
