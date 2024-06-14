import 'package:fe_pos/model/purchase.dart';
import 'package:fe_pos/page/purchase_form_page.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_data_table.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class PurchaseItemPage extends StatefulWidget {
  const PurchaseItemPage({super.key});

  @override
  State<PurchaseItemPage> createState() => _PurchaseItemPageState();
}

class _PurchaseItemPageState extends State<PurchaseItemPage>
    with AutomaticKeepAliveClientMixin {
  late final CustomAsyncDataTableSource<PurchaseItem> _source;
  late final Server server;
  String _searchText = '';
  List<PurchaseItem> items = [];
  final cancelToken = CancelToken();
  late Flash flash;
  late final Setting setting;
  Map _filter = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash(context);
    setting = context.read<Setting>();
    _source = CustomAsyncDataTableSource<PurchaseItem>(
        columns: setting.tableColumn('ipos::PurchaseItem'),
        fetchData: fetchPurchaseItems);
    _source.sortColumn = _source.columns[0];
    _source.isAscending = false;
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

  Future<ResponseResult<PurchaseItem>> fetchPurchaseItems(
      {int page = 1,
      int limit = 50,
      TableColumn? sortColumn,
      bool isAscending = false}) {
    String orderKey = sortColumn?.sortKey ?? 'kodeitem';
    Map<String, dynamic> param = {
      'search_text': _searchText,
      'page[page]': page.toString(),
      'page[limit]': limit.toString(),
      'include': 'item',
      'sort': '${isAscending ? '' : '-'}$orderKey',
    };
    _filter.forEach((key, value) {
      param[key] = value;
    });
    try {
      return server
          .get('purchase_items', queryParam: param, cancelToken: cancelToken)
          .then((response) {
        if (response.statusCode != 200) {
          throw 'error: ${response.data.toString()}';
        }
        Map responseBody = response.data;
        if (responseBody['data'] is! List) {
          throw 'error: invalid data type ${response.data.toString()}';
        }
        final models = responseBody['data']
            .map<PurchaseItem>((json) => PurchaseItem.fromJson(json,
                included: responseBody['included'] ?? []))
            .toList();
        final totalPages = responseBody['meta']?['total_pages'];
        return ResponseResult<PurchaseItem>(
            totalPages: totalPages,
            totalRows: responseBody['meta']?['total_rows'],
            models: models);
      },
              onError: (error, stackTrace) => server.defaultErrorResponse(
                  context: context, error: error, valueWhenError: []));
    } catch (e, trace) {
      flash.showBanner(
          title: e.toString(),
          description: trace.toString(),
          messageType: MessageType.failed);
      throw 'error';
    }
  }

  void showConfirmDialog(
      {required Function onSubmit, String message = 'Apakah Anda Yakin?'}) {
    AlertDialog alert = AlertDialog(
      title: const Text("Konfirmasi"),
      content: Text(message),
      actions: [
        ElevatedButton(
          child: const Text("Kembali"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: const Text("Submit"),
          onPressed: () {
            onSubmit();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
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

  void viewRecord(PurchaseItem purchaseItem) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
          'Lihat Pembelian ${purchaseItem.purchaseCode}',
          PurchaseFormPage(
              purchase: Purchase(code: purchaseItem.purchaseCode ?? '')));
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _source.actionButtons = (purchaseItem, index) => [
          IconButton.filled(
              onPressed: () {
                viewRecord(purchaseItem);
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
