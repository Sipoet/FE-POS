import 'package:fe_pos/model/stock_location.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/file_saver.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/widget/table_filter_form.dart';

import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class StockLocationPage extends StatefulWidget {
  const StockLocationPage({super.key});

  @override
  State<StockLocationPage> createState() => _StockLocationPageState();
}

class _StockLocationPageState extends State<StockLocationPage>
    with DefaultResponse, LoadingPopup, PlatformChecker {
  late final TableController _source;
  late final Server server;

  List<StockLocation> items = [];
  final cancelToken = CancelToken();
  late final Flash flash;
  late final List<TableColumn> columns;
  late final Setting setting;
  List<FilterData> _filters = [];

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    setting = context.read<Setting>();

    columns = setting.tableColumn('ipos::ItemStock');
    super.initState();
  }

  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  Future<DataTableResponse<StockLocation>> fetchStockLocations(
    QueryRequest request,
  ) {
    request.includeAddAll(['item', 'location']);
    request.filters = _filters;
    return StockLocationClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<StockLocation>(
            models: value.models,
            totalPage: value.metadata['total_pages'],
          ),
          onError: (error) {
            defaultErrorResponse(error: error);
            return DataTableResponse.empty();
          },
        );
  }

  void refreshTable() {
    _source.refreshTable();
  }

  void downloadRacksheet() {
    showLoadingPopup();
    server
        .get('ipos/item_stocks/download_racksheets', type: 'xlsx')
        .then((response) async {
          if (response.statusCode == 409) {
            flash.showBanner(
              title: response.data['message'],
              description: (response.data['errors'] ?? []).join(','),
              messageType: ToastificationType.error,
            );
          } else if (response.statusCode != 200) {
            flash.showBanner(
              title: 'Gagal Download',
              description: 'Gagal Download Item Racksheet',
              messageType: ToastificationType.error,
            );
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
        }, onError: (error) => defaultErrorResponse(error: error))
        .whenComplete(() => hideLoadingPopup());
  }

  void uploadRacksheet() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result == null) {
      return;
    }
    Future<dynamic> request;
    final path = 'ipos/item_stocks/upload_racksheets';
    if (isWeb()) {
      final file = result.files.first;
      request = server.upload(
        path,
        bytes: file.bytes!.toList(),
        filename: file.name,
      );
    } else {
      final file = result.xFiles.first;
      request = server.upload(path, filepath: file.path, filename: file.name);
    }

    showLoadingPopup();

    request
        .then(
          (response) {
            final flash = Flash();
            if (response.statusCode == 200) {
              flash.showBanner(
                messageType: .success,
                title: 'Sukses upload Item Racksheet',
                description: response.data['message'],
              );
            } else {
              flash.showBanner(
                messageType: .error,
                title: 'gagal upload Item Racksheet',
                description: response.data['message'],
              );
            }
          },
          onError: (error) {
            defaultErrorResponse(error: error);
          },
        )
        .whenComplete(() => hideLoadingPopup());
  }

  @override
  Widget build(BuildContext context) {
    return VerticalBodyScroll(
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
            child: Wrap(
              runSpacing: 15,
              spacing: 10,
              children: [
                ElevatedButton(
                  onPressed: downloadRacksheet,
                  child: Text('Download Racksheet'),
                ),

                ElevatedButton(
                  onPressed: uploadRacksheet,
                  child: Text('Upload Racksheet'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: bodyScreenHeight,
            child: CustomAsyncDataTable<StockLocation>(
              onLoaded: (stateManager) => _source = stateManager,
              fixedLeftColumns: 1,
              fetchData: fetchStockLocations,
              columns: columns,
              showFilter: false,
            ),
          ),
        ],
      ),
    );
  }
}
