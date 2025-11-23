import 'package:fe_pos/model/employee_attendance.dart';
import 'package:fe_pos/page/employee_attendance_form_page.dart';
import 'package:fe_pos/page/employee_attendance_mass_upload_page.dart';
import 'package:fe_pos/page/mass_update_allowed_overtime_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class EmployeeAttendancePage extends StatefulWidget {
  const EmployeeAttendancePage({super.key});

  @override
  State<EmployeeAttendancePage> createState() => _EmployeeAttendancePageState();
}

class _EmployeeAttendancePageState extends State<EmployeeAttendancePage>
    with AutomaticKeepAliveClientMixin, TextFormatter, DefaultResponse {
  late final PlutoGridStateManager _source;
  late final Server server;
  String _searchText = '';
  List<EmployeeAttendance> employeeAttendances = [];
  final cancelToken = CancelToken();
  late Flash flash;
  late final Setting setting;
  List<FilterData> _filters = [];
  List<TableColumn> columns = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    setting = context.read<Setting>();
    columns = setting.tableColumn('employeeAttendance');

    super.initState();
  }

  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  Future<void> refreshTable() async {
    // clear table row
    _source.refreshTable();
  }

  Future<DataTableResponse<EmployeeAttendance>> fetchEmployeeAttendances(
      QueryRequest request) {
    request.filters = _filters;
    request.searchText = _searchText;
    request.include = ['employee'];
    return EmployeeAttendanceClass().finds(server, request).then(
        (value) => DataTableResponse<EmployeeAttendance>(
            models: value.models,
            totalPage: value.metadata['total_pages']), onError: (error) {
      defaultErrorResponse(error: error);
      return DataTableResponse.empty();
    });
  }

  void massUploadAttendance() {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
          'Mass Upload Absensi Karyawan',
          const EmployeeAttendanceMassUploadPage(
            key: ObjectKey('EmployeeAttendanceMassUploadFormPage'),
          ));
    });
  }

  void massUpdateAttendance() {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
          'Mass Update Overtime Absensi Karyawan',
          const MassUpdateAllowedOvertimeFormPage(
            key: ObjectKey('MassUpdateAllowedOvertimeFormPage'),
          ));
    });
  }

  void editRecord(employeeAttendance) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
          'Edit Absensi Karyawan',
          EmployeeAttendanceFormPage(
            employeeAttendance: employeeAttendance,
            key: const ObjectKey('EmployeeAttendanceFormPage'),
          ));
    });
  }

  void destroyRecord(EmployeeAttendance employeeAttendance) {
    showConfirmDialog(
        message:
            'Apakah anda yakin hapus ${employeeAttendance.employee.name} tanggal ${dateFormat(employeeAttendance.date)}?',
        onSubmit: () {
          server.delete('/employee_attendances/${employeeAttendance.id}').then(
              (response) {
            if (response.statusCode == 200) {
              flash.showBanner(
                  messageType: ToastificationType.success,
                  title: 'Sukses Hapus',
                  description:
                      'Sukses Hapus employee_attendance ${employeeAttendance.employee.name}');
              refreshTable();
            }
          }, onError: (error) {
            defaultErrorResponse(error: error);
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

  final _menuController = MenuController();

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
            ),
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
                  SizedBox(
                    width: 50,
                    child: SubmenuButton(
                        controller: _menuController,
                        menuChildren: [
                          MenuItemButton(
                            child: const Text('Upload Absensi Karyawan'),
                            onPressed: () {
                              _menuController.close();
                              massUploadAttendance();
                            },
                          ),
                          MenuItemButton(
                            child: const Text(
                                'Mass Update Overtime Absensi Karyawan'),
                            onPressed: () {
                              _menuController.close();
                              massUpdateAttendance();
                            },
                          ),
                        ],
                        child: const Icon(Icons.table_rows_rounded)),
                  )
                ],
              ),
            ),
            SizedBox(
              height: bodyScreenHeight,
              child: CustomAsyncDataTable2<EmployeeAttendance>(
                renderAction: (employeeAttendance) => Row(
                  spacing: 10,
                  children: [
                    IconButton(
                        onPressed: () {
                          editRecord(employeeAttendance);
                        },
                        tooltip: 'Edit Absensi Karyawan',
                        icon: const Icon(Icons.edit)),
                    IconButton(
                        onPressed: () {
                          destroyRecord(employeeAttendance);
                        },
                        tooltip: 'Hapus Absensi Karyawan',
                        icon: const Icon(Icons.delete)),
                  ],
                ),
                onLoaded: (stateManager) {
                  _source = stateManager;
                  _source.sortDescending(_source.columns[1]);
                },
                columns: columns,
                fetchData: fetchEmployeeAttendances,
                fixedLeftColumns: 1,
                showCheckboxColumn: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
