import 'package:fe_pos/tool/default_response.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/book_payslip_line.dart';
import 'package:fe_pos/page/book_payslip_line_form_page.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/widget/table_filter_form.dart';

class BookPayslipLinePage extends StatefulWidget {
  const BookPayslipLinePage({super.key});

  @override
  State<BookPayslipLinePage> createState() => _BookPayslipLinePageState();
}

class _BookPayslipLinePageState extends State<BookPayslipLinePage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final CustomAsyncDataTableSource<BookPayslipLine> _source;
  late final Server server;

  String _searchText = '';
  final cancelToken = CancelToken();
  late Flash flash;
  List<FilterData> _filter = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    final setting = context.read<Setting>();
    _source = CustomAsyncDataTableSource<BookPayslipLine>(
        columns: setting.tableColumn('bookPayslipLine'), fetchData: fetchData);
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

  Future<ResponseResult<BookPayslipLine>> fetchData(
      {int page = 1,
      int limit = 100,
      TableColumn? sortColumn,
      bool isAscending = true}) {
    String orderKey = sortColumn?.name ?? 'transacion_date';
    Map<String, dynamic> param = {
      'search_text': _searchText,
      'page[page]': page.toString(),
      'page[limit]': limit.toString(),
      'sort': '${isAscending ? '' : '-'}$orderKey',
      'include': 'employee,payroll_type'
    };
    for (final filterData in _filter) {
      final data = filterData.toEntryJson();
      param[data.key] = data.value;
    }
    try {
      return server
          .get('book_payslip_lines',
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
            .map<BookPayslipLine>((json) => BookPayslipLineClass()
                .fromJson(json, included: responseBody['included'] ?? []))
            .toList();
        int totalRows =
            responseBody['meta']?['total_rows'] ?? responseBody['data'].length;
        return ResponseResult<BookPayslipLine>(
            models: models, totalRows: totalRows);
      },
              onError: (error, stackTrace) =>
                  defaultErrorResponse(error: error, valueWhenError: []));
    } catch (e, trace) {
      flash.showBanner(
          title: e.toString(),
          description: trace.toString(),
          messageType: ToastificationType.error);
      return Future(() => ResponseResult<BookPayslipLine>(models: []));
    }
  }

  void addForm() {
    BookPayslipLine bookPayslipLine = BookPayslipLine();

    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
          'New BookPayslipLine',
          BookPayslipLineFormPage(
              key: ObjectKey(bookPayslipLine),
              bookPayslipLine: bookPayslipLine));
    });
  }

  void editForm(BookPayslipLine bookPayslipLine) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
          'Edit BookPayslipLine ${bookPayslipLine.id}',
          BookPayslipLineFormPage(
              key: ObjectKey(bookPayslipLine),
              bookPayslipLine: bookPayslipLine));
    });
  }

  void destroyRecord(BookPayslipLine bookPayslipLine) {
    showConfirmDialog(
        message: 'Apakah anda yakin hapus ${bookPayslipLine.id}?',
        onSubmit: () {
          server.delete('/book_payslip_lines/${bookPayslipLine.id}').then(
              (response) {
            if (response.statusCode == 200) {
              flash.showBanner(
                  messageType: ToastificationType.success,
                  title: 'Sukses Hapus',
                  description:
                      'Sukses Hapus BookPayslipLine ${bookPayslipLine.id}');
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
    _source.actionButtons = ((bookPayslipLine, index) => <Widget>[
          IconButton(
              onPressed: () {
                editForm(bookPayslipLine);
              },
              tooltip: 'Edit BookPayslipLine',
              icon: const Icon(Icons.edit)),
          IconButton(
              onPressed: () {
                destroyRecord(bookPayslipLine);
              },
              tooltip: 'Hapus BookPayslipLine',
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
                        child: const Text('Tambah BookPayslipLine'),
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
                showCheckboxColumn: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
