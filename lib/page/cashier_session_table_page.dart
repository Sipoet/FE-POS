import 'package:fe_pos/page/edc_settlement_form_page.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/model/cashier_session.dart';

class CashierSessionTablePage extends StatefulWidget {
  const CashierSessionTablePage({super.key});

  @override
  State<CashierSessionTablePage> createState() =>
      _CashierSessionTablePageState();
}

class _CashierSessionTablePageState extends State<CashierSessionTablePage>
    with AutomaticKeepAliveClientMixin, DefaultResponse, TextFormatter {
  late final PlutoGridStateManager _source;
  late final Server server;
  String _searchText = '';
  final cancelToken = CancelToken();
  late Flash flash;
  late final TabManager tabManager;
  List<FilterData> _filters = [];
  List<TableColumn> columns = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    final setting = context.read<Setting>();
    columns = setting.tableColumn('cashierSession');
    tabManager = context.read<TabManager>();
    super.initState();
  }

  @override
  void dispose() {
    cancelToken.cancel();
    _source.dispose();
    super.dispose();
  }

  Future<void> refreshTable() async {
    _source.refreshTable();
  }

  Future<DataTableResponse<CashierSession>> fetchData(QueryRequest request) {
    request.filters = _filters;
    request.searchText = _searchText;
    return CashierSessionClass().finds(server, request).then(
        (value) => DataTableResponse<CashierSession>(
            models: value.models,
            totalPage: value.metadata['total_pages']), onError: (error) {
      defaultErrorResponse(error: error);
      return DataTableResponse<CashierSession>.empty();
    });
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
      refreshTable();
    }
  }

  void openEdcSettlement(cashierSession) {
    tabManager.addTab(
        "EDC Settlement ${dateFormat(cashierSession.date)}",
        EdcSettlementFormPage(
          key: ObjectKey(cashierSession),
          cashierSession: cashierSession,
        ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          children: [
            TableFilterForm(
              columns: columns,
              onSubmit: (filter) {
                _filters = filter;
                refreshTable();
              },
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _searchText = '';
                      });
                      refreshTable();
                    },
                    tooltip: 'Reset Table',
                    icon: const Icon(Icons.refresh),
                  ),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      decoration:
                          const InputDecoration(hintText: 'Search Text'),
                      onChanged: searchChanged,
                      onSubmitted: searchChanged,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: bodyScreenHeight - 150,
              child: CustomAsyncDataTable<CashierSession>(
                columns: columns,
                onLoaded: (stateManager) => _source = stateManager,
                renderAction: (cashierSession) => Row(spacing: 10, children: [
                  IconButton.filled(
                      onPressed: () {
                        openEdcSettlement(cashierSession);
                      },
                      icon: const Icon(Icons.search)),
                ]),
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
