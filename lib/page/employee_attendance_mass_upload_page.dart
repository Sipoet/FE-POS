import 'package:fe_pos/model/item_report.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/date_range_form_field.dart';
import 'package:fe_pos/widget/number_form_field.dart';
import 'package:fe_pos/widget/sync_data_table.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/employee_attendance.dart';
import 'package:fe_pos/model/session_state.dart';

import 'package:file_picker/file_picker.dart';

import 'package:provider/provider.dart';

class EmployeeAttendanceMassUploadPage extends StatefulWidget {
  const EmployeeAttendanceMassUploadPage({super.key});

  @override
  State<EmployeeAttendanceMassUploadPage> createState() =>
      _EmployeeAttendanceMassUploadPageState();
}

class _EmployeeAttendanceMassUploadPageState
    extends State<EmployeeAttendanceMassUploadPage>
    with
        AutomaticKeepAliveClientMixin,
        LoadingPopup,
        PlatformChecker,
        TextFormatter,
        DefaultResponse {
  late Server _server;
  TableController? _source;
  late final List<TableColumn> _columns;
  final _focusNode = FocusNode();

  @override
  void initState() {
    _server = context.read<Server>();
    _columns = [
      TableColumn(
        clientWidth: 200,
        name: 'employee.name',
        humanizeName: 'Nama Karyawan',
      ),
      TableColumn(
        clientWidth: 150,
        name: 'date',
        humanizeName: 'Tanggal',
        type: DateTableColumnType(DateRangeType()),
      ),
      TableColumn(
        clientWidth: 120,
        name: 'start_work',
        humanizeName: 'Jam Masuk',
        type: TimeTableColumnType(),
      ),
      TableColumn(
        clientWidth: 120,
        name: 'end_work',
        humanizeName: 'Jam Keluar',
        type: TimeTableColumnType(),
      ),
      TableColumn(
        clientWidth: 100,
        name: 'shift',
        humanizeName: 'Shift',
        type: NumberTableColumnType(IntegerType()),
      ),
      TableColumn(
        clientWidth: 120,
        name: 'is_late',
        humanizeName: 'Terlambat?',
        type: BooleanTableColumnType(),
      ),
    ];
    super.initState();
    Future.delayed(Duration.zero, () => _focusNode.requestFocus());
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const headerStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 16);

    return SingleChildScrollView(
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.all(10),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  pickFile();
                },
                focusNode: _focusNode,
                child: const Text('Pilih file'),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 10),
                const Text('Hasil :', style: headerStyle),
                const SizedBox(height: 10),
                SizedBox(
                  height: bodyScreenHeight,
                  child: SyncDataTable<ItemReport>(
                    columns: _columns,
                    onLoaded: (stateManager) => _source = stateManager,
                    showFilter: true,
                    showSummary: false,
                    isPaginated: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result == null) {
      return;
    }
    Future<dynamic> request;
    if (isWeb()) {
      final file = result.files.first;
      request = _server.upload(
        'employee_attendances/mass_upload',
        bytes: file.bytes!.toList(),
        filename: file.name,
      );
    } else {
      final file = result.xFiles.first;
      request = _server.upload(
        'employee_attendances/mass_upload',
        file: file,
        filename: file.name,
      );
    }

    showLoadingPopup();

    request
        .then(
          (response) {
            if (response.statusCode == 201) {
              final responseBody = response.data['data'] as List;
              setState(() {
                final employeeAttendances = responseBody
                    .map<EmployeeAttendance>(
                      (json) => EmployeeAttendanceClass().fromJson(
                        json,
                        included: response.data['included'],
                      ),
                    )
                    .toList();
                _source?.setModels(employeeAttendances);
              });
            } else {
              final flash = Flash();
              flash.showBanner(
                messageType: ToastificationType.error,
                title: 'gagal upload Absensi Karyawan',
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
}
