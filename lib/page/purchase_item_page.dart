import 'package:fe_pos/model/purchase.dart';
import 'package:fe_pos/page/purchase_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class PurchaseItemPage extends StatefulWidget {
  const PurchaseItemPage({super.key});

  @override
  State<PurchaseItemPage> createState() => _PurchaseItemPageState();
}

class _PurchaseItemPageState extends State<PurchaseItemPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final TableController _source;
  late final Server server;

  List<PurchaseItem> items = [];
  final cancelToken = CancelToken();
  late Flash flash;
  late final Setting setting;
  List<FilterData> _filters = [];
  List<TableColumn> columns = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    setting = context.read<Setting>();
    columns = setting.tableColumn('ipos::PurchaseItem');
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

  Future<DataTableResponse<PurchaseItem>> fetchPurchaseItems(
    QueryRequest request,
  ) {
    request.filters = _filters;

    return PurchaseItemClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<PurchaseItem>(
            models: value.models,
            totalPage: value.metadata['total_pages'],
          ),
          onError: (error) {
            defaultErrorResponse(error: error);
            return DataTableResponse.empty();
          },
        );
  }

  void viewRecord(PurchaseItem purchaseItem) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'Lihat Pembelian ${purchaseItem.purchaseCode}',
        PurchaseFormPage(
          purchase: Purchase(code: purchaseItem.purchaseCode ?? ''),
        ),
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
              child: CustomAsyncDataTable<PurchaseItem>(
                renderAction: (purchaseItem) => Row(
                  spacing: 10,
                  children: [
                    IconButton.filled(
                      onPressed: () {
                        viewRecord(purchaseItem);
                      },
                      icon: const Icon(Icons.search_rounded),
                    ),
                  ],
                ),
                onLoaded: (stateManager) {
                  _source = stateManager;
                  _source.sortDescending(_source.columns[0]);
                },
                columns: columns,
                fetchData: fetchPurchaseItems,
                fixedLeftColumns: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
