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
  late final TableController _source;
  late Flash flash;
  List<FilterData> _filters = [];
  List<TableColumn> columns = [];
  @override
  void initState() {
    server = context.read<Server>();
    final setting = context.read<Setting>();
    columns = setting.tableColumn('purchaseReport');
    flash = Flash();
    super.initState();
  }

  Future<DataTableResponse<PurchaseReport>> fetchData(QueryRequest request) {
    _reportType = 'json';
    return _requestReport(request).then(
      (response) {
        try {
          if (response.statusCode != 200) {
            return DataTableResponse<PurchaseReport>(totalPage: 0, models: []);
          }
          var data = response.data;
          setState(() {
            _isDisplayTable = true;
          });
          final models = data['data'].map<PurchaseReport>((row) {
            return PurchaseReportClass().fromJson(
              row,
              included: data['included'] ?? [],
            );
          }).toList();
          return DataTableResponse<PurchaseReport>(
            models: models,
            totalPage: data['meta']['total_pages'],
          );
        } catch (error, stackTrace) {
          debugPrint(error.toString());
          debugPrint(stackTrace.toString());
          return DataTableResponse<PurchaseReport>(totalPage: 0, models: []);
        }
      },
      onError: ((error, stackTrace) {
        defaultErrorResponse(error: error);
        return Future(() => DataTableResponse<PurchaseReport>(models: []));
      }),
    );
  }

  @override
  bool get wantKeepAlive => true;

  void _displayReport() async {
    _source.refreshTable();
  }

  void _downloadReport() async {
    flash.show(const Text('Dalam proses.'), ToastificationType.info);
    _reportType = 'xlsx';
    _requestReport(QueryRequest(limit: 99999)).then(
      _downloadResponse,
      onError: ((error, stackTrace) => defaultErrorResponse(error: error)),
    );
  }

  Future _requestReport(QueryRequest request) async {
    request.filters = _filters;
    request.include = ['supplier'];
    return server.get(
      'ipos/purchases/report',
      queryParam: request.toQueryParam()
        ..addEntries([MapEntry('report_type', _reportType)]),
      type: _reportType ?? 'json',
    );
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
              _filters = filter;
              _displayReport();
            },
            enums: const {'status': PurchaseReportStatus.values},
            onDownload: (filter) {
              _filters = filter;
              _downloadReport();
            },
            columns: columns,
          ),
          const SizedBox(height: 10),
          Visibility(visible: _isDisplayTable, child: const Divider()),
          SizedBox(
            height: bodyScreenHeight,
            child: CustomAsyncDataTable<PurchaseReport>(
              onLoaded: (stateManager) => _source = stateManager,
              fixedLeftColumns: 1,
              columns: columns,
              fetchData: fetchData,
              showFilter: false,
            ),
          ),
        ],
      ),
    );
  }
}
