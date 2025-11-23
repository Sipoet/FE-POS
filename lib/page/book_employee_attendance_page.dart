import 'package:fe_pos/tool/default_response.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/book_employee_attendance.dart';
import 'package:fe_pos/page/book_employee_attendance_form_page.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/widget/table_filter_form.dart';

class BookEmployeeAttendancePage extends StatefulWidget {
  const BookEmployeeAttendancePage({super.key});

  @override
  State<BookEmployeeAttendancePage> createState() =>
      _BookEmployeeAttendancePageState();
}

class _BookEmployeeAttendancePageState extends State<BookEmployeeAttendancePage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final PlutoGridStateManager _source;
  late final Server server;

  String _searchText = '';
  final cancelToken = CancelToken();
  late Flash flash;
  List<FilterData> _filters = [];
  List<TableColumn> columns = [];
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    final setting = context.read<Setting>();
    columns = setting.tableColumn('bookEmployeeAttendance');
    super.initState();
  }

  @override
  void dispose() {
    cancelToken.cancel();
    _source.dispose();
    super.dispose();
  }

  Future<DataTableResponse<BookEmployeeAttendance>> fetchData(
      QueryRequest request) {
    request.filters = _filters;
    request.searchText = _searchText;
    request.include.add('employee');
    return BookEmployeeAttendanceClass().finds(server, request).then(
        (value) => DataTableResponse<BookEmployeeAttendance>(
            models: value.models,
            totalPage: value.metadata['total_pages']), onError: (error) {
      defaultErrorResponse(error: error);
      return DataTableResponse.empty();
    });
  }

  void addForm() {
    BookEmployeeAttendance bookEmployeeAttendance = BookEmployeeAttendance();

    final tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
          'New BookEmployeeAttendance',
          BookEmployeeAttendanceFormPage(
              key: ObjectKey(bookEmployeeAttendance),
              bookEmployeeAttendance: bookEmployeeAttendance));
    });
  }

  void editForm(BookEmployeeAttendance bookEmployeeAttendance) {
    final tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
          'Edit BookEmployeeAttendance ${bookEmployeeAttendance.id}',
          BookEmployeeAttendanceFormPage(
              key: ObjectKey(bookEmployeeAttendance),
              bookEmployeeAttendance: bookEmployeeAttendance));
    });
  }

  void destroyRecord(BookEmployeeAttendance bookEmployeeAttendance) {
    showConfirmDialog(
        message: 'Apakah anda yakin hapus ${bookEmployeeAttendance.id}?',
        onSubmit: () {
          server
              .delete('/book_employee_attendances/${bookEmployeeAttendance.id}')
              .then((response) {
            if (response.statusCode == 200) {
              flash.showBanner(
                  messageType: ToastificationType.success,
                  title: 'Sukses Hapus',
                  description:
                      'Sukses Hapus BookEmployeeAttendance ${bookEmployeeAttendance.id}');
              _source.refreshTable();
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
      _source.refreshTable();
    }
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
              onSubmit: (filter) {
                _filters = filter;
                _source.refreshTable();
              },
              enums: {'group': PayrollGroup.values},
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
                      _source.refreshTable();
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
                    child: SubmenuButton(menuChildren: [
                      MenuItemButton(
                        child: const Text('Tambah BookEmployeeAttendance'),
                        onPressed: () => addForm(),
                      ),
                    ], child: const Icon(Icons.table_rows_rounded)),
                  )
                ],
              ),
            ),
            SizedBox(
              height: bodyScreenHeight,
              child: CustomAsyncDataTable<BookEmployeeAttendance>(
                renderAction: (BookEmployeeAttendance bookEmployeeAttendance) {
                  return Row(
                    children: [
                      IconButton(
                          onPressed: () {
                            editForm(bookEmployeeAttendance);
                          },
                          tooltip: 'Edit BookEmployeeAttendance',
                          icon: const Icon(Icons.edit)),
                      IconButton(
                          onPressed: () {
                            destroyRecord(bookEmployeeAttendance);
                          },
                          tooltip: 'Hapus BookEmployeeAttendance',
                          icon: const Icon(Icons.delete)),
                    ],
                  );
                },
                onLoaded: (stateManager) => _source = stateManager,
                columns: columns,
                fetchData: fetchData,
                fixedLeftColumns: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
