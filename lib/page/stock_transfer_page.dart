import 'package:fe_pos/model/stock_transfer.dart';
import 'package:fe_pos/page/stock_transfer_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class StockTransferPage extends StatefulWidget {
  const StockTransferPage({super.key});

  @override
  State<StockTransferPage> createState() => _StockTransferPageState();
}

class _StockTransferPageState extends State<StockTransferPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final TableController<StockTransfer> _source;
  late final Server server;
  List<StockTransfer> items = [];
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
    columns = setting.tableColumn('stockTransfer');
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

  Future<DataTableResponse<StockTransfer>> fetchRecords(QueryRequest request) {
    request.filters = _filters;
    request.includeAddAll(['from_location', 'to_location']);
    return StockTransferClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<StockTransfer>(
            models: value.models,
            totalPage: value.metadata['total_pages'],
          ),
          onError: (error) {
            defaultErrorResponse(error: error);
            return DataTableResponse<StockTransfer>.empty();
          },
        );
  }

  void openForm(StockTransfer stockTransfer) {
    final text = stockTransfer.isNewRecord ? 'Tambah' : 'Lihat';
    setState(() {
      tabManager.addTab(
        '$text Invoice Pembelian ${stockTransfer.code}',
        StockTransferFormPage(stockTransfer: stockTransfer),
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
              child: CustomAsyncDataTable<StockTransfer>(
                additionalHeaderActions: (menuController) => [
                  MenuItemButton(
                    child: Text('Tambah Invoice Pembelian'),
                    onPressed: () {
                      menuController.close();
                      openForm(StockTransferClass().initModel());
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
                fetchData: fetchRecords,
                fixedLeftColumns: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
