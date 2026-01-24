import 'package:fe_pos/tool/default_response.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/payroll_type.dart';
import 'package:fe_pos/page/payroll_type_form_page.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/widget/table_filter_form.dart';

class PayrollTypePage extends StatefulWidget {
  const PayrollTypePage({super.key});

  @override
  State<PayrollTypePage> createState() => _PayrollTypePageState();
}

class _PayrollTypePageState extends State<PayrollTypePage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final TableController _source;
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

    columns = setting.tableColumn('payrollType');

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
    _source.refreshTable();
  }

  Future<DataTableResponse<PayrollType>> fetchPayrollTypes(
    QueryRequest request,
  ) {
    request.filters = _filters;

    return PayrollTypeClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<PayrollType>(
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
    PayrollType payrollType = PayrollType();

    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'New Payroll Type',
        PayrollTypeFormPage(
          key: ObjectKey(payrollType),
          payrollType: payrollType,
        ),
      );
    });
  }

  void editForm(PayrollType payrollType) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'Edit Payroll Type ${payrollType.name}',
        PayrollTypeFormPage(
          key: ObjectKey(payrollType),
          payrollType: payrollType,
        ),
      );
    });
  }

  void destroyRecord(PayrollType payrollType) {
    showConfirmDialog(
      message: 'Apakah anda yakin hapus ${payrollType.name}?',
      onSubmit: () {
        server
            .delete('/payroll_types/${payrollType.id}')
            .then(
              (response) {
                if (response.statusCode == 200) {
                  flash.showBanner(
                    messageType: ToastificationType.success,
                    title: 'Sukses Hapus',
                    description: 'Sukses Hapus payrollType ${payrollType.name}',
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
                      menuChildren: [
                        MenuItemButton(
                          child: const Text('Tambah Tipe Payroll'),
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
              child: CustomAsyncDataTable<PayrollType>(
                renderAction: (payrollType) => Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        editForm(payrollType);
                      },
                      tooltip: 'Edit Tipe Payroll',
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: () {
                        destroyRecord(payrollType);
                      },
                      tooltip: 'Hapus Tipe Payroll',
                      icon: const Icon(Icons.delete),
                    ),
                  ],
                ),
                onLoaded: (stateManager) => _source = stateManager,
                fixedLeftColumns: 2,
                columns: columns,
                fetchData: fetchPayrollTypes,
                showCheckboxColumn: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
