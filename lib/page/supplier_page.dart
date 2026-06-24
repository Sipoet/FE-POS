import 'package:fe_pos/model/supplier.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/page/supplier_form_page.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});

  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> with DefaultResponse {
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

  Future<DataTableResponse<Supplier>> fetchSuppliers(QueryRequest request) {
    return SupplierClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<Supplier>(
            models: value.models,
            totalPage: value.metadata['total_pages'],
          ),
          onError: (error) {
            defaultErrorResponse(error: error);
            return DataTableResponse.empty();
          },
        );
  }

  void openForm(Supplier supplier) {
    final tabManager = context.read<TabManager>();

    final desc = supplier.isNewRecord ? 'Tambah' : 'Edit';
    tabManager.addTab(
      '$desc Supplier ${supplier.name}',
      SupplierFormPage(supplier: supplier),
    );
  }

  void deleteRecord(Supplier supplier) {
    showConfirmDialog(
      message: 'Apakah Yakin Hapus Supplier ${supplier.name}',
      onSubmit: () {
        supplier.destroy(server).then((result) {
          if (result) {
            flash.show(Text('Sukses hapus ${supplier.name}'), .success);
            refreshTable();
          } else {
            flash.show(Text('Gagal hapus ${supplier.name}'), .error);
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
              child: CustomAsyncDataTable<Supplier>(
                onLoaded: (stateManager) => _source = stateManager,
                additionalHeaderActions: (menuController) => [
                  MenuItemButton(
                    child: const Text('Tambah Supplier'),
                    onPressed: () {
                      menuController.close();
                      openForm(Supplier());
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
                fetchData: fetchSuppliers,
                showFilter: true,
                columns: setting.tableColumn('supplier'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
