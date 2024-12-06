import 'package:fe_pos/model/payslip.dart';
import 'package:fe_pos/page/payslip_form_page.dart';
import 'package:fe_pos/page/generate_payslip_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class PayslipPage extends StatefulWidget {
  const PayslipPage({super.key});

  @override
  State<PayslipPage> createState() => _PayslipPageState();
}

class _PayslipPageState extends State<PayslipPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  late final CustomAsyncDataTableSource<Payslip> _source;
  late final Server server;
  String _searchText = '';
  List<Payslip> payslips = [];
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
    _source = CustomAsyncDataTableSource<Payslip>(
        columns: setting.tableColumn('payslip'), fetchData: fetchPayslips);
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

  Future<ResponseResult<Payslip>> fetchPayslips(
      {int page = 1,
      int limit = 100,
      TableColumn? sortColumn,
      bool isAscending = true}) {
    String orderKey = sortColumn?.sortKey ?? 'id';
    Map<String, dynamic> param = {
      'search_text': _searchText,
      'page[page]': page.toString(),
      'page[limit]': limit.toString(),
      'include': 'payroll,employee',
      'sort': "${isAscending ? '' : '-'}$orderKey",
    };
    _filter.forEach((key, value) {
      param[key] = value;
    });
    try {
      return server
          .get('payslips', queryParam: param, cancelToken: cancelToken)
          .then((response) {
        if (response.statusCode != 200) {
          throw 'error: ${response.data.toString()}';
        }
        Map responseBody = response.data;
        if (responseBody['data'] is! List) {
          throw 'error: invalid data type ${response.data.toString()}';
        }
        final models = responseBody['data']
            .map<Payslip>((json) =>
                Payslip.fromJson(json, included: responseBody['included']))
            .toList();

        int totalRows =
            responseBody['meta']?['total_rows'] ?? responseBody['data'].length;
        return ResponseResult<Payslip>(models: models, totalRows: totalRows);
      },
              onError: (error, stackTrace) =>
                  defaultErrorResponse(error: error, valueWhenError: []));
    } catch (e, trace) {
      flash.showBanner(
          title: e.toString(),
          description: trace.toString(),
          messageType: ToastificationType.error);
      return Future(() => ResponseResult<Payslip>(models: []));
    }
  }

  void generatePayslip() {
    final tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab('Generate Slip Gaji',
          const GeneratePayslipFormPage(key: ObjectKey('Generate Payslip')));
    });
  }

  void editForm(Payslip payslip) {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab('Edit SLip Gaji ${payslip.id}',
          PayslipFormPage(key: ObjectKey(payslip), payslip: payslip));
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

  void destroyRecord(Payslip payslip) {
    showConfirmDialog(
        message: 'Apakah anda yakin hapus ${payslip.id}?',
        onSubmit: () {
          server.delete('/payslips/${payslip.id}').then((response) {
            if (response.statusCode == 200) {
              flash.showBanner(
                  messageType: ToastificationType.success,
                  title: 'Sukses Hapus',
                  description: 'Sukses Hapus Slip Gaji ${payslip.id}');
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

  void cancelPayslip(Payslip payslip) {}

  void confirmPayslip(Payslip payslip) {}
  void payPayslip(Payslip payslip) {}

  void actionSelected(void Function(Payslip) action) {
    for (Payslip payslip in _source.selected) {
      action(payslip);
    }
  }

  final menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _source.actionButtons = ((payslip, index) => <Widget>[
          IconButton(
              onPressed: () {
                editForm(payslip);
              },
              tooltip: 'Edit Slip Gaji',
              icon: const Icon(Icons.edit)),
          IconButton(
              onPressed: () {
                destroyRecord(payslip);
              },
              tooltip: 'Hapus Slip Gaji',
              icon: const Icon(Icons.delete)),
        ]);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          children: [
            TableFilterForm(
              columns: _source.columns,
              enums: const {'status': PayslipStatus.values},
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
                        controller: menuController,
                        onHover: (isHover) {
                          if (isHover) {
                            menuController.close();
                          }
                        },
                        menuChildren: [
                          MenuItemButton(
                            child: const Text('Cancel Slip Gaji'),
                            onPressed: () {
                              menuController.close();
                              actionSelected(cancelPayslip);
                            },
                          ),
                          MenuItemButton(
                            child: const Text('confirm Slip Gaji'),
                            onPressed: () {
                              menuController.close();
                              actionSelected(confirmPayslip);
                            },
                          ),
                          MenuItemButton(
                            child: const Text('pay Slip Gaji'),
                            onPressed: () {
                              menuController.close();
                              actionSelected(payPayslip);
                            },
                          ),
                          MenuItemButton(
                            child: const Text('Generate Slip Gaji'),
                            onPressed: () {
                              menuController.close();
                              generatePayslip();
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
