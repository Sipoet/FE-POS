import 'package:fe_pos/model/purchase_shipment.dart';
import 'package:fe_pos/page/purchase_shipment_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class PurchaseShipmentPage extends StatefulWidget {
  const PurchaseShipmentPage({super.key});

  @override
  State<PurchaseShipmentPage> createState() => _PurchaseShipmentPageState();
}

class _PurchaseShipmentPageState extends State<PurchaseShipmentPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final TableController<PurchaseShipment> _source;
  late final Server server;
  List<PurchaseShipment> items = [];
  final cancelToken = CancelToken();
  late Flash flash;
  late final Setting setting;
  late final TabManager tabManager;
  List<FilterData> _filters = [];
  List<TableColumn> columns = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    setting = context.read<Setting>();
    tabManager = context.read<TabManager>();
    columns = setting.tableColumn('purchaseShipment');
    super.initState();
  }

  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  Future<void> refreshTable() async {
    _source.refreshTable();
  }

  Future<DataTableResponse<PurchaseShipment>> fetchPurchases(
    QueryRequest request,
  ) {
    request.filters = _filters;
    request.includeAddAll(['sender', 'location']);
    return PurchaseShipmentClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<PurchaseShipment>(
            models: value.models,
            totalPage: value.metadata['total_pages'],
          ),
          onError: (error) {
            defaultErrorResponse(error: error);
            return DataTableResponse<PurchaseShipment>.empty();
          },
        );
  }

  void openForm(PurchaseShipment purchaseShipment) {
    final text = purchaseShipment.isNewRecord ? 'Tambah' : 'Lihat';
    setState(() {
      tabManager.addTab(
        '$text Pengiriman Pembelian ${purchaseShipment.code ?? ''}',
        PurchaseShipmentFormPage(purchaseShipment: purchaseShipment),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            TableFilterForm(
              columns: columns,
              onSubmit: (value) {
                _filters = value;
                refreshTable();
              },
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [],
              ),
            ),
            SizedBox(
              height: bodyScreenHeight,
              child: CustomAsyncDataTable<PurchaseShipment>(
                additionalHeaderActions: (menuController) => [
                  MenuItemButton(
                    child: Text('Tambah Pengiriman Pembelian'),
                    onPressed: () {
                      menuController.close();
                      openForm(PurchaseShipmentClass().initModel());
                    },
                  ),
                ],
                rowAction: (purchase) => Row(
                  spacing: 10,
                  children: [
                    IconButton.filled(
                      onPressed: () {
                        openForm(purchase);
                      },
                      icon: const Icon(Icons.search_rounded),
                    ),
                  ],
                ),
                onLoaded: (stateManager) {
                  _source = stateManager;
                  _source.sortDescending(_source.columns[1]);
                },
                columns: columns,
                fetchData: fetchPurchases,
                fixedLeftColumns: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
