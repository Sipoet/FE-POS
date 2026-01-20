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
  late final TrinaGridStateManager _source;
  late final Server server;

  List<SaleItem> items = [];
  final cancelToken = CancelToken();
  late Flash flash;
  late final Setting setting;
  List<FilterData> _filters = [];
  List<TableColumn> columns = [];
  QueryRequest? queryRequest;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    setting = context.read<Setting>();
    columns = setting.tableColumn('ipos::SaleItem');

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

  Future<DataTableResponse<SaleItem>> fetchSaleItems(QueryRequest request) {
    request.filters = _filters;
    queryRequest = request;
    return SaleItemClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<SaleItem>(
            models: value.models,
            totalPage: value.metadata['total_pages'],
          ),
          onError: (error) {
            defaultErrorResponse(error: error);
            return DataTableResponse.empty();
          },
        );
  }

  void viewRecord(SaleItem saleItem) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'Lihat Penjualan ${saleItem.saleCode}',
        SaleFormPage(sale: Sale(code: saleItem.saleCode ?? '')),
      );
    });
  }

  void download() {
    flash.show(const Text('Dalam proses.'), ToastificationType.info);
    queryRequest ??= QueryRequest(
      filters: _filters,
      include: ['item', 'sale'],
      sorts: [SortData(key: 'kodeitem', isAscending: true)],
    );
    queryRequest!.include = ['item', 'sale'];
    queryRequest!.sorts = [SortData(key: 'kodeitem', isAscending: true)];
    queryRequest!.filters = _filters;
    Map<String, dynamic> param = queryRequest!.toQueryParam();
    param['report_type'] = 'xlsx';
    for (final filterData in _filters) {
      final entry = filterData.toEntryJson();
      param[entry.key] = entry.value;
    }

    try {
      server
          .get(
            'ipos/sale_items',
            queryParam: param,
            cancelToken: cancelToken,
            type: 'xlsx',
          )
          .then(
            (response) {
              flash.hide();
              if (response.statusCode != 200) {
                flash.show(
                  const Text('gagal simpan ke excel'),
                  ToastificationType.error,
                );
                return;
              }
              String filename =
                  response.headers.value('content-disposition') ?? '';
              if (filename.isEmpty) {
                return;
              }
              filename = filename.substring(
                filename.indexOf('filename="') + 10,
                filename.indexOf('xlsx";') + 4,
              );
              var downloader = const FileSaver();
              downloader.download(
                filename,
                response.data,
                'xlsx',
                onSuccess: (String path) {
                  flash.showBanner(
                    messageType: ToastificationType.success,
                    title: 'Sukses download',
                    description: 'sukses disimpan di $path',
                  );
                },
              );
            },
            onError: (error, stackTrace) =>
                defaultErrorResponse(error: error, valueWhenError: []),
          );
    } catch (e, trace) {
      flash.showBanner(
        title: e.toString(),
        description: trace.toString(),
        messageType: ToastificationType.error,
      );
    }
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
              onDownload: (value) {
                _filters = value;
                download();
              },
            ),

            SizedBox(
              height: bodyScreenHeight,
              child: CustomAsyncDataTable<SaleItem>(
                key: const ObjectKey('saleItemTable'),
                renderAction: (saleItem) => Row(
                  spacing: 10,
                  children: [
                    IconButton.filled(
                      onPressed: () {
                        viewRecord(saleItem);
                      },
                      icon: const Icon(Icons.search_rounded),
                    ),
                  ],
                ),
                onLoaded: (stateManager) {
                  _source = stateManager;
                  _source.sortDescending(_source.columns[0]);
                },
                fetchData: fetchSaleItems,
                columns: columns,
                fixedLeftColumns: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
