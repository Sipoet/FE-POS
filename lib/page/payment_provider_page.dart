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
    with AutomaticKeepAliveClientMixin {
  late final CustomAsyncDataTableSource<PaymentProvider> _source;
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
    flash = Flash(context);
    final setting = context.read<Setting>();
    _source = CustomAsyncDataTableSource<PaymentProvider>(
        columns: setting.tableColumn('paymentProvider'),
        fetchData: fetchPaymentProviders);
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

  Future<ResponseResult<PaymentProvider>> fetchPaymentProviders(
      {int page = 1,
      int limit = 100,
      TableColumn? sortColumn,
      bool isAscending = true}) {
    String orderKey = sortColumn?.sortKey ?? 'name';
    Map<String, dynamic> param = {
      'search_text': _searchText,
      'page[page]': page.toString(),
      'page[limit]': limit.toString(),
      'sort': '${isAscending ? '' : '-'}$orderKey',
    };
    _filter.forEach((key, value) {
      param[key] = value;
    });

    return server
        .get('payment_providers', queryParam: param, cancelToken: cancelToken)
        .then((response) {
      try {
        if (response.statusCode != 200) {
          throw 'error: ${response.data.toString()}';
        }
        Map responseBody = response.data;
        if (responseBody['data'] is! List) {
          throw 'error: invalid data provider ${response.data.toString()}';
        }
        final models = responseBody['data']
            .map<PaymentProvider>((json) => PaymentProvider.fromJson(json,
                included: responseBody['included'] ?? []))
            .toList();
        int totalRows =
            responseBody['meta']?['total_rows'] ?? responseBody['data'].length;
        return ResponseResult<PaymentProvider>(
            models: models, totalRows: totalRows);
      } catch (e, trace) {
        flash.showBanner(
            title: e.toString(),
            description: trace.toString(),
            messageType: MessageType.failed);
        return Future(() => ResponseResult<PaymentProvider>(models: []));
      }
    },
            onError: (error, stackTrace) => server.defaultErrorResponse(
                context: context, error: error, valueWhenError: []));
  }

  void addForm() {
    PaymentProvider paymentProvider = PaymentProvider();

    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
          'Tipe Pembayaran Baru',
          PaymentProviderFormPage(
              key: ObjectKey(paymentProvider),
              paymentProvider: paymentProvider));
    });
  }

  void editForm(PaymentProvider paymentProvider) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
          'Edit Tipe Pembayaran ${paymentProvider.name}',
          PaymentProviderFormPage(
              key: ObjectKey(paymentProvider),
              paymentProvider: paymentProvider));
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

  void destroyRecord(PaymentProvider paymentProvider) {
    showConfirmDialog(
        message: 'Apakah anda yakin hapus ${paymentProvider.name}?',
        onSubmit: () {
          server.delete('/payment_providers/${paymentProvider.id}').then(
              (response) {
            if (response.statusCode == 200) {
              flash.showBanner(
                  messageType: MessageType.success,
                  title: 'Sukses Hapus',
                  description:
                      'Sukses Hapus paymentProvider ${paymentProvider.name}');
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _source.actionButtons = ((paymentProvider, index) => <Widget>[
          IconButton(
              onPressed: () {
                editForm(paymentProvider);
              },
              tooltip: 'Edit Payment Provider',
              icon: const Icon(Icons.edit)),
          IconButton(
              onPressed: () {
                destroyRecord(paymentProvider);
              },
              tooltip: 'Hapus Payment Provider',
              icon: const Icon(Icons.delete)),
        ]);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          children: [
            TableFilterForm(
              columns: _source.columns,
              enums: const {
                'status': PaymentProviderStatus.values,
              },
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
                  SubmenuButton(menuChildren: [
                    MenuItemButton(
                      child: const Text('Tambah Payment Provider'),
                      onPressed: () => addForm(),
                    ),
                  ], child: const Icon(Icons.table_rows_rounded))
                ],
              ),
            ),
            SizedBox(
              height: 600,
              width: 825,
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
