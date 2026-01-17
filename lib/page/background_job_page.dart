import 'package:fe_pos/model/background_job.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/widget/sync_data_table.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BackgroundJobPage extends StatefulWidget {
  const BackgroundJobPage({super.key});

  @override
  State<BackgroundJobPage> createState() => _BackgroundJobPageState();
}

class _BackgroundJobPageState extends State<BackgroundJobPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late List<TableColumn> _columns;
  List<BackgroundJob> records = [];
  TrinaGridStateManager? stateManager;
  late final Server _server;
  final flash = Flash();
  @override
  void initState() {
    _columns = [
      TableColumn(clientWidth: 180, name: 'job_class', humanizeName: 'Aksi'),
      TableColumn(clientWidth: 220, name: 'args', humanizeName: 'Arguments'),
      TableColumn(
        clientWidth: 180,
        name: 'description',
        type: TextTableColumnType(),
        humanizeName: 'Deskripsi',
      ),
      TableColumn(clientWidth: 150, name: 'status', humanizeName: 'Status'),
      TableColumn(
        type: DateTimeTableColumnType(),
        clientWidth: 180,
        name: 'created_at',
        humanizeName: 'Tgl Buat',
      ),
      TableColumn(
        clientWidth: 150,
        name: 'action',
        renderBody: (rendererContext) {
          final record = records[rendererContext.rowIdx];
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                tooltip: 'Jalankan Ulang',
                onPressed: () => _retryJob(record),
                icon: Icon(Icons.refresh),
              ),
              Offstage(
                offstage: record.status == BackgroundJobStatus.finished,
                child: IconButton(
                  tooltip: 'Batalkan',
                  onPressed: () => _cancelJob(record),
                  icon: Icon(Icons.block),
                ),
              ),
              Offstage(
                offstage:
                    record.status == BackgroundJobStatus.process ||
                    record.status == BackgroundJobStatus.retry,
                child: IconButton(
                  tooltip: 'Hapus',
                  onPressed: () => _removeJob(record),
                  icon: Icon(Icons.close),
                ),
              ),
            ],
          );
        },
        humanizeName: '',
      ),
    ];
    _server = context.read<Server>();

    super.initState();
    Future.delayed(Duration.zero, _fetchRecord);
  }

  @override
  bool get wantKeepAlive => true;

  void _retryJob(BackgroundJob record) {
    if (record.status == BackgroundJobStatus.retry ||
        record.status == BackgroundJobStatus.process ||
        record.status == BackgroundJobStatus.scheduled) {
      return;
    }
    _server.post('background_jobs/${record.id}/retry').then((response) {
      if (response.statusCode == 200) {
        flash.showBanner(
          title: 'Sukses Jalankan Ulang',
          description:
              'Sukses Jalankan Ulang ${record.modelValue} (${record.id})',
          messageType: ToastificationType.success,
        );
        _fetchRecord();
      } else {
        flash.showBanner(
          title: 'Gagal Jalankan Ulang',
          description: response.data.toString(),
          messageType: ToastificationType.error,
        );
      }
    }, onError: (error) => defaultErrorResponse(error: error));
  }

  void _cancelJob(BackgroundJob record) {
    _server.post('background_jobs/${record.id}/cancel').then((response) {
      if (response.statusCode == 200) {
        flash.showBanner(
          title: 'Sukses Batalkan',
          description: 'Sukses Batalkan ${record.modelValue} (${record.id})',
          messageType: ToastificationType.success,
        );
      } else {
        flash.showBanner(
          title: 'Gagal Batalkan',
          description: response.data.toString(),
          messageType: ToastificationType.error,
        );
      }
    }, onError: (error) => defaultErrorResponse(error: error));
  }

  void _removeJob(BackgroundJob record) {
    _server.delete('background_jobs/${record.id}').then((response) {
      if (response.statusCode == 200) {
        flash.showBanner(
          title: 'Sukses Hapus',
          description: 'Sukses Hapus ${record.modelValue} (${record.id})',
          messageType: ToastificationType.success,
        );
      } else {
        flash.showBanner(
          title: 'Gagal Hapus',
          description: response.data.toString(),
          messageType: ToastificationType.error,
        );
      }
    }, onError: (error) => defaultErrorResponse(error: error));
  }

  void _fetchRecord() {
    stateManager?.setShowLoading(true);

    _server
        .get('background_jobs')
        .then((response) {
          if (response.statusCode == 200) {
            final data = response.data;

            records = data['data']
                .map<BackgroundJob>(
                  (json) => BackgroundJobClass().fromJson(
                    json,
                    included: data['included'] ?? [],
                  ),
                )
                .toList();

            stateManager?.setModels(records);
          }
        }, onError: (error) => defaultErrorResponse(error: error))
        .whenComplete(() => stateManager?.setShowLoading(false));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: VerticalBodyScroll(
        child: Column(
          children: [
            Text("Background Job Log"),
            Divider(),
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: _fetchRecord,
                icon: Icon(Icons.refresh),
              ),
            ),
            SizedBox(
              height: bodyScreenHeight,
              child: SyncDataTable<BackgroundJob>(
                columns: _columns,
                rows: records,
                onLoaded: (newStateManager) => stateManager = newStateManager,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
