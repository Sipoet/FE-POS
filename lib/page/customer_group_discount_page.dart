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
  late final TrinaGridStateManager _source;
  late final Server server;
  final _menuController = MenuController();
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
    final setting = context.read<Setting>();
    columns = setting.tableColumn('customerGroupDiscount');

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

  Future<DataTableResponse<CustomerGroupDiscount>> fetchCustomerGroupDiscounts(
      QueryRequest request) {
    request.filters = _filters;
    request.searchText = _searchText;
    return CustomerGroupDiscountClass().finds(server, request).then(
        (value) => DataTableResponse<CustomerGroupDiscount>(
            models: value.models,
            totalPage: value.metadata['total_pages']), onError: (error) {
      defaultErrorResponse(error: error);
      return DataTableResponse.empty();
    });
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
              height: bodyScreenHeight,
              width: 900,
              child: CustomAsyncDataTable<CustomerGroupDiscount>(
                renderAction: (customerGroupDiscount) => Row(
                  spacing: 10,
                  children: [
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
                  ],
                ),
                columns: columns,
                onLoaded: (stateManager) => _source = stateManager,
                fetchData: fetchCustomerGroupDiscounts,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
