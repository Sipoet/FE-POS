import 'package:fe_pos/model/cash_transaction_report.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CashTransactionReportPage extends StatefulWidget {
  const CashTransactionReportPage({super.key});

  @override
  State<CashTransactionReportPage> createState() =>
      _CashTransactionReportPageState();
}

class _CashTransactionReportPageState extends State<CashTransactionReportPage>
    with DefaultResponse {
  late final List<TableColumn> columns;
  late final Server _server;
  late final TrinaGridStateManager _source;
  List<FilterData> _filters = [];

  @override
  void initState() {
    _server = context.read<Server>();
    final setting = context.read<Setting>();
    columns = setting.tableColumn('cashTransactionReport');
    super.initState();
  }

  Future<DataTableResponse<CashTransactionReport>> fetchData(
    QueryRequest request,
  ) {
    request.filters = _filters;

    request.include = ['detail_account', 'payment_account'];
    return CashTransactionReportClass()
        .finds(_server, request)
        .then(
          (value) => DataTableResponse<CashTransactionReport>(
            models: value.models,
            totalPage: value.metadata['total_pages'],
          ),
          onError: (error) => defaultErrorResponse(
            error: error,
            valueWhenError: DataTableResponse<CashTransactionReport>.empty(),
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
            enums: {'transaction_type': CashTransactionType.values},
            onSubmit: (value) {
              setState(() {
                _filters = value;
              });
              _source.refreshTable();
            },
          ),

          SizedBox(
            height: bodyScreenHeight,
            child: CustomAsyncDataTable<CashTransactionReport>(
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
