import 'package:fe_pos/model/discount.dart';
import 'package:fe_pos/page/discount_form_page.dart';
import 'package:fe_pos/page/discount_mass_upload_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class DiscountPage extends StatefulWidget {
  const DiscountPage({super.key});

  @override
  State<DiscountPage> createState() => _DiscountPageState();
}

class _DiscountPageState extends State<DiscountPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse, LoadingPopup {
  late final Server server;
  String _searchText = '';
  final cancelToken = CancelToken();
  late Flash flash;
  Map _filter = {};
  final _controller = MenuController();
  late final CustomAsyncDataTableSource<Discount> _source;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    final setting = context.read<Setting>();
    _source = CustomAsyncDataTableSource<Discount>(
        columns: setting.tableColumn('discount'), fetchData: fetchDiscounts);
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
    // clear table row
    _source.refreshDataFromFirstPage();
  }

  Future<ResponseResult<Discount>> fetchDiscounts({
    int page = 1,
    int limit = 100,
    TableColumn? sortColumn,
    bool isAscending = true,
  }) {
    String orderKey = sortColumn?.sortKey ?? 'code';
    Map<String, dynamic> param = {
      'search_text': _searchText,
      'page[page]': page.toString(),
      'page[limit]': limit.toString(),
      'include':
          'discount_items,discount_suppliers,discount_item_types,discount_brands',
      'sort': '${isAscending ? '' : '-'}$orderKey',
    };
    _filter.forEach((key, value) {
      param[key] = value;
    });
    try {
      return server
          .get('discounts', queryParam: param, cancelToken: cancelToken)
          .then((response) {
        if (response.statusCode != 200) {
          throw 'error: ${response.data.toString()}';
        }
        Map responseBody = response.data;
        if (responseBody['data'] is! List) {
          throw 'error: invalid data type ${response.data.toString()}';
        }
        final models = responseBody['data']
            .map<Discount>((json) => Discount.fromJson(json))
            .toList();
        int totalRows =
            responseBody['meta']?['total_rows'] ?? responseBody['data'].length;
        return ResponseResult<Discount>(totalRows: totalRows, models: models);
      },
              onError: (error, stackTrace) =>
                  defaultErrorResponse(error: error, valueWhenError: []));
    } catch (e, trace) {
      flash.showBanner(
          title: e.toString(),
          description: trace.toString(),
          messageType: ToastificationType.error);

      return Future(() => ResponseResult<Discount>(models: []));
    }
  }

  void addForm() {
    Discount discount = Discount(
        discount1: const Percentage(0.0),
        discount2: const Percentage(0.0),
        discount3: const Percentage(0.0),
        discount4: const Percentage(0.0),
        calculationType: DiscountCalculationType.percentage,
        startTime: DateTime.now().copyWith(hour: 0, minute: 0, second: 0),
        endTime: DateTime.now().copyWith(hour: 23, minute: 59, second: 59));
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab('New Discount',
          DiscountFormPage(key: ObjectKey(discount), discount: discount));
    });
  }

  void editForm(Discount discount) {
    var tabManager = context.read<TabManager>();
    tabManager.addTab('Edit Discount ${discount.code}',
        DiscountFormPage(key: ObjectKey(discount), discount: discount));
  }

  void showConfirmDeleteDialog(discount) {
    AlertDialog alert = AlertDialog(
      title: const Text("Konfirmasi"),
      content: Text("apakah yakin menghapus diskon ${discount.code} ?"),
      actions: [
        ElevatedButton(
          child: const Text("Kembali"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: const Text("Hapus"),
          onPressed: () {
            deleteRecord(discount);
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

  void deleteRecord(discount) {
    server.delete("discounts/${discount.id}").then((response) {
      if (response.statusCode == 200) {
        flash.showBanner(
            messageType: ToastificationType.success,
            description: response.data?['message']);
        refreshTable();
      } else if (response.statusCode == 409) {
        var data = response.data;
        flash.showBanner(
            title: data['message'],
            description: data['errors'].join('\n'),
            messageType: ToastificationType.error);
      }
    }, onError: (error, stack) {
      defaultErrorResponse(error: error);
    });
  }

  void refreshPromotion(Discount discount) {
    server.post('discounts/${discount.id}/refresh_promotion').then((value) {
      flash.showBanner(
          title: 'Refresh akan diproses',
          description: 'diskon ${discount.code} akan diproses',
          messageType: ToastificationType.info,
          duration: const Duration(seconds: 3));
    }, onError: (error, stack) {
      defaultErrorResponse(error: error);
    });
  }

  void refreshAllPromotion() {
    server.post('discounts/refresh_all_promotion').then((value) {
      flash.showBanner(
          title: 'Refresh akan diproses',
          description: 'Semua diskon akan diproses',
          messageType: ToastificationType.info,
          duration: const Duration(seconds: 3));
    }, onError: (error, stack) {
      defaultErrorResponse(error: error);
    });
  }

  void deleteAllOldDiscount() {
    server.delete('discounts/delete_inactive_past_discount').then((response) {
      flash.showBanner(
          title: response.data['message'],
          description: 'Semua diskon akan diproses',
          messageType: ToastificationType.success);
      refreshTable();
    }, onError: (error, stack) {
      defaultErrorResponse(error: error);
    });
  }

  void massUploadDiscount() {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab('Mass Upload Diskon', const DiscountMassUploadPage());
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
    _source.actionButtons = ((discount, index) => [
          IconButton(
              onPressed: () {
                editForm(discount);
              },
              tooltip: 'Edit diskon',
              icon: const Icon(Icons.edit)),
          IconButton(
              onPressed: () {
                refreshPromotion(discount);
              },
              tooltip: 'Refresh item promotion',
              icon: const Icon(Icons.refresh)),
          IconButton(
              onPressed: () {
                showConfirmDeleteDialog(discount);
              },
              tooltip: 'Hapus diskon',
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
                'calculation_type': DiscountCalculationType.values,
                'discount_type': DiscountType.values
              },
              onSubmit: (value) {
                _filter = value;
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
                        controller: _controller,
                        menuChildren: [
                          MenuItemButton(
                            child: const Text('Tambah Diskon'),
                            onPressed: () {
                              _controller.close();
                              addForm();
                            },
                          ),
                          MenuItemButton(
                            child: const Text('Refresh Semua promosi'),
                            onPressed: () {
                              _controller.close();
                              refreshAllPromotion();
                            },
                          ),
                          MenuItemButton(
                            child: const Text('Hapus Semua Diskon lama'),
                            onPressed: () {
                              _controller.close();
                              deleteAllOldDiscount();
                            },
                          ),
                          MenuItemButton(
                            child: const Text('Mass Upload'),
                            onPressed: () {
                              _controller.close();
                              massUploadDiscount();
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
                fixedLeftColumns: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
