import 'package:fe_pos/model/sales_cashier.dart';
import 'package:fe_pos/page/sales_cashier_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class SalesCashierPage extends StatefulWidget {
  const SalesCashierPage({super.key});

  @override
  State<SalesCashierPage> createState() => _SalesCashierPageState();
}

class _SalesCashierPageState extends State<SalesCashierPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final CustomAsyncDataTableSource<SalesCashier> _source;
  late final Server server;
  String _searchText = '';
  List<SalesCashier> items = [];
  final _menuController = MenuController();
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
    _source = CustomAsyncDataTableSource<SalesCashier>(
        columns: setting.tableColumn('salesCashier'),
        fetchData: fetchSalesCashiers);
    if (_source.columns.isNotEmpty) {
      _source.sortColumn = _source.columns?[1];
    }
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

  Future<ResponseResult<SalesCashier>> fetchSalesCashiers(
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
    };
    _filter.forEach((key, value) {
      param[key] = value;
    });
    try {
      return server
          .get('sales', queryParam: param, cancelToken: cancelToken)
          .then((response) {
        if (response.statusCode != 200) {
          throw 'error: ${response.data.toString()}';
        }
        Map responseBody = response.data;
        if (responseBody['data'] is! List) {
          throw 'error: invalid data type ${response.data.toString()}';
        }
        final models = responseBody['data']
            .map<SalesCashier>((json) => SalesCashier.fromJson(json,
                included: responseBody['included'] ?? []))
            .toList();
        final totalRows =
            responseBody['meta']?['total_rows'] ?? responseBody['data'].length;
        return ResponseResult<SalesCashier>(
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

  void viewRecord(SalesCashier salesCashier) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab('Lihat Penjualan ${salesCashier.code}',
          SalesCashierFormPage(salesCashier: salesCashier));
    });
  }

  void addForm() {
    String defaultLocation = 'TOKO';
    final salesCashier = SalesCashier(location: defaultLocation);
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab('Tambah Penjualan Kasir',
          SalesCashierFormPage(salesCashier: salesCashier));
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _source.actionButtons = (sale, index) => [
          IconButton.filled(
              onPressed: () {
                viewRecord(sale);
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
                  SizedBox(
                    width: 50,
                    child: SubmenuButton(
                        controller: _menuController,
                        menuChildren: [
                          MenuItemButton(
                            child: const Text('Tambah Penjualan di kasir'),
                            onPressed: () {
                              _menuController.close();
                              addForm();
                            },
                          ),
                        ],
                        child: const Icon(Icons.table_rows_rounded)),
                  )
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
