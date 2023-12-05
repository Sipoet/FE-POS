import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fe_pos/components/dropdown_remote_connection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:bs_flutter_selectbox/bs_flutter_selectbox.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/session_state.dart';
import 'package:fe_pos/components/web_downloader.dart';

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

  @override
  void initState() {
    super.initState();
    var appState = context.read<SessionState>();
    Server server = appState.server;
    _brandSelectWidget = BsSelectBox(
      key: const ValueKey('brandSelect'),
      searchable: true,
      controller: BsSelectBoxController(
        multiple: true,
      ),
      serverSide: (params) async {
        DropdownRemoteConnection connection = DropdownRemoteConnection(server);
        var list = await connection.getData('/brands',
            query: params['searchValue'].toString());
        return BsSelectBoxResponse(options: convertToOptions(list));
      },
    );
    _supplierSelectWidget = BsSelectBox(
      key: const ValueKey('supplierSelect'),
      searchable: true,
      controller: BsSelectBoxController(
        multiple: true,
      ),
      serverSide: (params) async {
        DropdownRemoteConnection connection = DropdownRemoteConnection(server);
        var list = await connection.getData('/suppliers',
            query: params['searchValue'].toString());
        return BsSelectBoxResponse(options: convertToOptions(list));
      },
    );
    _itemTypeSelectWidget = BsSelectBox(
      key: const ValueKey('itemTypeSelect'),
      searchable: true,
      controller: BsSelectBoxController(
        multiple: true,
      ),
      serverSide: (params) async {
        DropdownRemoteConnection connection = DropdownRemoteConnection(server);
        var list = await connection.getData('/item_types',
            query: params['searchValue'].toString());
        return BsSelectBoxResponse(options: convertToOptions(list));
      },
    );

    _itemSelectWidget = BsSelectBox(
      key: const ValueKey('itemSelect'),
      searchable: true,
      controller: BsSelectBoxController(
        multiple: true,
      ),
      serverSide: (params) async {
        DropdownRemoteConnection connection = DropdownRemoteConnection(server);
        var list = await connection.getData('/items',
            query: params['searchValue'].toString());
        return BsSelectBoxResponse(options: convertToOptions(list));
      },
    );
  }

  void _downloadReport(Server server) async {
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
    server.get('/reports/item_sales_percentage', {
      'suppliers[]': suppliers,
      'brands[]': brands,
      'item_types[]': itemTypes,
      'items[]': items,
    }).then(_downloadResponse);
  }

  void _downloadResponse(response) async {
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
    var appState = context.read<SessionState>();
    Server server = appState.server;
    return Center(
      child: Column(
        children: [
          const Text('Filter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              children: [
                const Text('Merek :', style: _filterLabelStyle),
                const SizedBox(width: 10),
                SizedBox(width: 200, child: _brandSelectWidget),
                const SizedBox(
                  width: 10,
                  height: 10,
                ),
                const Text('Jenis/Departemen :', style: _filterLabelStyle),
                const SizedBox(width: 10),
                SizedBox(width: 200, child: _itemTypeSelectWidget),
                const SizedBox(
                  width: 10,
                  height: 10,
                ),
                const Text('Supplier :', style: _filterLabelStyle),
                const SizedBox(width: 10),
                SizedBox(width: 200, child: _supplierSelectWidget),
                const SizedBox(
                  width: 10,
                  height: 10,
                ),
                const Text('Item :', style: _filterLabelStyle),
                const SizedBox(width: 10),
                SizedBox(width: 200, child: _itemSelectWidget),
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          ElevatedButton(
            onPressed: () => {_downloadReport(server)},
            child: const Text('Download'),
          )
        ],
      ),
    );
  }
}
