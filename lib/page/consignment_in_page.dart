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
  late final CustomAsyncDataTableSource<ConsignmentIn> _source;
  late final Server server;
  String _searchText = '';
  List<ConsignmentIn> items = [];
  final cancelToken = CancelToken();
  late Flash flash;
  late final Setting setting;
  Map _filter = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    setting = context.read<Setting>();
    _source = CustomAsyncDataTableSource<ConsignmentIn>(
        columns: setting.tableColumn('ipos::ConsignmentIn'),
        fetchData: fetchConsignmentIns);
    _source.sortColumn = _source.columns[4];
    _source.isAscending = false;
    Future.delayed(Duration.zero, refreshTable);
    super.initState();
  }

  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  Future<void> refreshTable() async {
    _source.refreshDataFromFirstPage();
  }

  Future<ResponseResult<ConsignmentIn>> fetchConsignmentIns(
      {int page = 1,
      int limit = 50,
      TableColumn? sortColumn,
      bool isAscending = false}) {
    String orderKey = sortColumn?.name ?? 'tanggal';
    Map<String, dynamic> param = {
      'search_text': _searchText,
      'page[page]': page.toString(),
      'page[limit]': limit.toString(),
      'sort': '${isAscending ? '' : '-'}$orderKey',
      'include': 'consignment_in_order,supplier',
    };
    _filter.forEach((key, value) {
      param[key] = value;
    });
    try {
      return server
          .get('consignment_ins', queryParam: param, cancelToken: cancelToken)
          .then((response) {
        if (response.statusCode != 200) {
          throw 'error: ${response.data.toString()}';
        }
        Map responseBody = response.data;
        if (responseBody['data'] is! List) {
          throw 'error: invalid data type ${response.data.toString()}';
        }
        final models = responseBody['data']
            .map<ConsignmentIn>((json) => ConsignmentIn.fromJson(json,
                included: responseBody['included'] ?? []))
            .toList();
        final totalRows =
            responseBody['meta']?['total_rows'] ?? responseBody['data'].length;
        return ResponseResult<ConsignmentIn>(
            totalRows: totalRows, models: models);
      },
              onError: (error, stackTrace) =>
                  defaultErrorResponse(error: error, valueWhenError: []));
    } catch (e, trace) {
      flash.showBanner(
          title: e.toString(),
          description: trace.toString(),
          messageType: ToastificationType.error);
      throw 'error';
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
    _source.actionButtons = (consignmentIn, index) => [
          IconButton.filled(
              onPressed: () {
                viewRecord(consignmentIn);
              },
              icon: const Icon(Icons.search_rounded)),
        ];
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            TableFilterForm(
              columns: _source.columns,
              onSubmit: (value) {
                _filter = value;
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
