import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
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
  late final TrinaGridStateManager _source;
  late final Server server;

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
    columns = setting.tableColumn('bookPayslipLine');
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
  }

  Future<DataTableResponse<BookPayslipLine>> fetchData(QueryRequest request) {
    request.filters = _filters;

    request.include = ['employee', 'payroll_type'];
    return BookPayslipLineClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<BookPayslipLine>(
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
    BookPayslipLine bookPayslipLine = BookPayslipLine();

    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'New BookPayslipLine',
        BookPayslipLineFormPage(
          key: ObjectKey(bookPayslipLine),
          bookPayslipLine: bookPayslipLine,
        ),
      );
    });
  }

  void editForm(BookPayslipLine bookPayslipLine) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'Edit BookPayslipLine ${bookPayslipLine.id}',
        BookPayslipLineFormPage(
          key: ObjectKey(bookPayslipLine),
          bookPayslipLine: bookPayslipLine,
        ),
      );
    });
  }

  void destroyRecord(BookPayslipLine bookPayslipLine) {
    showConfirmDialog(
      message: 'Apakah anda yakin hapus ${bookPayslipLine.id}?',
      onSubmit: () {
        server
            .delete('/book_payslip_lines/${bookPayslipLine.id}')
            .then(
              (response) {
                if (response.statusCode == 200) {
                  flash.showBanner(
                    messageType: ToastificationType.success,
                    title: 'Sukses Hapus',
                    description:
                        'Sukses Hapus BookPayslipLine ${bookPayslipLine.id}',
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return VerticalBodyScroll(
      child: Column(
        children: [
          TableFilterForm(
            columns: columns,
            onSubmit: (filter) {
              _filters = filter;
              refreshTable();
            },
            enums: {'group': PayrollGroup.values},
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 50,
                  child: SubmenuButton(
                    menuChildren: [
                      MenuItemButton(
                        child: const Text('Tambah BookPayslipLine'),
                        onPressed: () => addForm(),
                      ),
                    ],
                    child: const Icon(Icons.table_rows_rounded),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: bodyScreenHeight,
            child: CustomAsyncDataTable<BookPayslipLine>(
              renderAction: (bookPayslipLine) => Row(
                spacing: 10,
                children: [
                  IconButton(
                    onPressed: () {
                      editForm(bookPayslipLine);
                    },
                    tooltip: 'Edit BookPayslipLine',
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: () {
                      destroyRecord(bookPayslipLine);
                    },
                    tooltip: 'Hapus BookPayslipLine',
                    icon: const Icon(Icons.delete),
                  ),
                ],
              ),
              columns: columns,
              fetchData: fetchData,
              onLoaded: (stateManager) => _source = stateManager,
              fixedLeftColumns: 2,
            ),
          ),
        ],
      ),
    );
  }
}
