import 'package:fe_pos/model/employee.dart';
import 'package:fe_pos/page/employee_form_page.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_data_table.dart';
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
    with AutomaticKeepAliveClientMixin {
  late final CustomAsyncDataTableSource<Employee> _source;
  late final Server server;
  String _searchText = '';
  final cancelToken = CancelToken();
  late Flash flash;
  final _menuController = MenuController();
  Map _filter = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash(context);
    final setting = context.read<Setting>();
    _source = CustomAsyncDataTableSource<Employee>(
        actionButtons: actionButtons,
        columns: setting.tableColumn('employee'),
        fetchData: fetchEmployees);
    super.initState();
    Future.delayed(Duration.zero, refreshTable);
  }

  @override
  void dispose() {
    cancelToken.cancel();
    _source.dispose();
    super.dispose();
  }

  Future<void> refreshTable() async {
    _source.refreshDataFromFirstPage();
  }

  Future<ResponseResult<Employee>> fetchEmployees(
      {int page = 1,
      int limit = 50,
      TableColumn? sortColumn,
      bool isAscending = true}) {
    String orderKey = sortColumn?.sortKey ?? 'code';
    Map<String, dynamic> param = {
      'search_text': _searchText,
      'page[page]': page.toString(),
      'page[limit]': limit.toString(),
      'fields[role]': 'name',
      'fields[payroll]': 'name',
      'include': 'role,payroll',
      'sort': '${isAscending ? '' : '-'}$orderKey',
    };
    _filter.forEach((key, value) {
      param[key] = value;
    });
    try {
      return server
          .get('employees', queryParam: param, cancelToken: cancelToken)
          .then((response) {
        if (response.statusCode != 200) {
          throw 'error: ${response.data.toString()}';
        }
        Map responseBody = response.data;
        if (responseBody['data'] is! List) {
          throw 'error: invalid data type ${response.data.toString()}';
        }
        final responsedModels = responseBody['data']
            .map<Employee>((json) =>
                Employee.fromJson(json, included: responseBody['included']))
            .toList();
        setState(() {
          // _source.setData(employees);
        });
        int totalPages = responseBody['meta']?['total_pages'];
        return ResponseResult<Employee>(
            totalPages: totalPages, models: responsedModels);
      },
              onError: (error, stackTrace) => server.defaultErrorResponse(
                  context: context, error: error, valueWhenError: []));
    } catch (e, trace) {
      flash.showBanner(
          title: e.toString(),
          description: trace.toString(),
          messageType: MessageType.failed);
      return Future(() => ResponseResult<Employee>(models: []));
    }
  }

  void addForm() {
    Employee employee = Employee(
        code: '',
        name: '',
        startWorkingDate: Date.today(),
        role: Role(name: ''));
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab('Tambah Karyawan',
          EmployeeFormPage(key: ObjectKey(employee), employee: employee));
    });
  }

  void editForm(Employee employee) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab('Edit Karyawan ${employee.code}',
          EmployeeFormPage(key: ObjectKey(employee), employee: employee));
    });
  }

  void showConfirmDialog(
      {required Function onSubmit, String message = 'Apakah Anda Yakin'}) {
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

  void toggleStatus(Employee employee) {
    final statusPath =
        employee.status == EmployeeStatus.active ? 'deactivate' : 'activate';
    final statusName =
        employee.status == EmployeeStatus.active ? 'nonaktifkan' : 'aktifkan';
    showConfirmDialog(
        message: 'Apakah yakin $statusName ${employee.name}?',
        onSubmit: () {
          server.post('employees/${employee.id}/$statusPath').then((response) {
            setState(() {
              employee.status = employee.status == EmployeeStatus.active
                  ? EmployeeStatus.inactive
                  : EmployeeStatus.active;
            });

            flash.showBanner(
                title: 'Sukses',
                description: 'karyawan ${employee.code} sukses $statusName',
                messageType: MessageType.success,
                duration: const Duration(seconds: 3));
          }, onError: (error, stack) {
            server.defaultErrorResponse(context: context, error: error);
          });
        });
  }

  void activateSelected() {
    if (_source.selected.isEmpty) {
      return;
    }
    showConfirmDialog(
        message: 'Apakah yakin aktifkan ${_source.selected.length} karyawan?',
        onSubmit: () {
          _source.selectedMap.forEach((int index, Employee employee) async {
            await server.post('employees/${employee.id}/activate').then(
                (response) {
              setState(() {
                Employee.fromJson(response.data['data'], model: employee);
                _source.refreshDatasource();
              });
            }, onError: (error, stack) {
              server.defaultErrorResponse(context: context, error: error);
            });
          });
        });
  }

  void deactivateSelected() {
    if (_source.selected.isEmpty) {
      return;
    }
    showConfirmDialog(
        message:
            'Apakah yakin nonaktifkan ${_source.selected.length} karyawan?',
        onSubmit: () {
          _source.selectedMap.forEach((int index, Employee employee) async {
            await server.post('employees/${employee.id}/deactivate').then(
                (response) {
              setState(() {
                Employee.fromJson(response.data['data'], model: employee);
              });
            }, onError: (error, stack) {
              server.defaultErrorResponse(context: context, error: error);
            });
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

  List<Widget> actionButtons(Employee employee, int index) {
    return <Widget>[
      IconButton(
          onPressed: () {
            editForm(employee);
          },
          tooltip: 'Edit karyawan',
          icon: const Icon(Icons.edit)),
      IconButton(
        onPressed: () {
          setState(() {
            toggleStatus(employee);
          });
        },
        tooltip: 'Aktivasi/deaktivasi karyawan',
        icon: Icon(
          Icons.lightbulb,
          color:
              employee.status == EmployeeStatus.active ? Colors.yellow : null,
        ),
      )
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
              columns: _source.columns,
              enums: const {
                'status': EmployeeStatus.values,
                'marital_status': EmployeeMaritalStatus.values
              },
              onSubmit: (filter) {
                _filter = filter;
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
                  SubmenuButton(
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
                      child: const Icon(Icons.table_rows_rounded))
                ],
              ),
            ),
            SizedBox(
              height: 600,
              child: CustomAsyncDataTable(
                controller: _source,
                fixedLeftColumns: 2,
                showCheckboxColumn: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
