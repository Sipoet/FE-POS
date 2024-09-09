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
  late final CustomAsyncDataTableSource<CashierSession> _source;
  late final Server server;
  String _searchText = '';
  final cancelToken = CancelToken();
  late Flash flash;
  late final TabManager tabManager;
  Map _filter = {};

  @override
  bool get wantKeepAlive => true;

  List<Widget> actionButtons(CashierSession cashierSession, int index) {
    return [
      IconButton.filled(
          onPressed: () {
            openEdcSettlement(cashierSession);
          },
          icon: const Icon(Icons.search))
    ];
  }

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash(context);
    final setting = context.read<Setting>();
    final tableColumns = setting.tableColumn('cashierSession');
    tabManager = context.read<TabManager>();
    _source = CustomAsyncDataTableSource<CashierSession>(
        actionButtons: actionButtons,
        columns: tableColumns,
        fetchData: fetchCashierSessions);
    _source.isAscending = false;
    _source.sortColumn = tableColumns.firstWhere(
        (tableColumn) => tableColumn.key == 'date',
        orElse: () => tableColumns.first);
    super.initState();
    Future.delayed(Duration.zero, refreshTable);
  }

  @override
  void dispose() {
    cancelToken.cancel();
    _source.dispose();
    super.dispose();
  }

  Future<void> refreshTable() async {
    _source.refreshDataFromFirstPage();
  }

  Future<ResponseResult<CashierSession>> fetchCashierSessions(
      {int page = 1,
      int limit = 50,
      TableColumn? sortColumn,
      bool isAscending = true}) {
    try {
      String orderKey = sortColumn?.sortKey ?? 'date';
      Map<String, dynamic> param = {
        'search_text': _searchText,
        'page[page]': page.toString(),
        'page[limit]': limit.toString(),
        'sort': '${isAscending ? '' : '-'}$orderKey',
      };
      _filter.forEach((key, value) {
        param[key] = value;
      });

      return server
          .get('cashier_sessions', queryParam: param, cancelToken: cancelToken)
          .then((response) {
        if (response.statusCode != 200) {
          throw 'error: ${response.data.toString()}';
        }
        Map responseBody = response.data;
        if (responseBody['data'] is! List) {
          throw 'error: invalid data type ${response.data.toString()}';
        }
        try {
          final responsedModels = responseBody['data']
              .map<CashierSession>((json) => CashierSession.fromJson(json,
                  included: responseBody['included'] ?? []))
              .toList();
          int totalRows = responseBody['meta']?['total_rows'] ??
              responseBody['data'].length;
          return ResponseResult<CashierSession>(
              totalRows: totalRows, models: responsedModels);
        } catch (error, stackTrace) {
          debugPrint(error.toString());
          debugPrint(stackTrace.toString());
          return ResponseResult<CashierSession>(totalRows: 0, models: []);
        }
      },
              onError: (error, stackTrace) => server.defaultErrorResponse(
                  context: context, error: error, valueWhenError: []));
    } catch (e, trace) {
      flash.showBanner(
          title: e.toString(),
          description: trace.toString(),
          messageType: MessageType.failed);
      return Future(() => ResponseResult<CashierSession>(models: []));
    }
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
              columns: _source.columns,
              onSubmit: (filter) {
                _filter = filter;
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
              height: 600,
              child: CustomAsyncDataTable(
                controller: _source,
                fixedLeftColumns: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
