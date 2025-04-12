import 'package:fe_pos/model/payslip.dart';
import 'package:fe_pos/page/payslip_form_page.dart';
import 'package:fe_pos/page/generate_payslip_form_page.dart';
import 'package:fe_pos/page/payslip_pay_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/file_saver.dart';
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
    String orderKey = sortColumn?.name ?? 'id';
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

  void cancelPayslip(Payslip payslip) {
    server.post('payslips/${payslip.id.toString()}/cancel').then((response) {
      if (response.statusCode == 200) {
        flash.show(
            Text('Berhasil Cancel slip gaji'), ToastificationType.success);
        _source.refreshDatasource();
        return;
      }
      flash.show(Text('Gagal Cancel slip gaji'), ToastificationType.error);
    }, onError: (error) {
      defaultErrorResponse(error: error);
    });
  }

  void confirmPayslip(Payslip payslip) {
    server.post('payslips/${payslip.id.toString()}/confirm').then((response) {
      if (response.statusCode == 200) {
        flash.show(
            Text('Berhasil Confirm slip gaji'), ToastificationType.success);
        _source.refreshDatasource();
        return;
      }
      flash.show(Text('Gagal Confirm slip gaji'), ToastificationType.error);
    }, onError: (error) {
      defaultErrorResponse(error: error);
    });
  }

  void payPayslip() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pembayaran Slip Gaji'),
              IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close)),
            ],
          ),
          contentPadding: EdgeInsets.all(10),
          content: PayslipPayPage(
            isModal: true,
          ),
        );
      },
    );
  }

  void actionSelected(void Function(Payslip) action) {
    for (Payslip payslip in _source.selected) {
      action(payslip);
    }
  }

  void download(Payslip payslip) async {
    server.get('payslips/${payslip.id.toString()}/download', type: 'file').then(
        (response) async {
      String filename = response.headers.value('content-disposition') ?? '';
      if (filename.isEmpty) {
        return;
      }
      filename = filename.substring(
          filename.indexOf('filename="') + 10, filename.indexOf('pdf";') + 3);

      var downloader = const FileSaver();
      downloader.download(filename, response.data, 'pdf',
          onSuccess: (String path) {
        flash.showBanner(
            messageType: ToastificationType.success,
            title: 'Sukses download',
            duration: Durations.short1,
            description: 'sukses disimpan di $path');
      });
    }, onError: (error) => defaultErrorResponse(error: error));
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
                download(payslip);
              },
              tooltip: 'Download Slip Gaji',
              icon: const Icon(Icons.download)),
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
                              payPayslip();
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
              height: bodyScreenHeight,
              child: CustomAsyncDataTable(
                controller: _source,
                fixedLeftColumns: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
