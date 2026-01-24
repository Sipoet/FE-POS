import 'package:fe_pos/model/payroll.dart';
import 'package:fe_pos/page/payroll_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class PayrollPage extends StatefulWidget {
  const PayrollPage({super.key});

  @override
  State<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends State<PayrollPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final TableController _source;
  late final Server server;
  late final Setting setting;
  final cancelToken = CancelToken();
  late Flash flash;
  List<FilterData> _filters = [];
  List<TableColumn> columns = [];
  final _menuController = MenuController();
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    setting = context.read<Setting>();
    columns = setting.tableColumn('payroll');

    super.initState();
    Future.delayed(Duration.zero, refreshTable);
  }

  @override
  void dispose() {
    cancelToken.cancel();
    // _source.dispose();
    super.dispose();
  }

  Future<void> refreshTable() async {
    // clear table row
    _source.refreshTable();
  }

  Future<DataTableResponse<Payroll>> fetchPayrolls(QueryRequest request) {
    request.filters = _filters;
    return PayrollClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<Payroll>(
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
    Payroll payroll = Payroll(name: '', lines: []);

    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'New Payroll',
        PayrollFormPage(key: ObjectKey(payroll), payroll: payroll),
      );
    });
  }

  void editForm(Payroll payroll) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'Edit Payroll ${payroll.name}',
        PayrollFormPage(key: ObjectKey(payroll), payroll: payroll),
      );
    });
  }

  void destroyRecord(Payroll payroll) {
    showConfirmDialog(
      message: 'Apakah anda yakin hapus ${payroll.name}?',
      onSubmit: () {
        server
            .delete('/payrolls/${payroll.id}')
            .then(
              (response) {
                if (response.statusCode == 200) {
                  flash.showBanner(
                    messageType: ToastificationType.success,
                    title: 'Sukses Hapus',
                    description: 'Sukses Hapus payroll ${payroll.name}',
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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          children: [
            TableFilterForm(
              columns: columns,
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
                  SizedBox(
                    width: 50,
                    child: SubmenuButton(
                      controller: _menuController,
                      menuChildren: [
                        if (setting.isAuthorize('payrolls', 'create'))
                          MenuItemButton(
                            child: const Text('Tambah Payroll'),
                            onPressed: () {
                              _menuController.close();
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
              height: bodyScreenHeight,
              child: CustomAsyncDataTable<Payroll>(
                renderAction: (payroll) => Row(
                  spacing: 10,
                  children: [
                    if (setting.isAuthorize('payrolls', 'update'))
                      IconButton(
                        onPressed: () {
                          editForm(payroll);
                        },
                        tooltip: 'Edit Payroll',
                        icon: const Icon(Icons.edit),
                      ),
                    if (setting.isAuthorize('payrolls', 'destroy'))
                      IconButton(
                        onPressed: () {
                          destroyRecord(payroll);
                        },
                        tooltip: 'Hapus Payroll',
                        icon: const Icon(Icons.delete),
                      ),
                  ],
                ),
                onLoaded: (stateManager) => _source = stateManager,
                fixedLeftColumns: 1,
                fetchData: fetchPayrolls,
                columns: columns,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
