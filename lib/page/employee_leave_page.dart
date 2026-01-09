import 'package:collection/collection.dart';
import 'package:fe_pos/model/employee_leave.dart';
import 'package:fe_pos/page/employee_leave_form_page.dart';
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

class EmployeeLeavePage extends StatefulWidget {
  const EmployeeLeavePage({super.key});

  @override
  State<EmployeeLeavePage> createState() => _EmployeeLeavePageState();
}

class _EmployeeLeavePageState extends State<EmployeeLeavePage>
    with AutomaticKeepAliveClientMixin, TextFormatter, DefaultResponse {
  late final TrinaGridStateManager _source;
  late final Server server;
  String _searchText = '';
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
    columns = setting.tableColumn('employeeLeave');

    super.initState();
    Future.delayed(Duration.zero, refreshTable);
  }

  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  Future<void> refreshTable() async {
    _source.refreshTable();
  }

  Future<DataTableResponse<EmployeeLeave>> fetchEmployeeLeaves(
    QueryRequest request,
  ) {
    request.filters = _filters;
    request.searchText = _searchText;
    request.include.add('employee');
    return EmployeeLeaveClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<EmployeeLeave>(
            models: value.models,
            totalPage: value.metadata['total_pages'],
          ),
          onError: (error) {
            defaultErrorResponse(error: error);
            return DataTableResponse.empty();
          },
        );
  }

  void addForm() {
    var tabManager = context.read<TabManager>();
    setState(() {
      EmployeeLeave employeeLeave = EmployeeLeave(
        leaveType: LeaveType.annualLeave,
        date: Date.today(),
        employee: Employee(
          code: '',
          name: '',
          role: Role(name: ''),
          startWorkingDate: Date.today(),
        ),
      );
      tabManager.addTab(
        'Buat Cuti Karyawan',
        EmployeeLeaveFormPage(
          key: ObjectKey(employeeLeave),
          employeeLeave: employeeLeave,
        ),
      );
    });
  }

  void editForm(EmployeeLeave employeeLeave) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'Edit Cuti Karyawan ${employeeLeave.id}',
        EmployeeLeaveFormPage(
          key: ObjectKey(employeeLeave),
          employeeLeave: employeeLeave,
        ),
      );
    });
  }

  void destroyRecord(EmployeeLeave employeeLeave) {
    showConfirmDialog(
      message:
          'Apakah anda yakin hapus ${employeeLeave.employee.name} tanggal ${dateFormat(employeeLeave.date)}?',
      onSubmit: () {
        server
            .delete('/employee_leaves/${employeeLeave.id}')
            .then(
              (response) {
                if (response.statusCode == 200) {
                  flash.showBanner(
                    messageType: ToastificationType.success,
                    title: 'Sukses Hapus',
                    description:
                        'Sukses Hapus employee_leave ${employeeLeave.employee.name}',
                  );
                  refreshTable();
                }
              },
              onError: (error) {
                defaultErrorResponse(error: error);
              },
            );
      },
    );
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

  final menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          children: [
            TableFilterForm(
              columns: columns,
              enums: const {'leave_type': LeaveType.values},
              onSubmit: (filter) {
                _filters = filter;
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
                      decoration: const InputDecoration(
                        hintText: 'Search Text',
                      ),
                      onChanged: searchChanged,
                      onSubmitted: searchChanged,
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: SubmenuButton(
                      controller: menuController,
                      menuChildren: [
                        if (setting.isAuthorize('employeeLeave', 'create'))
                          MenuItemButton(
                            child: const Text('Tambah Cuti Karyawan'),
                            onPressed: () {
                              menuController.close();
                              addForm();
                            },
                          ),
                      ],
                      child: const Icon(Icons.table_rows_rounded),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: <double>[bodyScreenHeight, 570].min,
              child: CustomAsyncDataTable<EmployeeLeave>(
                enums: {'leave_type': LeaveType.values},
                renderAction: (employeeLeave) => Row(
                  spacing: 10,
                  children: [
                    if (setting.isAuthorize('employeeLeave', 'update'))
                      IconButton(
                        onPressed: () {
                          editForm(employeeLeave);
                        },
                        tooltip: 'Edit Cuti Karyawan',
                        icon: const Icon(Icons.edit),
                      ),
                    if (setting.isAuthorize('employeeLeave', 'destroy'))
                      IconButton(
                        onPressed: () {
                          destroyRecord(employeeLeave);
                        },
                        tooltip: 'Hapus Cuti Karyawan',
                        icon: const Icon(Icons.delete),
                      ),
                  ],
                ),
                onLoaded: (stateManager) {
                  _source = stateManager;
                  _source.sortDescending(_source.columns[1]);
                },
                fetchData: fetchEmployeeLeaves,
                columns: columns,
                fixedLeftColumns: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
