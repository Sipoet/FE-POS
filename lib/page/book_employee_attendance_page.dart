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
  late final CustomAsyncDataTableSource<BookEmployeeAttendance> _source;
  late final Server server;

  String _searchText = '';
  final cancelToken = CancelToken();
  late Flash flash;
  Map _filter = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    final setting = context.read<Setting>();
    _source = CustomAsyncDataTableSource<BookEmployeeAttendance>(
        columns: setting.tableColumn('bookEmployeeAttendance'),
        fetchData: fetchData);
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

  Future<ResponseResult<BookEmployeeAttendance>> fetchData(
      {int page = 1,
      int limit = 100,
      TableColumn? sortColumn,
      bool isAscending = true}) {
    String orderKey = sortColumn?.name ?? 'start_date';
    Map<String, dynamic> param = {
      'search_text': _searchText,
      'page[page]': page.toString(),
      'page[limit]': limit.toString(),
      'sort': '${isAscending ? '' : '-'}$orderKey',
      'include': 'employee'
    };
    _filter.forEach((key, value) {
      param[key] = value;
    });
    try {
      return server
          .get('book_employee_attendances',
              queryParam: param, cancelToken: cancelToken)
          .then((response) {
        if (response.statusCode != 200) {
          throw 'error: ${response.data.toString()}';
        }
        Map responseBody = response.data;
        if (responseBody['data'] is! List) {
          throw 'error: invalid data type ${response.data.toString()}';
        }
        final models = responseBody['data']
            .map<BookEmployeeAttendance>((json) =>
                BookEmployeeAttendance.fromJson(json,
                    included: responseBody['included'] ?? []))
            .toList();
        int totalRows =
            responseBody['meta']?['total_rows'] ?? responseBody['data'].length;
        return ResponseResult<BookEmployeeAttendance>(
            models: models, totalRows: totalRows);
      },
              onError: (error, stackTrace) =>
                  defaultErrorResponse(error: error, valueWhenError: []));
    } catch (e, trace) {
      flash.showBanner(
          title: e.toString(),
          description: trace.toString(),
          messageType: ToastificationType.error);
      return Future(() => ResponseResult<BookEmployeeAttendance>(models: []));
    }
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _source.actionButtons = ((bookEmployeeAttendance, index) => <Widget>[
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
        ]);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          children: [
            TableFilterForm(
              columns: _source.columns,
              onSubmit: (filter) {
                _filter = filter;
                refreshTable();
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
              child: CustomAsyncDataTable(
                controller: _source,
                fixedLeftColumns: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
