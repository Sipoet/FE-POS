import 'package:fe_pos/model/employee_attendance.dart';
import 'package:fe_pos/page/employee_attendance_form_page.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_data_table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class EmployeeAttendancePage extends StatefulWidget {
  const EmployeeAttendancePage({super.key});

  @override
  State<EmployeeAttendancePage> createState() => _EmployeeAttendancePageState();
}

class _EmployeeAttendancePageState extends State<EmployeeAttendancePage> {
  final _source = CustomDataTableSource<EmployeeAttendance>();
  late final Server server;
  bool _isDisplayTable = false;
  String _searchText = '';
  List<EmployeeAttendance> employeeAttendances = [];
  final cancelToken = CancelToken();
  late Flash flash;
  late final Setting setting;

  @override
  void initState() {
    server = context.read<SessionState>().server;
    flash = Flash(context);
    setting = context.read<Setting>();
    _source.columns = setting.tableColumn('employeeAttendance');
    refreshTable();
    super.initState();
  }

  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  Future<void> refreshTable() async {
    // clear table row
    setState(() {
      employeeAttendances = [];
      _isDisplayTable = false;
    });
    fetchEmployeeAttendances(page: 1);
  }

  Future fetchEmployeeAttendances({int page = 1}) {
    String orderKey = _source.sortColumn ?? 'code';
    try {
      return server
          .get('employee_attendances',
              queryParam: {
                'search_text': _searchText,
                'page[offset]': ((page - 1) * 100).toString(),
                'page[limit]': '100',
                'include': 'employee',
                'order_key': orderKey,
                'is_order_asc': _source.isAscending.toString(),
              },
              cancelToken: cancelToken)
          .then((response) {
        if (response.statusCode != 200) {
          throw 'error: ${response.data.toString()}';
        }
        Map responseBody = response.data;
        if (responseBody['data'] is! List) {
          throw 'error: invalid data type ${response.data.toString()}';
        }
        employeeAttendances.addAll(responseBody['data']
            .map<EmployeeAttendance>((json) => EmployeeAttendance.fromJson(json,
                included: responseBody['included']))
            .toList());
        setState(() {
          _isDisplayTable = true;
          _source.setData(employeeAttendances);
        });

        flash.hide();
        final totalPages = responseBody['meta']?['total_pages'];
        if (page < totalPages.toInt()) {
          fetchEmployeeAttendances(page: page + 1);
        }
      },
              onError: (error, stackTrace) => server.defaultErrorResponse(
                  context: context, error: error, valueWhenError: []));
    } catch (e, trace) {
      flash.showBanner(
          title: e.toString(),
          description: trace.toString(),
          messageType: MessageType.failed);
      return Future(() => null);
    }
  }

  void massUploadAttendance() {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
          'Mass Upload Employee Attendance',
          const EmployeeAttendanceFormPage(
            key: ObjectKey('EmployeeAttendanceFormPage'),
          ));
    });
  }

  void showConfirmDialog(
      {required Function onSubmit, String message = 'Apakah Anda Yakin?'}) {
    AlertDialog alert = AlertDialog(
      title: const Text("Konfirmasi"),
      content: Text(message),
      actions: [
        ElevatedButton(
          child: const Text("Kembali"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: const Text("Submit"),
          onPressed: () {
            onSubmit();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void destroyRecord(EmployeeAttendance employeeAttendance) {
    showConfirmDialog(
        message:
            'Apakah anda yakin hapus ${employeeAttendance.employee.name} tanggal ${setting.dateFormat(employeeAttendance.date)}?',
        onSubmit: () {
          server.delete('/employee_attendances/${employeeAttendance.id}').then(
              (response) {
            if (response.statusCode == 200) {
              flash.showBanner(
                  messageType: MessageType.success,
                  title: 'Sukses Hapus',
                  description:
                      'Sukses Hapus employee_attendance ${employeeAttendance.employee.name}');
              refreshTable();
            }
          }, onError: (error) {
            server.defaultErrorResponse(context: context, error: error);
          });
        });
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

  @override
  Widget build(BuildContext context) {
    _source.setActionButtons((employeeAttendance, index) => <Widget>[
          IconButton(
              onPressed: () {
                destroyRecord(employeeAttendance);
              },
              tooltip: 'Hapus Absensi Karyawan',
              icon: const Icon(Icons.delete)),
        ]);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
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
                  SubmenuButton(menuChildren: [
                    MenuItemButton(
                      child: const Text('Upload Absensi Karyawan'),
                      onPressed: () => massUploadAttendance(),
                    ),
                  ], child: const Icon(Icons.table_rows_rounded))
                ],
              ),
            ),
            Visibility(
                visible: _isDisplayTable,
                child: SizedBox(
                  height: 600,
                  child: CustomDataTable(
                    controller: _source,
                    fixedLeftColumns: 1,
                    showCheckboxColumn: true,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
