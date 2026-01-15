import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/payment_provider.dart';
import 'package:fe_pos/page/payment_provider_form_page.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/widget/table_filter_form.dart';

class PaymentProviderPage extends StatefulWidget {
  const PaymentProviderPage({super.key});

  @override
  State<PaymentProviderPage> createState() => _PaymentProviderPageState();
}

class _PaymentProviderPageState extends State<PaymentProviderPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final TrinaGridStateManager _source;
  late final Server server;
  late final Setting setting;

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
    setting = context.read<Setting>();
    columns = setting.tableColumn('paymentProvider');
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

  Future<DataTableResponse<PaymentProvider>> fetchPaymentProviders(
    QueryRequest request,
  ) {
    request.filters = _filters;
    request.searchText = _searchText;
    return PaymentProviderClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<PaymentProvider>(
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
    PaymentProvider paymentProvider = PaymentProvider();

    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'Tipe Pembayaran Baru',
        PaymentProviderFormPage(
          key: ObjectKey(paymentProvider),
          paymentProvider: paymentProvider,
        ),
      );
    });
  }

  void editForm(PaymentProvider paymentProvider) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'Edit Tipe Pembayaran ${paymentProvider.name}',
        PaymentProviderFormPage(
          key: ObjectKey(paymentProvider),
          paymentProvider: paymentProvider,
        ),
      );
    });
  }

  void destroyRecord(PaymentProvider paymentProvider) {
    showConfirmDialog(
      message: 'Apakah anda yakin hapus ${paymentProvider.name}?',
      onSubmit: () {
        server
            .delete('/payment_providers/${paymentProvider.id}')
            .then(
              (response) {
                if (response.statusCode == 200) {
                  flash.showBanner(
                    messageType: ToastificationType.success,
                    title: 'Sukses Hapus',
                    description:
                        'Sukses Hapus paymentProvider ${paymentProvider.name}',
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

    return VerticalBodyScroll(
      child: Column(
        children: [
          TableFilterForm(
            columns: columns,
            enums: const {'status': PaymentProviderStatus.values},
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
                    decoration: const InputDecoration(hintText: 'Search Text'),
                    onChanged: searchChanged,
                    onSubmitted: searchChanged,
                  ),
                ),
                if (setting.isAuthorize('payment_providers', 'create'))
                  SizedBox(
                    width: 50,
                    child: SubmenuButton(
                      menuChildren: [
                        MenuItemButton(
                          child: const Text('Tambah Payment Provider'),
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
            child: CustomAsyncDataTable<PaymentProvider>(
              renderAction: (paymentProvider) => Row(
                spacing: 10,
                children: [
                  if (setting.isAuthorize('payment_providers', 'update'))
                    IconButton(
                      onPressed: () {
                        editForm(paymentProvider);
                      },
                      tooltip: 'Edit Payment Provider',
                      icon: const Icon(Icons.edit),
                    ),
                  if (setting.isAuthorize('payment_providers', 'destroy'))
                    IconButton(
                      onPressed: () {
                        destroyRecord(paymentProvider);
                      },
                      tooltip: 'Hapus Payment Provider',
                      icon: const Icon(Icons.delete),
                    ),
                ],
              ),
              onLoaded: (stateManager) => _source = stateManager,
              columns: columns,
              fetchData: fetchPaymentProviders,
              fixedLeftColumns: 2,
            ),
          ),
        ],
      ),
    );
  }
}
