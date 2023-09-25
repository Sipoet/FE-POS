import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fe_pos/components/dropdown_remote_menu.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class SalesPercentageReportPage extends StatelessWidget {
  // const SalesPercentageReportPage({super.key});
  static const filterLabelStyle =
      TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  final Server server =
      Server(host: 'localhost', port: 3000, jwt: '', session: '');

  void _downloadReport() async {
    String _brand = _brandSelectWidget.dropdownValue;
    String _supplier = _supplierSelectWidget.dropdownValue;
    String _itemType = _itemTypeSelectWidget.dropdownValue;
    log('supplier ${_supplier}, brand ${_brand}');

    server.get('/reports/item_sales_percentage', {
      'suppliers[]': [_supplier],
      'brands[]': [_brand],
      'item_types[]': [_itemType]
    }).then(_testResponse);
  }

  void _testResponse(response) async {
    String filename = response.headers['content-disposition'];
    filename = filename.substring(
        filename.indexOf('filename="') + 10, filename.indexOf('csv";') + 3);
    if (response.statusCode == 200) {
      String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Please select an output file:',
          fileName: filename,
          type: FileType.custom,
          allowedExtensions: ['csv']);
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

  var _brandSelectWidget;
  var _supplierSelectWidget;
  var _itemTypeSelectWidget;

  @override
  Widget build(BuildContext context) {
    _brandSelectWidget = DropdownRemoteMenu(
      path: '/brands',
      server: server,
      dropdownValue: '',
      width: 150,
    );
    _supplierSelectWidget = DropdownRemoteMenu(
      path: '/suppliers',
      server: server,
      dropdownValue: '',
      width: 150,
    );
    _itemTypeSelectWidget = DropdownRemoteMenu(
      path: '/item_types',
      server: server,
      dropdownValue: '',
      width: 150,
    );
    return Center(
      child: Column(
        children: [
          const Text('Filter'),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              children: [
                const Text('Merek :', style: filterLabelStyle),
                const SizedBox(width: 10),
                _brandSelectWidget,
                const SizedBox(width: 10),
                const Text('Jenis/Departemen :', style: filterLabelStyle),
                const SizedBox(width: 10),
                _itemTypeSelectWidget,
                const SizedBox(width: 10),
                const Text('Supplier :', style: filterLabelStyle),
                const SizedBox(width: 10),
                _supplierSelectWidget
              ],
            ),
          ),
          SizedBox(
            height: 10,
          ),
          ElevatedButton(
            child: Text('Download'),
            onPressed: _downloadReport,
          )
        ],
      ),
    );
  }
}
