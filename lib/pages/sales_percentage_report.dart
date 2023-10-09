import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:fe_pos/components/dropdown_remote_menu.dart';
// import 'package:fe_pos/components/server.dart';
import 'package:fe_pos/components/dropdown_remote_connection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:bs_flutter_selectbox/bs_flutter_selectbox.dart';
// import 'dart:developer';
// import 'package:path_provider/path_provider.dart';

Server server = Server(host: 'backend', port: 3000, jwt: '', session: '');
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
  final BsSelectBox _brandSelectWidget = BsSelectBox(
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
  final BsSelectBox _supplierSelectWidget = BsSelectBox(
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
  final BsSelectBox _itemTypeSelectWidget = BsSelectBox(
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

  final BsSelectBox _itemSelectWidget = BsSelectBox(
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

  void _downloadReport() async {
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
      String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Please select an output file:',
          fileName: filename,
          type: FileType.custom,
          allowedExtensions: ['xlsx']);
      if (outputFile != null) {
        File file = File(outputFile);
        file.writeAsBytesSync(response.bodyBytes);
        log('filename: ${file.path}');
      } else {
        // User canceled the picker
      }
    } else {
      log("Response get ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _downloadReport,
            child: const Text('Download'),
          )
        ],
      ),
    );
  }
}
