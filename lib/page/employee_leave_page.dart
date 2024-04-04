import 'package:fe_pos/model/employee_leave.dart';
import 'package:fe_pos/page/employee_leave_form_page.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_data_table.dart';
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
    with AutomaticKeepAliveClientMixin {
  final _source = CustomDataTableSource<EmployeeLeave>();
  late final Server server;
  bool _isDisplayTable = false;
  String _searchText = '';
  List<EmployeeLeave> employeeLeaves = [];
  final cancelToken = CancelToken();
  late Flash flash;
  late final Setting setting;
  Map _filter = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash(context);
    setting = context.read<Setting>();
    _source.columns = setting.tableColumn('employeeLeave');
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
      employeeLeaves = [];
      _isDisplayTable = false;
    });
    fetchEmployeeLeaves(page: 1);
  }

  Future fetchEmployeeLeaves({int page = 1}) {
    String orderKey = _source.sortColumn?.sortKey ?? 'employees.name';
    Map<String, dynamic> param = {
      'search_text': _searchText,
      'page[page]': page.toString(),
      'page[limit]': '100',
      'include': 'employee',
      'sort': '${_source.isAscending ? '' : '-'}$orderKey',
    };
    _filter.forEach((key, value) {
      param[key] = value;
    });
    try {
      return server
          .get('employee_leaves', queryParam: param, cancelToken: cancelToken)
          .then((response) {
        if (response.statusCode != 200) {
          throw 'error: ${response.data.toString()}';
        }
        Map responseBody = response.data;
        if (responseBody['data'] is! List) {
          throw 'error: invalid data type ${response.data.toString()}';
        }
        employeeLeaves.addAll(responseBody['data']
            .map<EmployeeLeave>((json) => EmployeeLeave.fromJson(json,
                included: responseBody['included']))
            .toList());
        setState(() {
          _isDisplayTable = true;
          _source.setData(employeeLeaves);
        });

        flash.hide();
        final totalPages = responseBody['meta']?['total_pages'];
        if (page < totalPages.toInt()) {
          fetchEmployeeLeaves(page: page + 1);
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
    var tabManager = context.read<TabManager>();
    setState(() {
      EmployeeLeave employeeLeave = EmployeeLeave(
          leaveType: LeaveType.annualLeave,
          date: Date.today(),
          employee: Employee(
              code: '',
              name: '',
              role: Role(name: ''),
              startWorkingDate: Date.today()));
      tabManager.addTab(
          'Tambah Cuti Karyawan',
          EmployeeLeaveFormPage(
              key: ObjectKey(employeeLeave), employeeLeave: employeeLeave));
    });
  }

  void editForm(EmployeeLeave employeeLeave) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
          'Edit Cuti Karyawan ${employeeLeave.id}',
          EmployeeLeaveFormPage(
              key: ObjectKey(employeeLeave), employeeLeave: employeeLeave));
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

  void destroyRecord(EmployeeLeave employeeLeave) {
    showConfirmDialog(
        message:
            'Apakah anda yakin hapus ${employeeLeave.employee.name} tanggal ${setting.dateFormat(employeeLeave.date)}?',
        onSubmit: () {
          server.delete('/employee_leaves/${employeeLeave.id}').then(
              (response) {
            if (response.statusCode == 200) {
              flash.showBanner(
                  messageType: MessageType.success,
                  title: 'Sukses Hapus',
                  description:
                      'Sukses Hapus employee_leave ${employeeLeave.employee.name}');
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

  final menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _source.setActionButtons((employeeLeave, index) => <Widget>[
          IconButton(
              onPressed: () {
                editForm(employeeLeave);
              },
              tooltip: 'Edit Cuti Karyawan',
              icon: const Icon(Icons.edit)),
          IconButton(
              onPressed: () {
                destroyRecord(employeeLeave);
              },
              tooltip: 'Hapus Cuti Karyawan',
              icon: const Icon(Icons.delete)),
        ]);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          children: [
            TableFilterForm(
              columns: _source.columns,
              enums: const {'leave_type': LeaveType.values},
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
                      controller: menuController,
                      menuChildren: [
                        MenuItemButton(
                          child: const Text('Tambah Cuti Karyawan'),
                          onPressed: () {
                            menuController.close();
                            addForm();
                          },
                        ),
                      ],
                      child: const Icon(Icons.table_rows_rounded))
                ],
              ),
            ),
            Visibility(
                visible: _isDisplayTable,
                child: SizedBox(
                  height: 600,
                  child: CustomDataTable(
                    controller: _source,
                    fixedLeftColumns: 2,
                    showCheckboxColumn: true,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
