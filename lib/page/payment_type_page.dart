import 'package:fe_pos/tool/default_response.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/payment_type.dart';
import 'package:fe_pos/page/payment_type_form_page.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/widget/table_filter_form.dart';

class PaymentTypePage extends StatefulWidget {
  const PaymentTypePage({super.key});

  @override
  State<PaymentTypePage> createState() => _PaymentTypePageState();
}

class _PaymentTypePageState extends State<PaymentTypePage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final TrinaGridStateManager _source;
  late final Server server;
  late final Setting setting;

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
    setting = context.read<Setting>();

    columns = setting.tableColumn('paymentType');

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

  Future<DataTableResponse<PaymentType>> fetchPaymentTypes(
    QueryRequest request,
  ) {
    request.filters = _filters;

    return PaymentTypeClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<PaymentType>(
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
    PaymentType paymentType = PaymentType();

    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'Tipe Pembayaran Baru',
        PaymentTypeFormPage(
          key: ObjectKey(paymentType),
          paymentType: paymentType,
        ),
      );
    });
  }

  void editForm(PaymentType paymentType) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'Edit Tipe Pembayaran ${paymentType.name}',
        PaymentTypeFormPage(
          key: ObjectKey(paymentType),
          paymentType: paymentType,
        ),
      );
    });
  }

  void destroyRecord(PaymentType paymentType) {
    showConfirmDialog(
      message: 'Apakah anda yakin hapus ${paymentType.name}?',
      onSubmit: () {
        server
            .delete('/payment_types/${paymentType.id}')
            .then(
              (response) {
                if (response.statusCode == 200) {
                  flash.showBanner(
                    messageType: ToastificationType.success,
                    title: 'Sukses Hapus',
                    description: 'Sukses Hapus paymentType ${paymentType.name}',
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
                        if (setting.isAuthorize('payment_types', 'create'))
                          MenuItemButton(
                            child: const Text('Tambah PaymentType'),
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
              child: CustomAsyncDataTable<PaymentType>(
                renderAction: (paymentType) => Row(
                  spacing: 10,
                  children: [
                    if (setting.isAuthorize('payment_types', 'update'))
                      IconButton(
                        onPressed: () {
                          editForm(paymentType);
                        },
                        tooltip: 'Edit PaymentType',
                        icon: const Icon(Icons.edit),
                      ),
                    if (setting.isAuthorize('payment_types', 'destroy'))
                      IconButton(
                        onPressed: () {
                          destroyRecord(paymentType);
                        },
                        tooltip: 'Hapus PaymentType',
                        icon: const Icon(Icons.delete),
                      ),
                  ],
                ),
                onLoaded: (stateManager) => _source = stateManager,
                columns: columns,
                fetchData: fetchPaymentTypes,
                fixedLeftColumns: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
