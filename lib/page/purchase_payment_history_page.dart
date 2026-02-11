import 'package:fe_pos/model/purchase_payment_history.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PurchasePaymentHistoryPage extends StatefulWidget {
  const PurchasePaymentHistoryPage({super.key});

  @override
  State<PurchasePaymentHistoryPage> createState() =>
      _PurchasePaymentHistoryPageState();
}

class _PurchasePaymentHistoryPageState extends State<PurchasePaymentHistoryPage>
    with DefaultResponse {
  late final List<TableColumn> columns;
  late final Server _server;
  late final TableController _source;
  List<FilterData> _filters = [];

  @override
  void initState() {
    _server = context.read<Server>();
    final setting = context.read<Setting>();
    columns = setting.tableColumn('purchasePaymentHistory');
    super.initState();
  }

  Future<DataTableResponse<PurchasePaymentHistory>> fetchData(
    QueryRequest request,
  ) {
    request.filters = _filters;

    request.include = ['supplier', 'payment_account'];
    return PurchasePaymentHistoryClass()
        .finds(_server, request)
        .then(
          (value) => DataTableResponse<PurchasePaymentHistory>(
            models: value.models,
            totalPage: value.metadata['total_pages'],
          ),
          onError: (error) => defaultErrorResponse(
            error: error,
            valueWhenError: DataTableResponse<PurchasePaymentHistory>.empty(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return VerticalBodyScroll(
      child: Column(
        spacing: 10,
        children: [
          TableFilterForm(
            columns: columns,
            onSubmit: (value) {
              setState(() {
                _filters = value;
              });
              _source.refreshTable();
            },
          ),

          SizedBox(
            height: bodyScreenHeight,
            child: CustomAsyncDataTable<PurchasePaymentHistory>(
              onLoaded: (stateManager) {
                _source = stateManager;
                _source.sortDescending(_source.columns[2]);
              },
              fetchData: fetchData,
              showSummary: _filters.isNotEmpty,
              fixedLeftColumns: 1,
              columns: columns,
            ),
          ),
        ],
      ),
    );
  }
}
