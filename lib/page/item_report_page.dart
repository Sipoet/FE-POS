import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/model/item_report.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/tool/file_saver.dart';
import 'package:async/async.dart';

class ItemReportPage extends StatefulWidget {
  const ItemReportPage({super.key});

  @override
  State<ItemReportPage> createState() => _ItemReportPageState();
}

class _ItemReportPageState extends State<ItemReportPage>
    with AutomaticKeepAliveClientMixin, LoadingPopup, DefaultResponse {
  late Server server;
  String _searchText = '';
  double minimumColumnWidth = 150;
  late final PlutoGridStateManager _source;
  late final Setting _setting;
  late Flash flash;
  Map _filter = {};
  @override
  void initState() {
    server = context.read<Server>();
    _setting = context.read<Setting>();
    flash = Flash();
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  Future<DataTableResponse<ItemReport>> _displayReport(
      {DataTableRequest? request, CancelToken? cancelToken}) async {
    if (request == null) {
      _source.setPage(1);
      _source.refreshTable();
      return DataTableResponse<ItemReport>(models: []);
    }

    _source.setShowLoading(true);
    return _requestReport(
      page: request.page,
      limit: 15,
      cancelToken: request.cancelToken,
      sorts: request.sorts,
    ).then((response) {
      if (response.statusCode != 200) {
        return DataTableResponse<ItemReport>(models: []);
      }
      var data = response.data;
      final models = data['data']
          .map<ItemReport>((row) => ItemReportClass().fromJson(row))
          .toList();

      return DataTableResponse<ItemReport>(
          models: models, totalPage: response.data['meta']['total_pages']);
    }, onError: ((error, stackTrace) {
      defaultErrorResponse(error: error);
      return DataTableResponse<ItemReport>(models: []);
    })).whenComplete(() {
      _source.setShowLoading(false);
    });
  }

  void _downloadReport() async {
    flash.show(
      const Text('Dalam proses.'),
      ToastificationType.info,
    );
    _requestReport(reportType: 'xlsx').then(_downloadResponse,
        onError: ((error, stackTrace) => defaultErrorResponse(error: error)));
  }

  Future _requestReport({
    int page = 1,
    String reportType = 'json',
    int limit = 10,
    CancelToken? cancelToken,
    List<SortData> sorts = const [],
  }) async {
    final sort = sorts.isEmpty
        ? SortData(key: 'item_code', isAscending: true)
        : sorts.first;
    Map<String, dynamic> param = {
      'page[page]': page.toString(),
      'page[limit]': limit.toString(),
      'report_type': reportType,
      'search_text': _searchText,
      'include': 'item,supplier,brand,item_type',
      'sort': sort.isAscending ? sort.key : "-${sort.key}",
    };
    _filter.forEach((key, value) {
      param[key] = value;
    });
    return server.get('item_reports',
        queryParam: param, type: reportType, cancelToken: cancelToken);
  }

  void _downloadResponse(response) async {
    flash.hide();
    if (response.statusCode != 200) {
      flash.show(const Text('gagal simpan ke excel'), ToastificationType.error);
      return;
    }
    String filename = response.headers.value('content-disposition') ?? '';
    if (filename.isEmpty) {
      return;
    }
    filename = filename.substring(
        filename.indexOf('filename="') + 10, filename.indexOf('xlsx";') + 4);
    var downloader = const FileSaver();
    downloader.download(filename, response.data, 'xlsx',
        onSuccess: (String path) {
      flash.showBanner(
          messageType: ToastificationType.success,
          title: 'Sukses download',
          description: 'sukses disimpan di $path');
    });
  }

  CancelableOperation? searchFuture;
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
      if (searchFuture != null) {
        searchFuture!.cancel();
      }
      searchFuture = CancelableOperation.fromFuture(
        Future.delayed(const Duration(milliseconds: 700), _displayReport),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final columns = _setting.tableColumn('itemReport');
    return VerticalBodyScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TableFilterForm(
              showCanopy: false,
              onSubmit: (filter) {
                _filter = filter;
                _displayReport();
              },
              onDownload: (filter) {
                _filter = filter;
                _downloadReport();
              },
              columns: columns),
          const SizedBox(height: 10),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _searchText = '';
                });
                _displayReport();
              },
              tooltip: 'Reset Table',
              icon: const Icon(Icons.refresh),
            ),
            SizedBox(
              width: 150,
              child: TextField(
                decoration: const InputDecoration(hintText: 'Search Text'),
                onChanged: searchChanged,
                onSubmitted: searchChanged,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            height: bodyScreenHeight,
            child: CustomAsyncDataTable2<ItemReport>(
              columns: columns,
              showFilter: false,
              fetchData: (DataTableRequest request) =>
                  _displayReport(request: request),
              onLoaded: (stateManager) => _source = stateManager,
              fixedLeftColumns: 1,
            ),
          ),
        ],
      ),
    );
  }
}
