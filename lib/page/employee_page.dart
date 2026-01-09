import 'package:collection/collection.dart';
import 'package:fe_pos/model/employee.dart';
import 'package:fe_pos/page/employee_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/widget/table_filter_form.dart';

class EmployeePage extends StatefulWidget {
  const EmployeePage({super.key});

  @override
  State<EmployeePage> createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final TrinaGridStateManager _source;
  late final Server server;
  late final Setting setting;
  String _searchText = '';
  final cancelToken = CancelToken();
  late Flash flash;
  final _menuController = MenuController();
  List<FilterData> _filters = [];
  List<TableColumn> columns = [];
  Map<int, Employee> _selected = {};
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    setting = context.read<Setting>();
    columns = setting.tableColumn('employee');
    super.initState();
  }

  @override
  void dispose() {
    cancelToken.cancel();
    _source.dispose();
    super.dispose();
  }

  Future<void> refreshTable() async {
    _source.refreshTable();
    _selected.clear();
  }

  Future<DataTableResponse<Employee>> fetchEmployees(QueryRequest request) {
    request.filters = _filters;
    request.searchText = _searchText;
    request.include = ['payroll', 'role'];
    return EmployeeClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<Employee>(
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
    Employee employee = Employee(
      code: '',
      name: '',
      startWorkingDate: Date.today(),
      role: Role(name: ''),
    );
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'Tambah Karyawan',
        EmployeeFormPage(key: ObjectKey(employee), employee: employee),
      );
    });
  }

  void editForm(Employee employee) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'Edit Karyawan ${employee.code}',
        EmployeeFormPage(key: ObjectKey(employee), employee: employee),
      );
    });
  }

  void toggleStatus(Employee employee) {
    final statusPath = employee.status == EmployeeStatus.active
        ? 'deactivate'
        : 'activate';
    final statusName = employee.status == EmployeeStatus.active
        ? 'nonaktifkan'
        : 'aktifkan';
    showConfirmDialog(
      message: 'Apakah yakin $statusName ${employee.name}?',
      onSubmit: () {
        server
            .post('employees/${employee.id}/$statusPath')
            .then(
              (response) {
                setState(() {
                  employee.status = employee.status == EmployeeStatus.active
                      ? EmployeeStatus.inactive
                      : EmployeeStatus.active;
                });
                _source.refreshTable();
                flash.showBanner(
                  title: 'Sukses',
                  description: 'karyawan ${employee.code} sukses $statusName',
                  messageType: ToastificationType.success,
                  duration: const Duration(seconds: 3),
                );
              },
              onError: (error, stack) {
                defaultErrorResponse(error: error);
              },
            );
      },
    );
  }

  void activateSelected() {
    if (_selected.values.isEmpty) {
      return;
    }
    showConfirmDialog(
      message: 'Apakah yakin aktifkan ${_selected.values.length} karyawan?',
      onSubmit: () async {
        try {
          for (final employee in _selected.values) {
            var response = await server.post(
              'employees/${employee.id}/activate',
            );
            if (response.statusCode == 200) {
              setState(() {
                employee.setFromJson(response.data['data']);
              });
            }
          }
          _source.refreshTable();
        } catch (e) {
          defaultErrorResponse(error: e);
        }
      },
    );
  }

  void deactivateSelected() {
    if (_selected.values.isEmpty) {
      return;
    }
    showConfirmDialog(
      message: 'Apakah yakin nonaktifkan ${_selected.values.length} karyawan?',
      onSubmit: () async {
        try {
          for (final employee in _selected.values) {
            var response = await server.post(
              'employees/${employee.id}/deactivate',
            );
            if (response.statusCode == 200) {
              setState(() {
                employee.setFromJson(response.data['data']);
              });
            }
          }
          _source.refreshTable();
        } catch (e) {
          defaultErrorResponse(error: e);
        }
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

  List<Widget> actionButtons(Employee employee, int index) {
    return <Widget>[
      IconButton(
        onPressed: () {
          editForm(employee);
        },
        tooltip: 'Edit karyawan',
        icon: const Icon(Icons.edit),
      ),
      IconButton(
        onPressed: () {
          setState(() {
            toggleStatus(employee);
          });
        },
        tooltip: 'Aktivasi/deaktivasi karyawan',
        icon: Icon(
          Icons.lightbulb,
          color: employee.status == EmployeeStatus.active
              ? Colors.yellow
              : null,
        ),
      ),
    ];
  }

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
              enums: const {
                'status': EmployeeStatus.values,
                'marital_status': EmployeeMaritalStatus.values,
                'religion': Religion.values,
              },
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
                      controller: _menuController,
                      menuChildren: [
                        MenuItemButton(
                          child: const Text('Tambah Karyawan'),
                          onPressed: () {
                            _menuController.close();
                            addForm();
                          },
                        ),
                        MenuItemButton(
                          child: const Text('Aktifkan Karyawan'),
                          onPressed: () {
                            _menuController.close();
                            activateSelected();
                          },
                        ),
                        MenuItemButton(
                          child: const Text('nonaktifkan Karyawan'),
                          onPressed: () {
                            _menuController.close();
                            deactivateSelected();
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
              child: CustomAsyncDataTable<Employee>(
                renderAction: (employee) => Row(
                  spacing: 10,
                  children: [
                    if (setting.isAuthorize('employee', 'update'))
                      IconButton(
                        onPressed: () {
                          editForm(employee);
                        },
                        tooltip: 'Edit karyawan',
                        icon: const Icon(Icons.edit),
                      ),
                    if (setting.isAuthorize('employee', 'deactivate') ||
                        setting.isAuthorize('employee', 'activate') &&
                            setting.canShow('employee', 'status'))
                      IconButton(
                        onPressed: () {
                          setState(() {
                            toggleStatus(employee);
                          });
                        },
                        tooltip: 'Aktivasi/deaktivasi karyawan',
                        icon: Icon(
                          Icons.lightbulb,
                          color: employee.status == EmployeeStatus.active
                              ? Colors.yellow
                              : null,
                        ),
                      ),
                  ],
                ),
                onRowChecked: (event) {
                  final employee = _source.modelFromCheckEvent<Employee>(event);
                  if (event.isChecked == null || employee == null) {
                    return;
                  }

                  if (event.isChecked == true) {
                    _selected[event.rowIdx ?? -1] = employee;
                  } else {
                    _selected.remove(event.rowIdx);
                  }
                },
                onLoaded: (stateManager) => _source = stateManager,
                fixedLeftColumns: 2,
                columns: columns,
                fetchData: fetchEmployees,
                showCheckboxColumn: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
