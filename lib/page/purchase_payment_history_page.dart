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
  late final TrinaGridStateManager _source;
  List<FilterData> _filters = [];
  String _searchText = '';
  @override
  void initState() {
    _server = context.read<Server>();
    final setting = context.read<Setting>();
    columns = setting.tableColumn('purchasePaymentHistory');
    super.initState();
  }

  Future<DataTableResponse<PurchasePaymentHistory>> fetchData(
      QueryRequest request) {
    request.filters = _filters;
    request.searchText = _searchText;
    request.include = ['supplier', 'payment_account'];
    return PurchasePaymentHistoryClass().finds(_server, request).then(
        (value) => DataTableResponse<PurchasePaymentHistory>(
            models: value.models, totalPage: value.metadata['total_pages']),
        onError: (error) => defaultErrorResponse(
            error: error,
            valueWhenError: DataTableResponse<PurchasePaymentHistory>.empty()));
  }

  void searchChanged(value) {
    String container = _searchText;
    setState(() {
      if (value.length >= 3) {
        _searchText = value;
      } else {
        _searchText = '';
      }
    });
    if (container != _searchText) {
      _source.refreshTable();
    }
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _searchText = '';
                  });
                  _source.refreshTable();
                },
                tooltip: 'Reset Table',
                icon: const Icon(Icons.refresh),
              ),
              SizedBox(
                width: 250,
                child: TextField(
                  decoration: const InputDecoration(hintText: 'Search Text'),
                  onChanged: searchChanged,
                  onSubmitted: searchChanged,
                ),
              ),
            ],
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
          )
        ],
      ),
    );
  }
}
