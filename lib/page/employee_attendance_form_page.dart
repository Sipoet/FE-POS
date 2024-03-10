import 'package:fe_pos/tool/flash.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/employee_attendance.dart';
import 'package:fe_pos/model/session_state.dart';

import 'package:fe_pos/tool/setting.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'package:provider/provider.dart';

class EmployeeAttendanceFormPage extends StatefulWidget {
  const EmployeeAttendanceFormPage({super.key});

  @override
  State<EmployeeAttendanceFormPage> createState() =>
      _EmployeeAttendanceFormPageState();
}

class _EmployeeAttendanceFormPageState extends State<EmployeeAttendanceFormPage>
    with AutomaticKeepAliveClientMixin {
  late Server _server;
  late Setting _setting;
  late final EmployeeAttendanceMassUploadDatatableSource _source;

  List<bool> selected = [];
  @override
  void initState() {
    _server = context.read<Server>();
    _setting = context.read<Setting>();
    _source = EmployeeAttendanceMassUploadDatatableSource(setting: _setting);
    super.initState();
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
          const SizedBox(
            height: 20,
          ),
          Center(
            child: ElevatedButton(
                onPressed: () {
                  pickFile();
                },
                child: const Text('Pilih file')),
          ),
          Visibility(
            visible: _source.rows.isNotEmpty,
            child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Hasil :',
                  style: headerStyle,
                ),
                const SizedBox(
                  height: 10,
                ),
                PaginatedDataTable(
                  showFirstLastButtons: true,
                  rowsPerPage: 30,
                  showCheckboxColumn: false,
                  sortAscending: _source.isAscending,
                  sortColumnIndex: _source.sortColumn,
                  columns: [
                    DataColumn(
                      label: const Text('Nama Karyawan', style: headerStyle),
                      onSort: (columnIndex, isAscending) {
                        final num = isAscending ? 1 : -1;
                        _source.rows.sort((a, b) =>
                            a.employee.name.compareTo(b.employee.name) * num);
                        setState(() {
                          _source.sortColumn = columnIndex;
                          _source.isAscending = isAscending;
                          _source.setData(_source.rows);
                        });
                      },
                    ),
                    DataColumn(
                      label: const Text('Tanggal', style: headerStyle),
                      onSort: (columnIndex, isAscending) {
                        final num = isAscending ? 1 : -1;
                        _source.rows
                            .sort((a, b) => a.date.compareTo(b.date) * num);
                        setState(() {
                          _source.sortColumn = columnIndex;
                          _source.isAscending = isAscending;
                          _source.setData(_source.rows);
                        });
                      },
                    ),
                    DataColumn(
                      label: const Text('Jam Masuk', style: headerStyle),
                      onSort: (columnIndex, isAscending) {
                        final num = isAscending ? 1 : -1;
                        _source.rows.sort(
                            (a, b) => a.startTime.compareTo(b.startTime) * num);
                        setState(() {
                          _source.sortColumn = columnIndex;
                          _source.isAscending = isAscending;
                          _source.setData(_source.rows);
                        });
                      },
                    ),
                    DataColumn(
                      label: const Text('Jam Keluar', style: headerStyle),
                      onSort: (columnIndex, isAscending) {
                        final num = isAscending ? 1 : -1;
                        _source.rows.sort(
                            (a, b) => a.endTime.compareTo(b.endTime) * num);
                        setState(() {
                          _source.sortColumn = columnIndex;
                          _source.isAscending = isAscending;
                          _source.setData(_source.rows);
                        });
                      },
                    ),
                  ],
                  source: _source,
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
    ));
  }

  Future createOrUpdateEmployeeAttendance(
      EmployeeAttendance employeeAttendance, int index) async {
    Map body = {'employee_attendance': employeeAttendance};
    dynamic request;
    if (employeeAttendance.id == null) {
      request = await _server.post('employee_attendances', body: body);
    } else {
      request = await _server
          .put('employee_attendances/${employeeAttendance.id}', body: body);
    }
    if ([200, 201].contains(request.statusCode)) {
      var data = request.data['data'];
      setState(() {
        if (employeeAttendance.id == null) {
          employeeAttendance.id = int.tryParse(data['id']);
          employeeAttendance.employee = Employee(
              id: data['attributes']['id'],
              code: 'code',
              name: data['attributes']['employee_name'],
              role: Role(name: ''),
              startWorkingDate: Date.today());
        }
        _source.selected[index] = false;
        _source.setStatus(index, 'saved');
      });
    } else {
      setState(() {
        _source.setStatus(index, 'failed');
      });
    }

    return request;
  }

  void pickFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
    if (result == null) {
      return;
    }
    final file = XFile(result.files.single.path!);

    _server.upload('employee_attendances/mass_upload', file).then((response) {
      if (response.statusCode == 201) {
        final responseBody = response.data['data'] as List;
        setState(() {
          final employeeAttendances = responseBody
              .map<EmployeeAttendance>((json) => EmployeeAttendance.fromJson(
                  json,
                  included: response.data['included']))
              .toList();
          _source.setData(employeeAttendances);
        });
      } else {
        final flash = Flash(context);
        flash.showBanner(
            messageType: MessageType.failed,
            title: 'gagal upload Absensi Karyawan',
            description: response.data['message']);
      }
    }, onError: (error) {
      _server.defaultErrorResponse(context: context, error: error);
    });
  }
}

class EmployeeAttendanceMassUploadDatatableSource extends DataTableSource {
  List<EmployeeAttendance> rows = [];
  List selected = [];
  List status = [];
  final Setting setting;
  bool isAscending = true;
  int sortColumn = 0;

  EmployeeAttendanceMassUploadDatatableSource({required this.setting});

  void setData(data) {
    rows = data;
    selected = List.generate(rows.length, (index) => true);
    status = List.generate(rows.length, (index) => 'Draft');
    notifyListeners();
  }

  void setStatus(index, newStatus) {
    status[index] = newStatus;
    notifyListeners();
  }

  @override
  int get rowCount => rows.length;

  @override
  DataRow? getRow(int index) {
    return DataRow(
      key: ObjectKey(rows[index]),
      cells: decorateEmployeeAttendance(index),
      selected: selected[index],
      onSelectChanged: (bool? value) {
        selected[index] = value!;
        notifyListeners();
      },
    );
  }

  List<DataCell> decorateEmployeeAttendance(int index) {
    final employeeAttendance = rows[index];
    return <DataCell>[
      DataCell(SelectableText(employeeAttendance.employee.name)),
      DataCell(SelectableText(setting.dateFormat(employeeAttendance.date))),
      DataCell(
          SelectableText(setting.dateTimeFormat(employeeAttendance.startTime))),
      DataCell(
          SelectableText(setting.dateTimeFormat(employeeAttendance.endTime))),
    ];
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
