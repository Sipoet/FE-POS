import 'package:fe_pos/model/discount.dart';
import 'package:fe_pos/page/discount_form_page.dart';
import 'package:fe_pos/page/discount_mass_upload_page.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_data_table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class DiscountPage extends StatefulWidget {
  const DiscountPage({super.key});

  @override
  State<DiscountPage> createState() => _DiscountPageState();
}

class _DiscountPageState extends State<DiscountPage> {
  final _source = CustomDataTableSource();
  late final SessionState _sessionState;
  bool _isDisplayTable = false;
  String _searchText = '';
  List<Discount> discounts = [];
  final cancelToken = CancelToken();
  late Flash flash;

  // @override
  // bool get wantKeepAlive => true;

  @override
  void initState() {
    _sessionState = context.read<SessionState>();
    flash = Flash(context);
    final setting = context.read<Setting>();
    _source.columns = setting.tableColumn('discount');
    refreshTable();
    super.initState();
  }

  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  Future<void> refreshTable() async {
    // clear table row
    setState(() {
      discounts = [];
      _isDisplayTable = false;
    });
    fetchDiscounts(page: 1);
  }

  Future fetchDiscounts({int page = 1}) {
    var server = _sessionState.server;
    String orderKey = _source.sortColumn ?? 'code';
    try {
      return server
          .get('discounts',
              queryParam: {
                'search_text': _searchText,
                'page': page.toString(),
                'per': '100',
                'order_key': orderKey,
                'is_order_asc': _source.isAscending.toString(),
              },
              cancelToken: cancelToken)
          .then((response) {
        if (response.statusCode != 200) {
          throw 'error: ${response.data.toString()}';
        }
        Map responseBody = response.data;
        if (responseBody['data'] is! List) {
          throw 'error: invalid data type ${response.data.toString()}';
        }
        discounts.addAll(responseBody['data']
            .map<Discount>((json) => Discount.fromJson(json))
            .toList());
        setState(() {
          _isDisplayTable = true;
          _source.setData(discounts);
        });

        flash.hide();
        int totalPages = responseBody['meta']?['total_pages'];
        if (page < totalPages.toInt()) {
          fetchDiscounts(page: page + 1);
        }
      },
              onError: (error, stackTrace) => server.defaultErrorResponse(
                  context: context, error: error, valueWhenError: []));
    } catch (e, trace) {
      flash.showBanner(
          title: e.toString(),
          description: trace.toString(),
          messageType: MessageType.failed);
      return Future(() => null);
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
    setState(() {
      tabManager.addTab('Edit Discount ${discount.code}',
          DiscountFormPage(key: ObjectKey(discount), discount: discount));
    });
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
    _sessionState.server.delete("discounts/${discount.id}").then((response) {
      if (response.statusCode == 200) {
        flash.showBanner(
            messageType: MessageType.success,
            description: response.data?['message']);
        refreshTable();
      } else if (response.statusCode == 409) {
        var data = response.data;
        flash.showBanner(
            title: data['message'],
            description: data['errors'].join('\n'),
            messageType: MessageType.failed);
      }
    }, onError: (error, stack) {
      _sessionState.server.defaultErrorResponse(context: context, error: error);
    });
  }

  void refreshPromotion(Discount discount) {
    var server = _sessionState.server;
    server.post('discounts/${discount.id}/refresh_promotion').then((value) {
      flash.showBanner(
          title: 'Refresh akan diproses',
          description: 'diskon ${discount.code} akan diproses',
          messageType: MessageType.info,
          duration: const Duration(seconds: 3));
    }, onError: (error, stack) {
      server.defaultErrorResponse(context: context, error: error);
    });
  }

  void refreshAllPromotion() {
    var server = _sessionState.server;
    server.post('discounts/refresh_all_promotion').then((value) {
      flash.showBanner(
          title: 'Refresh akan diproses',
          description: 'Semua diskon akan diproses',
          messageType: MessageType.info,
          duration: const Duration(seconds: 3));
    }, onError: (error, stack) {
      server.defaultErrorResponse(context: context, error: error);
    });
  }

  void deleteAllOldDiscount() {
    var server = _sessionState.server;
    server.delete('discounts/delete_inactive_past_discount').then((response) {
      flash.showBanner(
          title: response.data['message'],
          description: 'Semua diskon akan diproses',
          messageType: MessageType.success);
      refreshTable();
    }, onError: (error, stack) {
      server.defaultErrorResponse(context: context, error: error);
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
    // super.build(context);
    _source.actionButtons = (discount) => [
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
        ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
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
                      child: const Text('Tambah Diskon'),
                      onPressed: () => addForm(),
                    ),
                    MenuItemButton(
                      child: const Text('Refresh Semua promosi'),
                      onPressed: () => refreshAllPromotion(),
                    ),
                    MenuItemButton(
                      child: const Text('Hapus Semua Diskon lama'),
                      onPressed: () => deleteAllOldDiscount(),
                    ),
                    MenuItemButton(
                      child: const Text('Mass Upload'),
                      onPressed: () => massUploadDiscount(),
                    ),
                  ], child: const Icon(Icons.table_rows_rounded))
                ],
              ),
            ),
            if (_isDisplayTable)
              SizedBox(
                height: 600,
                child: CustomDataTable(
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
