import 'package:fe_pos/model/consignment_in_order.dart';
import 'package:fe_pos/page/consignment_in_order_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class ConsignmentInOrderPage extends StatefulWidget {
  const ConsignmentInOrderPage({super.key});

  @override
  State<ConsignmentInOrderPage> createState() => _ConsignmentInOrderPageState();
}

class _ConsignmentInOrderPageState extends State<ConsignmentInOrderPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final TableController _source;
  late final Server server;

  List<ConsignmentInOrder> items = [];
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

    columns = setting.tableColumn('ipos::ConsignmentInOrder');

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

  Future<DataTableResponse<ConsignmentInOrder>> fetchData(
    QueryRequest request,
  ) {
    request.filters = _filters;
    request.include = ['supplier', 'consignment_in'];
    return ConsignmentInOrderClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<ConsignmentInOrder>(
            models: value.models,
            totalPage: value.metadata['total_pages'],
          ),
          onError: (error) {
            defaultErrorResponse(error: error);
            return DataTableResponse<ConsignmentInOrder>.empty();
          },
        );
  }

  void viewRecord(ConsignmentInOrder consignmentInOrder) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'Lihat Pesanan Konsinyasi Masuk ${consignmentInOrder.code}',
        ConsignmentInOrderFormPage(consignmentInOrder: consignmentInOrder),
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
              child: CustomAsyncDataTable<ConsignmentInOrder>(
                renderAction: (consignmentInOrder) => Row(
                  spacing: 10,
                  children: [
                    IconButton.filled(
                      onPressed: () {
                        viewRecord(consignmentInOrder);
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
                fetchData: fetchData,
                fixedLeftColumns: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
