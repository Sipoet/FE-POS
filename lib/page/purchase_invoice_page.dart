import 'package:fe_pos/model/purchase_invoice.dart';
import 'package:fe_pos/page/purchase_invoice_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class PurchaseInvoicePage extends StatefulWidget {
  const PurchaseInvoicePage({super.key});

  @override
  State<PurchaseInvoicePage> createState() => _PurchaseInvoicePageState();
}

class _PurchaseInvoicePageState extends State<PurchaseInvoicePage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final TableController<PurchaseInvoice> _source;
  late final Server server;
  List<PurchaseInvoice> items = [];
  final cancelToken = CancelToken();
  late Flash flash;
  late final Authorizer setting;
  late final TabManager tabManager;
  List<FilterData> _filters = [];
  List<TableColumn> columns = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    setting = context.read<Authorizer>();
    tabManager = context.read<TabManager>();
    columns = setting.tableColumn('purchaseInvoice');
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

  Future<DataTableResponse<PurchaseInvoice>> fetchPurchases(
    QueryRequest request,
  ) {
    request.filters = _filters;
    request.includeAddAll(['purchase_order', 'supplier', 'location']);
    return PurchaseInvoiceClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<PurchaseInvoice>(
            models: value.models,
            totalPage: value.metadata['total_pages'],
          ),
          onError: (error) {
            defaultErrorResponse(error: error);
            return DataTableResponse<PurchaseInvoice>.empty();
          },
        );
  }

  void openForm(PurchaseInvoice purchaseInvoice) {
    final text = purchaseInvoice.isNewRecord ? 'Tambah' : 'Lihat';
    setState(() {
      tabManager.addTab(
        '$text Invoice Pembelian ${purchaseInvoice.code}',
        PurchaseInvoiceFormPage(purchaseInvoice: purchaseInvoice),
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
              child: CustomAsyncDataTable<PurchaseInvoice>(
                enums: {
                  'tax_type': TaxType.values,
                  'status': PurchaseInvoiceStatus.values,
                },
                additionalHeaderActions: (menuController) => [
                  MenuItemButton(
                    child: Text('Tambah Invoice Pembelian'),
                    onPressed: () {
                      menuController.close();
                      openForm(PurchaseInvoiceClass().initModel());
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
