import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/model/item_report.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/sync_data_table.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/tool/file_saver.dart';

class ItemReportPage extends StatefulWidget {
  const ItemReportPage({super.key});

  @override
  State<ItemReportPage> createState() => _ItemReportPageState();
}

class _ItemReportPageState extends State<ItemReportPage>
    with AutomaticKeepAliveClientMixin, LoadingPopup, DefaultResponse {
  late Server server;
  String? _reportType;
  double minimumColumnWidth = 150;
  PlutoGridStateManager? _source;
  late Flash flash;
  late final List<TableColumn> columns;
  List<ItemReport> _itemReports = [];
  Map _filter = {};
  @override
  void initState() {
    server = context.read<Server>();
    final setting = context.read<Setting>();
    columns = setting.tableColumn('itemReport');
    flash = Flash();
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  void _displayReport() async {
    _source?.setShowLoading(true);
    final sortData = SortData(
        key: _source?.getSortedColumn?.field ?? 'item_code',
        isAscending: _source?.getSortedColumn?.sort.isAscending ?? true);
    _requestReport(page: 1, limit: 2000, sortData: sortData).then((response) {
      try {
        if (response.statusCode != 200) {
          setState(() {
            _itemReports = [];
            _source?.setModels(_itemReports, columns);
          });
          return;
        }
        var data = response.data;
        final initClass = ItemReportClass();
        setState(() {
          _itemReports = data['data'].map<ItemReport>((row) {
            return initClass.fromJson(row);
          }).toList();
          _source?.setModels(_itemReports, columns);
        });
      } catch (error, stackTrace) {
        debugPrint(error.toString());
        debugPrint(stackTrace.toString());
      }
    },
        onError: ((error, stackTrace) => defaultErrorResponse(
            error: error))).whenComplete(() => _source?.setShowLoading(false));
  }

  void _downloadReport() async {
    flash.show(
      const Text('Dalam proses.'),
      ToastificationType.info,
    );
    _reportType = 'xlsx';
    _requestReport(limit: null).then(_downloadResponse,
        onError: ((error, stackTrace) => defaultErrorResponse(error: error)));
  }

  Future _requestReport(
      {int page = 1, int? limit = 10, SortData? sortData}) async {
    String orderKey = sortData?.key ?? 'item_code';
    Map<String, dynamic> param = {
      'page[page]': page.toString(),
      'page[limit]': (limit ?? '').toString(),
      'report_type': _reportType ?? 'json',
      'include': 'item,supplier,brand,item_type',
      'sort': '${sortData?.isAscending == false ? '-' : ''}$orderKey',
    };
    _filter.forEach((key, value) {
      param[key] = value;
    });
    return server.get('item_reports',
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
          const SizedBox(height: 5),
          const Divider(),
          const SizedBox(height: 10),
          SizedBox(
            height: bodyScreenHeight,
            child: SyncDataTable<ItemReport>(
              showFilter: false,
              showSummary: true,
              isPaginated: true,
              rows: _itemReports,
              columns: columns,
              onLoaded: (stateManager) => _source = stateManager,
              fixedLeftColumns: 1,
            ),
          ),
        ],
      ),
    );
  }
}
