import 'package:fe_pos/model/payroll.dart';
import 'package:fe_pos/page/payroll_form_page.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_data_table.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class PayrollPage extends StatefulWidget {
  const PayrollPage({super.key});

  @override
  State<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends State<PayrollPage>
    with AutomaticKeepAliveClientMixin {
  final _source = CustomDataTableSource<Payroll>();
  late final Server server;
  bool _isDisplayTable = false;
  String _searchText = '';
  List<Payroll> payrolls = [];
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
    _source.columns = setting.tableColumn('payroll');
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
      payrolls = [];
      _isDisplayTable = false;
    });
    fetchPayrolls(page: 1);
  }

  Future fetchPayrolls({int page = 1}) {
    String orderKey = _source.sortColumn?.sortKey ?? 'name';
    Map<String, dynamic> param = {
      'search_text': _searchText,
      'page[page]': page.toString(),
      'page[limit]': '100',
      'sort': '${_source.isAscending ? '' : '-'}$orderKey',
    };
    _filter.forEach((key, value) {
      param[key] = value;
    });
    try {
      return server
          .get('payrolls', queryParam: param, cancelToken: cancelToken)
          .then((response) {
        if (response.statusCode != 200) {
          throw 'error: ${response.data.toString()}';
        }
        Map responseBody = response.data;
        if (responseBody['data'] is! List) {
          throw 'error: invalid data type ${response.data.toString()}';
        }
        payrolls.addAll(responseBody['data']
            .map<Payroll>((json) => Payroll.fromJson(json))
            .toList());
        setState(() {
          _isDisplayTable = true;
          _source.setData(payrolls);
        });

        flash.hide();
        int totalPages = responseBody['meta']?['total_pages'];
        if (page < totalPages.toInt()) {
          fetchPayrolls(page: page + 1);
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
    Payroll payroll = Payroll(name: '', lines: []);

    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab('New Payroll',
          PayrollFormPage(key: ObjectKey(payroll), payroll: payroll));
    });
  }

  void editForm(Payroll payroll) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab('Edit Payroll ${payroll.name}',
          PayrollFormPage(key: ObjectKey(payroll), payroll: payroll));
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

  void destroyRecord(Payroll payroll) {
    showConfirmDialog(
        message: 'Apakah anda yakin hapus ${payroll.name}?',
        onSubmit: () {
          server.delete('/payrolls/${payroll.id}').then((response) {
            if (response.statusCode == 200) {
              flash.showBanner(
                  messageType: MessageType.success,
                  title: 'Sukses Hapus',
                  description: 'Sukses Hapus payroll ${payroll.name}');
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
    _source.setActionButtons((payroll, index) => <Widget>[
          IconButton(
              onPressed: () {
                editForm(payroll);
              },
              tooltip: 'Edit Payroll',
              icon: const Icon(Icons.edit)),
          IconButton(
              onPressed: () {
                destroyRecord(payroll);
              },
              tooltip: 'Hapus Payroll',
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
                  SubmenuButton(menuChildren: [
                    MenuItemButton(
                      child: const Text('Tambah Payroll'),
                      onPressed: () => addForm(),
                    ),
                  ], child: const Icon(Icons.table_rows_rounded))
                ],
              ),
            ),
            Visibility(
              visible: _isDisplayTable,
              child: SizedBox(
                height: 600,
                width: 825,
                child: CustomDataTable(
                  controller: _source,
                  fixedLeftColumns: 2,
                  showCheckboxColumn: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
