import 'package:fe_pos/model/consignment_in.dart';
import 'package:fe_pos/page/consignment_in_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class ConsignmentInPage extends StatefulWidget {
  const ConsignmentInPage({super.key});

  @override
  State<ConsignmentInPage> createState() => _ConsignmentInPageState();
}

class _ConsignmentInPageState extends State<ConsignmentInPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final PlutoGridStateManager _source;
  late final Server server;
  String _searchText = '';
  List<ConsignmentIn> items = [];
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
    columns = setting.tableColumn('ipos::ConsignmentIn');
    Future.delayed(Duration.zero, refreshTable);
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

  Future<DataTableResponse<ConsignmentIn>> fetchConsignmentIns(
      QueryRequest request) {
    request.filters = _filters;
    request.searchText = _searchText;
    return ConsignmentInClass().finds(server, request).then(
        (value) => DataTableResponse<ConsignmentIn>(
            models: value.models,
            totalPage: value.metadata['total_pages']), onError: (error) {
      defaultErrorResponse(error: error);
      return DataTableResponse.empty();
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

  void viewRecord(ConsignmentIn consignmentIn) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab('Lihat Konsinyasi Masuk ${consignmentIn.code}',
          ConsignmentInFormPage(consignmentIn: consignmentIn));
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
              height: bodyScreenHeight,
              child: CustomAsyncDataTable<ConsignmentIn>(
                renderAction: (consignmentIn) => Row(
                  spacing: 10,
                  children: [
                    IconButton.filled(
                        onPressed: () {
                          viewRecord(consignmentIn);
                        },
                        icon: const Icon(Icons.search_rounded)),
                  ],
                ),
                onLoaded: (stateManager) {
                  _source = stateManager;
                  _source.sortDescending(_source.columns[4]);
                },
                columns: columns,
                fetchData: fetchConsignmentIns,
                fixedLeftColumns: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
