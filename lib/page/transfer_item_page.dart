import 'package:fe_pos/model/transfer.dart';
import 'package:fe_pos/page/transfer_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class TransferItemPage extends StatefulWidget {
  const TransferItemPage({super.key});

  @override
  State<TransferItemPage> createState() => _TransferItemPageState();
}

class _TransferItemPageState extends State<TransferItemPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final TrinaGridStateManager _source;
  late final Server server;

  List<TransferItem> items = [];
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

    columns = setting.tableColumn('ipos::TransferItem');

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

  Future<DataTableResponse<TransferItem>> fetchTransferItems(
    QueryRequest request,
  ) {
    request.filters = _filters;

    return TransferItemClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<TransferItem>(
            models: value.models,
            totalPage: value.metadata['total_pages'],
          ),
          onError: (error) {
            defaultErrorResponse(error: error);
            return DataTableResponse.empty();
          },
        );
  }

  void viewRecord(TransferItem transferItem) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'Lihat Pembelian ${transferItem.transferCode}',
        TransferFormPage(
          transfer: Transfer(code: transferItem.transferCode ?? ''),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return VerticalBodyScroll(
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
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [

              ],
            ),
          ),
          SizedBox(
            height: bodyScreenHeight,
            child: CustomAsyncDataTable<TransferItem>(
              renderAction: (transferItem) => Row(
                spacing: 10,
                children: [
                  IconButton.filled(
                    onPressed: () {
                      viewRecord(transferItem);
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
              fetchData: fetchTransferItems,
              fixedLeftColumns: 1,
            ),
          ),
        ],
      ),
    );
  }
}
