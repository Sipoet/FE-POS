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
  late final CustomAsyncDataTableSource<PaymentMethod> _source;
  late final Server server;
  String _searchText = '';
  final cancelToken = CancelToken();
  late Flash flash;
  final _menuController = MenuController();
  Map _filter = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    final setting = context.read<Setting>();
    _source = CustomAsyncDataTableSource<PaymentMethod>(
        actionButtons: actionButtons,
        columns: setting.tableColumn('paymentMethod'),
        fetchData: fetchPaymentMethods);
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

  Future<ResponseResult<PaymentMethod>> fetchPaymentMethods(
      {int page = 1,
      int limit = 50,
      TableColumn? sortColumn,
      bool isAscending = true}) {
    String orderKey = sortColumn?.name ?? 'name';
    Map<String, dynamic> param = {
      'search_text': _searchText,
      'page[page]': page.toString(),
      'page[limit]': limit.toString(),
      'fields[bank]': 'kodebank,namabank',
      'include': 'bank',
      'sort': '${isAscending ? '' : '-'}$orderKey',
    };
    _filter.forEach((key, value) {
      param[key] = value;
    });
    try {
      return server
          .get('payment_methods', queryParam: param, cancelToken: cancelToken)
          .then((response) {
        if (response.statusCode != 200) {
          throw 'error: ${response.data.toString()}';
        }
        Map responseBody = response.data;
        if (responseBody['data'] is! List) {
          throw 'error: invalid data type ${response.data.toString()}';
        }
        final responsedModels = responseBody['data']
            .map<PaymentMethod>((json) => PaymentMethod.fromJson(json,
                included: responseBody['included']))
            .toList();
        setState(() {
          // _source.setData(employees);
        });
        int totalRows =
            responseBody['meta']?['total_rows'] ?? responseBody['data'].length;
        return ResponseResult<PaymentMethod>(
            totalRows: totalRows, models: responsedModels);
      },
              onError: (error, stackTrace) =>
                  defaultErrorResponse(error: error, valueWhenError: []));
    } catch (e, trace) {
      flash.showBanner(
          title: e.toString(),
          description: trace.toString(),
          messageType: ToastificationType.error);
      return Future(() => ResponseResult<PaymentMethod>(models: []));
    }
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

  void showConfirmDialog(
      {required Function onSubmit, String message = 'Apakah Anda Yakin'}) {
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
      // IconButton(
      //   onPressed: () {
      //     setState(() {
      //       toggleStatus(employee);
      //     });
      //   },
      //   tooltip: 'Aktivasi/deaktivasi karyawan',
      //   icon: Icon(
      //     Icons.lightbulb,
      //     color:
      //         employee.status == EmployeeStatus.active ? Colors.yellow : null,
      //   ),
      // )
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
              columns: _source.columns,
              enums: const {
                'payment_type': PaymentType.values,
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
              height: 600,
              child: CustomAsyncDataTable(
                controller: _source,
                showCheckboxColumn: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
