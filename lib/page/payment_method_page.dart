import 'package:fe_pos/tool/default_response.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/model/payment_method.dart';
import 'package:fe_pos/page/payment_method_form_page.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/tab_manager.dart';

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({super.key});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final PlutoGridStateManager _source;
  late final Server server;
  String _searchText = '';
  final cancelToken = CancelToken();
  late Flash flash;
  final _menuController = MenuController();
  List<FilterData> _filters = [];
  List<TableColumn> columns = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    final setting = context.read<Setting>();
    columns = setting.tableColumn('paymentMethod');

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

  Future<DataTableResponse<PaymentMethod>> fetchPaymentMethods(
      QueryRequest request) {
    request.filters = _filters;
    request.searchText = _searchText;
    return PaymentMethodClass().finds(server, request).then(
        (value) => DataTableResponse<PaymentMethod>(
            models: value.models,
            totalPage: value.metadata['total_pages']), onError: (error) {
      defaultErrorResponse(error: error);
      return DataTableResponse.empty();
    });
  }

  void addForm() {
    PaymentMethod paymentMethod = PaymentMethod();
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
          'Tambah Metode Pembayaran',
          PaymentMethodFormPage(
              key: ObjectKey(paymentMethod), paymentMethod: paymentMethod));
    });
  }

  void editForm(PaymentMethod paymentMethod) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
          'Edit Metode Pembayaran ${paymentMethod.name}',
          PaymentMethodFormPage(
              key: ObjectKey(paymentMethod), paymentMethod: paymentMethod));
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

  List<Widget> actionButtons(PaymentMethod paymentMethod, int index) {
    return <Widget>[
      IconButton(
          onPressed: () {
            editForm(paymentMethod);
          },
          tooltip: 'Edit Metode Pembayaran',
          icon: const Icon(Icons.edit)),
    ];
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
              enums: const {
                'payment_type': PaymentType.values,
              },
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
                      decoration:
                          const InputDecoration(hintText: 'Search Text'),
                      onChanged: searchChanged,
                      onSubmitted: searchChanged,
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: SubmenuButton(
                        controller: _menuController,
                        menuChildren: [
                          MenuItemButton(
                            child: const Text('Tambah Metode Pembayaran'),
                            onPressed: () {
                              _menuController.close();
                              addForm();
                            },
                          ),
                        ],
                        child: const Icon(Icons.table_rows_rounded)),
                  )
                ],
              ),
            ),
            SizedBox(
              height: bodyScreenHeight,
              child: CustomAsyncDataTable2<PaymentMethod>(
                renderAction: (paymentMethod) => IconButton(
                    onPressed: () {
                      editForm(paymentMethod);
                    },
                    tooltip: 'Edit Metode Pembayaran',
                    icon: const Icon(Icons.edit)),
                onLoaded: (stateManager) => _source = stateManager,
                columns: columns,
                fetchData: fetchPaymentMethods,
                showCheckboxColumn: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
