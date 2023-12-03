import 'dart:io';
import 'package:fe_pos/main.dart';
import 'package:flutter/material.dart';
// import 'package:fe_pos/components/dropdown_remote_menu.dart';
// import 'package:fe_pos/components/server.dart';
import 'package:fe_pos/components/dropdown_remote_connection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:bs_flutter_selectbox/bs_flutter_selectbox.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// import 'dart:developer';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

List<BsSelectBoxOption> convertToOptions(List list) {
  return list
      .map(((row) => BsSelectBoxOption(
          value: row['id'],
          text: Text(row['name'].substring(
              0, row['name'].length < 16 ? row['name'].length : 16)))))
      .toList();
}

class SalesPercentageReportPage extends StatelessWidget {
  SalesPercentageReportPage({super.key});
  static const filterLabelStyle =
      TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
  var _brandSelectWidget,
      _supplierSelectWidget,
      _itemTypeSelectWidget,
      _itemSelectWidget;

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

  void _saveXlsxPick(String filename, List<int> data) async {
    String? outputFile;
    if (Platform.isIOS || kIsWeb) {
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
      file.writeAsBytesSync(data);
      log('filename: ${file.path}');
    } else {
      // User canceled the picker
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.read<MyAppState>();
    Server server = appState.server;
    BsSelectBox _brandSelectWidget = BsSelectBox(
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
    BsSelectBox _supplierSelectWidget = BsSelectBox(
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
    BsSelectBox _itemTypeSelectWidget = BsSelectBox(
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

    BsSelectBox _itemSelectWidget = BsSelectBox(
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
                const Text('Merek :', style: filterLabelStyle),
                const SizedBox(width: 10),
                SizedBox(width: 200, child: _brandSelectWidget),
                const SizedBox(
                  width: 10,
                  height: 10,
                ),
                const Text('Jenis/Departemen :', style: filterLabelStyle),
                const SizedBox(width: 10),
                SizedBox(width: 200, child: _itemTypeSelectWidget),
                const SizedBox(
                  width: 10,
                  height: 10,
                ),
                const Text('Supplier :', style: filterLabelStyle),
                const SizedBox(width: 10),
                SizedBox(width: 200, child: _supplierSelectWidget),
                const SizedBox(
                  width: 10,
                  height: 10,
                ),
                const Text('Item :', style: filterLabelStyle),
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
