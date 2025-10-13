import 'package:fe_pos/model/hash_model.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RefreshTablePage extends StatefulWidget {
  const RefreshTablePage({super.key});

  @override
  State<RefreshTablePage> createState() => _RefreshTablePageState();
}

class _RefreshTablePageState extends State<RefreshTablePage> {
  late final Server _server;
  final flash = Flash();
  String? _tableKey;
  @override
  void initState() {
    _server = context.read<Server>();

    super.initState();
  }

  void refreshTable() async {
    var response = await _server
        .post('system_settings/refresh_table', body: {'table_key': _tableKey});

    if (response.statusCode == 200) {
      flash.show(Text(response.data['message'] ?? ''), ToastificationType.info);
    } else {
      flash.showBanner(
          title: 'Gagal Refreh Data',
          description: response.data.toString(),
          messageType: ToastificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Text('Refresh Table'),
            const Divider(),
            const SizedBox(
              height: 10,
            ),
            Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 250,
                    child: AsyncDropdown<HashModel>(
                        allowClear: false,
                        path: 'system_settings/list_tables',
                        onChanged: (model) => _tableKey = model?.data['value'],
                        textOnSearch: (e) => e.data['label'],
                        modelClass: HashModelClass()),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                      onPressed: () => refreshTable(),
                      icon: Icon(Icons.refresh))
                ]),
          ],
        ),
      ),
    );
  }
}
