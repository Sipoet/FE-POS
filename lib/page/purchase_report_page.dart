import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/model/purchase_report.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/tool/file_saver.dart';

class PurchaseReportPage extends StatefulWidget {
  const PurchaseReportPage({super.key});

  @override
  State<PurchaseReportPage> createState() => _PurchaseReportPageState();
}

class _PurchaseReportPageState extends State<PurchaseReportPage>
    with AutomaticKeepAliveClientMixin, LoadingPopup, DefaultResponse {
  late Server server;
  String? _reportType;
  bool _isDisplayTable = false;
  double minimumColumnWidth = 150;
  late final CustomAsyncDataTableSource<PurchaseReport> _source;
  late Flash flash;
  Map _filter = {};
  @override
  void initState() {
    server = context.read<Server>();
    final setting = context.read<Setting>();
    _source = CustomAsyncDataTableSource<PurchaseReport>(
      columns: setting.tableColumn('purchaseReport'),
      fetchData: (
          {bool isAscending = true,
          int limit = 10,
          int page = 1,
          TableColumn? sortColumn}) {
        _reportType = 'json';
        return _requestReport(
                page: page,
                limit: limit,
                sortColumn: sortColumn,
                isAscending: isAscending)
            .then((response) {
          try {
            if (response.statusCode != 200) {
              return ResponseResult<PurchaseReport>(totalRows: 0, models: []);
            }
            var data = response.data;
            setState(() {
              _isDisplayTable = true;
            });
            final models = data['data'].map<PurchaseReport>((row) {
              return PurchaseReport.fromJson(row,
                  included: data['included'] ?? []);
            }).toList();
            return ResponseResult<PurchaseReport>(
                models: models, totalRows: data['meta']['total_rows']);
          } catch (error, stackTrace) {
            debugPrint(error.toString());
            debugPrint(stackTrace.toString());
            return ResponseResult<PurchaseReport>(totalRows: 0, models: []);
          }
        }, onError: ((error, stackTrace) {
          defaultErrorResponse(error: error);
          return Future(() => ResponseResult<PurchaseReport>(models: []));
        }));
      },
    );
    flash = Flash();
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  void _displayReport() async {
    _source.refreshDataFromFirstPage();
  }

  void _downloadReport() async {
    flash.show(
      const Text('Dalam proses.'),
      ToastificationType.info,
    );
    _reportType = 'xlsx';
    _requestReport().then(_downloadResponse,
        onError: ((error, stackTrace) => defaultErrorResponse(error: error)));
  }

  Future _requestReport(
      {int page = 1,
      int limit = 10,
      TableColumn? sortColumn,
      bool isAscending = true}) async {
    String orderKey = sortColumn?.name ?? 'purchase_date';
    Map<String, dynamic> param = {
      'page[page]': page.toString(),
      'page[limit]': limit.toString(),
      'report_type': _reportType ?? 'json',
      'sort': '${isAscending ? '' : '-'}$orderKey',
      'include': 'supplier',
    };
    _filter.forEach((key, value) {
      param[key] = value;
    });
    return server.get('purchases/report',
        queryParam: param, type: _reportType ?? 'json');
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return VerticalBodyScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TableFilterForm(
              showCanopy: true,
              onSubmit: (filter) {
                _filter = filter;
                _displayReport();
              },
              enums: const {
                'status': PurchaseReportStatus.values,
              },
              onDownload: (filter) {
                _filter = filter;
                _downloadReport();
              },
              columns: _source.columns),
          const SizedBox(height: 10),
          Visibility(visible: _isDisplayTable, child: const Divider()),
          SizedBox(
            height: bodyScreenHeight,
            child: CustomAsyncDataTable(
              controller: _source,
              fixedLeftColumns: 1,
            ),
          ),
        ],
      ),
    );
  }
}
