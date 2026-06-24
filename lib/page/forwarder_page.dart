import 'package:fe_pos/model/forwarder.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/page/forwarder_form_page.dart';

class ForwarderPage extends StatefulWidget {
  const ForwarderPage({super.key});

  @override
  State<ForwarderPage> createState() => _ForwarderPageState();
}

class _ForwarderPageState extends State<ForwarderPage> with DefaultResponse {
  late final TableController _source;
  late final Server server;
  late Flash flash;
  late final Authorizer setting;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    setting = context.read<Authorizer>();
    super.initState();
    Future.delayed(Duration.zero, refreshTable);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> refreshTable() async {
    _source.refreshTable();
  }

  Future<DataTableResponse<Forwarder>> fetchForwarders(QueryRequest request) {
    return ForwarderClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<Forwarder>(
            models: value.models,
            totalPage: value.metadata['total_pages'],
          ),
          onError: (error) {
            defaultErrorResponse(error: error);
            return DataTableResponse.empty();
          },
        );
  }

  void openForm(Forwarder forwarder) {
    final tabManager = context.read<TabManager>();

    final desc = forwarder.isNewRecord ? 'Tambah' : 'Edit';
    tabManager.addTab(
      '$desc Forwarder ${forwarder.name}',
      ForwarderFormPage(forwarder: forwarder),
    );
  }

  void deleteRecord(Forwarder forwarder) {
    showConfirmDialog(
      message: 'Apakah Yakin Hapus Forwarder ${forwarder.name}',
      onSubmit: () {
        forwarder.destroy(server).then((result) {
          if (result) {
            flash.show(Text('Sukses hapus ${forwarder.name}'), .success);
            refreshTable();
          } else {
            flash.show(Text('Gagal hapus ${forwarder.name}'), .error);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [],
              ),
            ),
            SizedBox(
              height: bodyScreenHeight,
              child: CustomAsyncDataTable<Forwarder>(
                onLoaded: (stateManager) => _source = stateManager,
                additionalHeaderActions: (menuController) => [
                  MenuItemButton(
                    child: const Text('Tambah Forwarder'),
                    onPressed: () {
                      menuController.close();
                      openForm(Forwarder());
                    },
                  ),
                ],
                rowAction: (model) => Row(
                  children: [
                    IconButton(
                      onPressed: () => openForm(model),
                      icon: Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: () => deleteRecord(model),
                      icon: Icon(Icons.delete),
                    ),
                  ],
                ),
                fixedLeftColumns: 0,
                fetchData: fetchForwarders,
                showFilter: true,
                columns: setting.tableColumn('forwarder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
