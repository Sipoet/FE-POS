import 'package:fe_pos/model/sale.dart';
import 'package:fe_pos/page/sale_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/file_saver.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class SaleItemPage extends StatefulWidget {
  const SaleItemPage({super.key});

  @override
  State<SaleItemPage> createState() => _SaleItemPageState();
}

class _SaleItemPageState extends State<SaleItemPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final CustomAsyncDataTableSource<SaleItem> _source;
  late final Server server;
  String _searchText = '';
  List<SaleItem> items = [];
  final cancelToken = CancelToken();
  late Flash flash;
  late final Setting setting;
  List<FilterData> _filter = [];
  final _menuController = MenuController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    setting = context.read<Setting>();
    _source = CustomAsyncDataTableSource<SaleItem>(
        columns: setting.tableColumn('ipos::SaleItem'),
        fetchData: fetchSaleItems);
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

  Future<ResponseResult<SaleItem>> fetchSaleItems(
      {int page = 1,
      int limit = 50,
      TableColumn? sortColumn,
      bool isAscending = false}) {
    String orderKey = sortColumn?.name ?? 'kodeitem';
    Map<String, dynamic> param = {
      'search_text': _searchText,
      'page[page]': page.toString(),
      'page[limit]': limit.toString(),
      'include': 'item,sale',
      'sort': '${isAscending ? '' : '-'}$orderKey',
    };
    for (final filterData in _filter) {
      final data = filterData.toEntryJson();
      param[data.key] = data.value;
    }
    try {
      return server
          .get('sale_items', queryParam: param, cancelToken: cancelToken)
          .then((response) {
        if (response.statusCode != 200) {
          throw 'error: ${response.data.toString()}';
        }
        Map responseBody = response.data;
        if (responseBody['data'] is! List) {
          throw 'error: invalid data type ${response.data.toString()}';
        }
        final models = responseBody['data']
            .map<SaleItem>((json) => SaleItemClass()
                .fromJson(json, included: responseBody['included'] ?? []))
            .toList();
        final totalRows =
            responseBody['meta']?['total_rows'] ?? responseBody['data'].length;
        return ResponseResult<SaleItem>(totalRows: totalRows, models: models);
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

  void viewRecord(SaleItem saleItem) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab('Lihat Penjualan ${saleItem.saleCode}',
          SaleFormPage(sale: Sale(code: saleItem.saleCode ?? '')));
    });
  }

  void download() {
    flash.show(
      const Text('Dalam proses.'),
      ToastificationType.info,
    );
    Map<String, dynamic> param = {
      'search_text': _searchText,
      'include': 'item,sale',
      'sort': 'kodeitem',
      'report_type': 'xlsx',
    };
    for (final filterData in _filter) {
      final data = filterData.toEntryJson();
      param[data.key] = data.value;
    }
    try {
      server
          .get('sale_items',
              queryParam: param, cancelToken: cancelToken, type: 'xlsx')
          .then((response) {
        flash.hide();
        if (response.statusCode != 200) {
          flash.show(
              const Text('gagal simpan ke excel'), ToastificationType.error);
          return;
        }
        String filename = response.headers.value('content-disposition') ?? '';
        if (filename.isEmpty) {
          return;
        }
        filename = filename.substring(filename.indexOf('filename="') + 10,
            filename.indexOf('xlsx";') + 4);
        var downloader = const FileSaver();
        downloader.download(filename, response.data, 'xlsx',
            onSuccess: (String path) {
          flash.showBanner(
              messageType: ToastificationType.success,
              title: 'Sukses download',
              description: 'sukses disimpan di $path');
        });
      },
              onError: (error, stackTrace) =>
                  defaultErrorResponse(error: error, valueWhenError: []));
    } catch (e, trace) {
      flash.showBanner(
          title: e.toString(),
          description: trace.toString(),
          messageType: ToastificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _source.actionButtons = (saleItem, index) => [
          IconButton.filled(
              onPressed: () {
                viewRecord(saleItem);
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
                            leadingIcon: const Icon(Icons.download),
                            child: const Text('Download Excel'),
                            onPressed: () {
                              _menuController.close();
                              download();
                            },
                          ),
                        ],
                        child: const Icon(Icons.table_rows_rounded)),
                  )
                ],
              ),
            ),
            SizedBox(
              height: bodyScreenHeight,
              child: CustomAsyncDataTable(
                key: const ObjectKey('saleItemTable'),
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
