import 'package:fe_pos/model/discount.dart';
import 'package:fe_pos/page/discount_form_page.dart';
import 'package:fe_pos/page/discount_mass_upload_page.dart';
import 'package:fe_pos/tool/datatable.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:data_table_2/data_table_2.dart';

class DiscountPage extends StatefulWidget {
  const DiscountPage({super.key});

  @override
  State<DiscountPage> createState() => _DiscountPageState();
}

class _DiscountPageState extends State<DiscountPage> {
  final DiscountDatatableSource _source = DiscountDatatableSource();
  late final SessionState _sessionState;
  late final List<String> _columnOrder;
  List<DataColumn2> _columns = [];
  double _tableWidth = 50.0;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  bool _isDisplayTable = false;
  String _searchText = '';
  List<Discount> discounts = [];
  Future? requestController;
  late Flash flash;
  @override
  void initState() {
    _sessionState = context.read<SessionState>();
    flash = Flash(context);
    refreshTable();
    super.initState();
  }

  @override
  void dispose() {
    if (requestController != null) {
      requestController?.ignore();
    }

    super.dispose();
  }

  Future<void> _fetchTableColumn() async {
    Setting setting = context.read<Setting>();
    List columnNames = setting.columnNames('discount');
    _columnOrder = setting.columnOrder('discount');
    _source.setKeys(_columnOrder);
    _columns = [];
    _tableWidth = 50.0;
    setState(() {
      for (String columnName in columnNames) {
        _tableWidth += 215.0;
        _columns.add(DataColumn2(
          tooltip: columnName,
          fixedWidth: 215.0,
          onSort: ((columnIndex, ascending) {
            setState(() {
              _sortColumnIndex = columnIndex;
              _sortAscending = ascending;
            });
            _source.sortData(_columnOrder[_sortColumnIndex], _sortAscending);
          }),
          label: Text(
            columnName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ));
      }
      _tableWidth += 250.0;
      _columns.add(const DataColumn2(
          label: Text(
            'Action',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          fixedWidth: 250.0));
    });
  }

  Future<void> refreshTable() async {
    if (_columns.isEmpty) {
      await _fetchTableColumn();
    } else {
      flash.show(const Text("Sedang proses."), MessageType.info);
    }
    discounts = []; // clear table row
    setState(() {
      _isDisplayTable = false;
    });
    requestController = fetchDiscounts(page: 1);
  }

  Future fetchDiscounts({int page = 1}) {
    var server = _sessionState.server;
    String orderKey = _columnOrder[_sortColumnIndex];
    try {
      return server.get('discounts', queryParam: {
        'search_text': _searchText,
        'page': page.toString(),
        'per': '100',
        'order_key': orderKey,
        'is_order_asc': _sortAscending.toString(),
      }).then((response) {
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
          _source.setData(discounts, orderKey, _sortAscending);
          _isDisplayTable = true;
        });
        flash.hide();
        int totalPages = responseBody['meta']?['total_pages'];
        if (page < totalPages.toInt()) {
          requestController = fetchDiscounts(page: page + 1);
        } else {
          requestController = null;
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
          messageType: MessageType.info);
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
          messageType: MessageType.info);
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

  @override
  Widget build(BuildContext context) {
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
                      onChanged: (value) {
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
                      },
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
                child: PaginatedDataTable2(
                  columns: _columns,
                  source: _source,
                  minWidth: _tableWidth,
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  fixedLeftColumns: 1,
                  border: TableBorder.all(
                      width: 1, color: Colors.black45.withOpacity(0.3)),
                  sortArrowAlwaysVisible: false,
                  empty: const Text('Data tidak ditemukan'),
                  headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                    return Colors.blueAccent.withOpacity(0.2);
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DiscountDatatableSource extends Datatable {}
