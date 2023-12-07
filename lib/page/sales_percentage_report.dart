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
import 'package:fe_pos/widget/web_downloader.dart';
import 'package:data_table_2/data_table_2.dart';

List<BsSelectBoxOption> convertToOptions(List list) {
  return list
      .map(((row) => BsSelectBoxOption(
          value: row['id'],
          text: Text(row['name'].substring(
              0, row['name'].length < 16 ? row['name'].length : 16)))))
      .toList();
}

class SalesPercentageReportPage extends StatefulWidget {
  const SalesPercentageReportPage({super.key});

  @override
  State<SalesPercentageReportPage> createState() =>
      _SalesPercentageReportPageState();
}

class _SalesPercentageReportPageState extends State<SalesPercentageReportPage> {
  late BsSelectBox _brandSelectWidget;

  late BsSelectBox _supplierSelectWidget;

  late BsSelectBox _itemTypeSelectWidget;

  late BsSelectBox _itemSelectWidget;

  static const TextStyle _filterLabelStyle =
      TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
  late Server server;
  String? _reportType;
  bool _isDisplayTable = false;
  List<DataColumn> _columns = [];
  List<DataRow> _rows = [];
  @override
  void initState() {
    super.initState();
    var appState = context.read<SessionState>();
    server = appState.server;
    DropdownRemoteConnection connection = DropdownRemoteConnection(server);
    _brandSelectWidget = BsSelectBox(
      key: const ValueKey('brandSelect'),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      searchable: true,
      controller: BsSelectBoxController(
        multiple: true,
      ),
      serverSide: (params) async {
        var list = await connection.getData('/brands',
            query: params['searchValue'].toString());
        return BsSelectBoxResponse(options: convertToOptions(list));
      },
    );
    _supplierSelectWidget = BsSelectBox(
      key: const ValueKey('supplierSelect'),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      searchable: true,
      controller: BsSelectBoxController(
        multiple: true,
      ),
      serverSide: (params) async {
        var list = await connection.getData('/suppliers',
            query: params['searchValue'].toString());
        return BsSelectBoxResponse(options: convertToOptions(list));
      },
    );
    _itemTypeSelectWidget = BsSelectBox(
      key: const ValueKey('itemTypeSelect'),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      searchable: true,
      controller: BsSelectBoxController(
        multiple: true,
      ),
      serverSide: (params) async {
        var list = await connection.getData('/item_types',
            query: params['searchValue'].toString());
        return BsSelectBoxResponse(options: convertToOptions(list));
      },
    );

    _itemSelectWidget = BsSelectBox(
      key: const ValueKey('itemSelect'),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      searchable: true,
      controller: BsSelectBoxController(
        multiple: true,
      ),
      serverSide: (params) async {
        var list = await connection.getData('/items',
            query: params['searchValue'].toString());
        return BsSelectBoxResponse(options: convertToOptions(list));
      },
    );
  }

  void _displayReport() async {
    _reportType = 'json';
    _requestReport().then(_displayDatatable);
  }

  void _downloadReport() async {
    _reportType = 'xlsx';
    _requestReport().then(_downloadResponse);
  }

  Future _requestReport({int? page, int? per}) async {
    List brands = _brandSelectWidget.controller
        .getSelectedAll()
        .map((e) => e.getValue())
        .toList();
    List suppliers = _supplierSelectWidget.controller
        .getSelectedAll()
        .map((e) => e.getValue())
        .toList();
    List itemTypes = _itemTypeSelectWidget.controller
        .getSelectedAll()
        .map((e) => e.getValue())
        .toList();
    List items = _itemSelectWidget.controller
        .getSelectedAll()
        .map((e) => e.getValue())
        .toList();
    log('supplier $suppliers, brand $brands, item_types: $itemTypes, items: $items');
    return server.get('/reports/item_sales_percentage', {
      'suppliers[]': suppliers,
      'brands[]': brands,
      'item_types[]': itemTypes,
      'items[]': items,
      'report_type': _reportType,
      'page': page.toString(),
      'per': per.toString()
    });
  }

  void _downloadResponse(response) async {
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
    'Kode Item': 140.0,
    'Persentase Laku Terjual': 210.0,
    'Harga Beli Rata-rata': 210.0
  };
  double _tableWidth = 4000;
  void _displayDatatable(response) async {
    if (response.statusCode != 200) {
      return;
    }
    var data = jsonDecode(response.body);
    var meta = data['meta'] ?? {'column_names': [], 'column_order': []};
    setState(() {
      _columns = [];
      _tableWidth = 50.0;

      meta['column_names'].forEach((columnName) {
        double width = _columnWidth[columnName] ?? 195.0;
        _tableWidth += width;
        _columns.add(DataColumn2(
          fixedWidth: width,
          label: Text(
            columnName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ));
      });
      _rows = [];
      int numRow = 1;
      List columnOrder = meta['column_order'];
      data['data'].forEach((row) {
        List<DataCell> dataCells = columnOrder.map<DataCell>((key) {
          return DataCell(SelectableText(
            _decorateCell(row['attributes'][key]),
          ));
        }).toList();
        _rows.add(DataRow(
          selected: numRow.isEven,
          cells: dataCells,
        ));
        numRow += 1;
      });
      _isDisplayTable = true;
    });
  }

  String _decorateCell(cell) {
    if (cell is double) {
      return _decorateNumber(cell);
    } else {
      return cell.toString();
    }
  }

  _decorateNumber(number) {
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
      components.removeAt(0);
    }
    components = components.reversed.toList();
    components.add(".${um[1]}");
    return components.join();
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
    } else {
      // User canceled the picker
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    double height = size.height - padding.top - padding.bottom - 250;
    return Column(
      children: [
        const Text('Filter',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('Merek :', style: _filterLabelStyle),
                  SizedBox(width: 300, child: _brandSelectWidget),
                ],
              ),
              Row(children: [
                const Text('Jenis/Departemen :', style: _filterLabelStyle),
                SizedBox(width: 300, child: _itemTypeSelectWidget),
              ]),
              Row(children: [
                const Text('Supplier :', style: _filterLabelStyle),
                SizedBox(width: 300, child: _supplierSelectWidget),
              ]),
              Row(children: [
                const Text('Item :', style: _filterLabelStyle),
                SizedBox(width: 300, child: _itemSelectWidget),
              ]),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 50),
          child: Row(
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
        ),
        if (_isDisplayTable)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const Divider(),
                Container(
                  constraints: BoxConstraints(maxHeight: height),
                  child: DataTable2(
                    showBottomBorder: true,
                    fixedLeftColumns: 1,
                    empty: const Text('Data tidak ditemukan'),
                    columns: _columns,
                    rows: _rows,
                    minWidth: _tableWidth,
                    headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                      return Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.08);
                    }),
                    dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.08);
                      }
                      return null; // Use the default value.
                    }),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
