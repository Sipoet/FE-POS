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

class _EmployeePageState extends State<EmployeePage> {
  final _source = CustomDataTableSource<Employee>();
  late final Server server;
  bool _isDisplayTable = false;
  String _searchText = '';
  List<Employee> employees = [];
  final cancelToken = CancelToken();
  late Flash flash;
  Map _filter = {};

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash(context);
    final setting = context.read<Setting>();
    _source.columns = setting.tableColumn('employee');
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
      employees = [];
      _isDisplayTable = false;
    });
    fetchEmployees(page: 1);
  }

  Future fetchEmployees({int page = 1}) {
    String orderKey = _source.sortColumn?.sortKey ?? 'code';
    Map<String, dynamic> param = {
      'search_text': _searchText,
      'page': page.toString(),
      'per': '100',
      'fields[role]': 'name',
      'fields[payroll]': 'name',
      'include': 'role,payroll',
      'sort': '${_source.isAscending ? '' : '-'}$orderKey',
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
        employees.addAll(responseBody['data']
            .map<Employee>((json) =>
                Employee.fromJson(json, included: responseBody['included']))
            .toList());
        setState(() {
          _isDisplayTable = true;
          _source.setData(employees);
        });

        flash.hide();
        int totalPages = responseBody['meta']?['total_pages'];
        if (page < totalPages.toInt()) {
          fetchEmployees(page: page + 1);
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

  void addForm() {
    Employee employee = Employee(
        code: '',
        name: '',
        startWorkingDate: Date.today(),
        role: Role(name: ''));
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab('New Employee',
          EmployeeFormPage(key: ObjectKey(employee), employee: employee));
    });
  }

  void editForm(Employee employee) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab('Edit Employee ${employee.code}',
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

  void toggleStatus(Employee employee, int index) {
    final statusPath =
        employee.status == EmployeeStatus.active ? 'deactivate' : 'activate';
    final statusName =
        employee.status == EmployeeStatus.active ? 'nonaktifkan' : 'aktifkan';
    showConfirmDialog(
        message: 'Apakah yakin $statusName ${employee.name}?',
        onSubmit: () {
          server.post('employees/${employee.code}/$statusPath').then(
              (response) {
            _source.updateData(index, employee);
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
            await server.post('employees/${employee.code}/activate').then(
                (response) {
              employee = Employee.fromJson(response.data['data']);
              setState(() {
                _source.updateData(index, employee);
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
            await server.post('employees/${employee.code}/deactivate').then(
                (response) {
              employee = Employee.fromJson(response.data['data']);
              _source.updateData(index, employee);
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

  @override
  Widget build(BuildContext context) {
    _source.setActionButtons((employee, index) => <Widget>[
          IconButton(
              onPressed: () {
                editForm(employee);
              },
              tooltip: 'Edit karyawan',
              icon: const Icon(Icons.edit)),
          IconButton(
              onPressed: () {
                toggleStatus(employee, index);
              },
              tooltip: 'Aktivasi/deaktivasi karyawan',
              icon: employee.status == EmployeeStatus.active
                  ? const Icon(
                      Icons.lightbulb,
                      color: Colors.yellow,
                    )
                  : const Icon(
                      Icons.lightbulb,
                    )),
        ]);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          children: [
            TableFilterForm(
              columns: _source.columns,
              enums: const {'status': EmployeeStatus.values},
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
                  SubmenuButton(menuChildren: [
                    MenuItemButton(
                      child: const Text('Tambah Karyawan'),
                      onPressed: () => addForm(),
                    ),
                    MenuItemButton(
                      child: const Text('Aktifkan Karyawan'),
                      onPressed: () => activateSelected(),
                    ),
                    MenuItemButton(
                      child: const Text('nonaktifkan Karyawan'),
                      onPressed: () => deactivateSelected(),
                    ),
                  ], child: const Icon(Icons.table_rows_rounded))
                ],
              ),
            ),
            if (_isDisplayTable)
              SizedBox(
                height: 600,
                child: CustomDataTable(
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
