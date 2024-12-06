import 'package:fe_pos/tool/default_response.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/customer_group_discount.dart';
import 'package:fe_pos/page/customer_group_discount_form_page.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/widget/table_filter_form.dart';

class CustomerGroupDiscountPage extends StatefulWidget {
  const CustomerGroupDiscountPage({super.key});

  @override
  State<CustomerGroupDiscountPage> createState() =>
      _CustomerGroupDiscountPageState();
}

class _CustomerGroupDiscountPageState extends State<CustomerGroupDiscountPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final CustomAsyncDataTableSource<CustomerGroupDiscount> _source;
  late final Server server;
  final _menuController = MenuController();
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
    _source = CustomAsyncDataTableSource<CustomerGroupDiscount>(
        columns: setting.tableColumn('customerGroupDiscount'),
        fetchData: fetchCustomerGroupDiscounts);
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

  Future<ResponseResult<CustomerGroupDiscount>> fetchCustomerGroupDiscounts(
      {int page = 1,
      int limit = 100,
      TableColumn? sortColumn,
      bool isAscending = true}) {
    String orderKey = sortColumn?.sortKey ?? 'tbl_supelgrup.grup';
    Map<String, dynamic> param = {
      'search_text': _searchText,
      'page[page]': page.toString(),
      'page[limit]': limit.toString(),
      'include': 'customer_group',
      'sort': '${isAscending ? '' : '-'}$orderKey',
    };
    _filter.forEach((key, value) {
      param[key] = value;
    });

    return server
        .get('customer_group_discounts',
            queryParam: param, cancelToken: cancelToken)
        .then((response) {
      if (response.statusCode != 200) {
        throw 'error: ${response.data.toString()}';
      }
      try {
        Map responseBody = response.data;
        if (responseBody['data'] is! List) {
          throw 'error: invalid data type ${response.data.toString()}';
        }
        final models = responseBody['data']
            .map<CustomerGroupDiscount>((json) =>
                CustomerGroupDiscount.fromJson(json,
                    included: responseBody['included']))
            .toList();
        int totalRows =
            responseBody['meta']?['total_rows'] ?? responseBody['data'].length;
        return ResponseResult<CustomerGroupDiscount>(
            models: models, totalRows: totalRows);
      } catch (e, trace) {
        flash.showBanner(
            title: e.toString(),
            description: trace.toString(),
            messageType: ToastificationType.error);
        return Future(() => ResponseResult<CustomerGroupDiscount>(models: []));
      }
    },
            onError: (error, stackTrace) =>
                defaultErrorResponse(error: error, valueWhenError: []));
  }

  void addForm() {
    CustomerGroupDiscount customerGroupDiscount = CustomerGroupDiscount();

    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
          'Tambah Customer Group Discount',
          CustomerGroupDiscountFormPage(
              key: ObjectKey(customerGroupDiscount),
              customerGroupDiscount: customerGroupDiscount));
    });
  }

  void editForm(CustomerGroupDiscount customerGroupDiscount) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
          'Edit Customer Group Discount ${customerGroupDiscount.id}',
          CustomerGroupDiscountFormPage(
              key: ObjectKey(customerGroupDiscount),
              customerGroupDiscount: customerGroupDiscount));
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

  void destroyRecord(CustomerGroupDiscount customerGroupDiscount) {
    showConfirmDialog(
        message: 'Apakah anda yakin hapus ${customerGroupDiscount.id}?',
        onSubmit: () {
          server
              .delete('/customer_group_discounts/${customerGroupDiscount.id}')
              .then((response) {
            if (response.statusCode == 200) {
              flash.showBanner(
                  messageType: ToastificationType.success,
                  title: 'Sukses Hapus',
                  description:
                      'Sukses Hapus customer Group Discount ${customerGroupDiscount.id}');
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

  void toggleDiscount() {
    server.post('/customer_group_discounts/toggle_discount').then(
      (response) {
        if (response.statusCode == 200) {
          flash.show(const Text('Sedang diproses'), ToastificationType.info);
        } else {
          flash.show(const Text('Gagal diproses'), ToastificationType.error);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _source.actionButtons = ((customerGroupDiscount, index) => <Widget>[
          IconButton(
              onPressed: () {
                editForm(customerGroupDiscount);
              },
              tooltip: 'Edit CustomerGroupDiscount',
              icon: const Icon(Icons.edit)),
          IconButton(
              onPressed: () {
                destroyRecord(customerGroupDiscount);
              },
              tooltip: 'Hapus CustomerGroupDiscount',
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
                            child: const Text('Tambah Customer Group Discount'),
                            onPressed: () {
                              _menuController.close();
                              addForm();
                            },
                          ),
                          MenuItemButton(
                            child: const Text('Toggle Diskon'),
                            onPressed: () {
                              _menuController.close();
                              toggleDiscount();
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
              width: 900,
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
