import 'package:fe_pos/model/discount.dart';
import 'package:fe_pos/page/discount_form_page.dart';
import 'package:fe_pos/page/discount_mass_upload_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/file_saver.dart';
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

  final cancelToken = CancelToken();
  late Flash flash;
  List<FilterData> _filters = [];
  List<TableColumn> columns = [];
  final _controller = MenuController();
  late final TableController _source;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    final setting = context.read<Setting>();
    columns = setting.tableColumn('discount');
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
    _source.refreshTable();
  }

  Future<DataTableResponse<Discount>> fetchDiscounts(QueryRequest request) {
    request.filters = _filters;

    return DiscountClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<Discount>(
            models: value.models,
            totalPage: value.metadata['total_pages'],
          ),
          onError: (error) {
            defaultErrorResponse(error: error);
            return DataTableResponse.empty();
          },
        );
  }

  void addForm() {
    Discount discount = Discount(
      discount1: const Percentage(0.0),
      discount2: const Percentage(0.0),
      discount3: const Percentage(0.0),
      discount4: const Percentage(0.0),
      calculationType: DiscountCalculationType.percentage,
      startTime: DateTime.now().copyWith(hour: 0, minute: 0, second: 0),
      endTime: DateTime.now().copyWith(hour: 23, minute: 59, second: 59),
    );
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab(
        'New Discount',
        DiscountFormPage(key: ObjectKey(discount), discount: discount),
      );
    });
  }

  void editForm(Discount discount) {
    var tabManager = context.read<TabManager>();
    tabManager.addTab(
      'Edit Discount ${discount.code}',
      DiscountFormPage(key: ObjectKey(discount), discount: discount),
    );
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
    server
        .delete("discounts/${discount.id}")
        .then(
          (response) {
            if (response.statusCode == 200) {
              flash.showBanner(
                messageType: ToastificationType.success,
                description: response.data?['message'],
              );
              refreshTable();
            } else if (response.statusCode == 409) {
              var data = response.data;
              flash.showBanner(
                title: data['message'],
                description: data['errors'].join('\n'),
                messageType: ToastificationType.error,
              );
            }
          },
          onError: (error, stack) {
            defaultErrorResponse(error: error);
          },
        );
  }

  void refreshPromotion(Discount discount) {
    server
        .post('discounts/${discount.id}/refresh_promotion')
        .then(
          (value) {
            flash.showBanner(
              title: 'Refresh akan diproses',
              description: 'diskon ${discount.code} akan diproses',
              messageType: ToastificationType.info,
              duration: const Duration(seconds: 3),
            );
          },
          onError: (error, stack) {
            defaultErrorResponse(error: error);
          },
        );
  }

  void refreshAllPromotion() {
    server
        .post('discounts/refresh_all_promotion')
        .then(
          (value) {
            flash.showBanner(
              title: 'Refresh akan diproses',
              description: 'Semua diskon akan diproses',
              messageType: ToastificationType.info,
              duration: const Duration(seconds: 3),
            );
          },
          onError: (error, stack) {
            defaultErrorResponse(error: error);
          },
        );
  }

  void deleteAllOldDiscount() {
    server
        .delete('discounts/delete_inactive_past_discount')
        .then(
          (response) {
            flash.showBanner(
              title: response.data['message'],
              description: 'Semua diskon akan diproses',
              messageType: ToastificationType.success,
            );
            refreshTable();
          },
          onError: (error, stack) {
            defaultErrorResponse(error: error);
          },
        );
  }

  void massUploadDiscount() {
    var tabManager = context.read<TabManager>();
    setState(() {
      tabManager.addTab('Mass Upload Diskon', const DiscountMassUploadPage());
    });
  }

  void downloadActiveDiscountItems() {
    showLoadingPopup();
    server
        .get('discounts/download_active_items', type: 'xlsx')
        .then((response) async {
          if (response.statusCode != 200) {
            flash.showBanner(
              title: 'Gagal Download',
              description: 'Gagal Download Aktif discount item ',
              messageType: ToastificationType.error,
            );
          }
          String filename = response.headers.value('content-disposition') ?? '';
          if (filename.isEmpty) {
            return;
          }
          filename = filename.substring(
            filename.indexOf('filename="') + 10,
            filename.indexOf('xlsx";') + 4,
          );
          var downloader = const FileSaver();
          downloader.download(
            filename,
            response.data,
            'xlsx',
            onSuccess: (String path) {
              flash.showBanner(
                messageType: ToastificationType.success,
                title: 'Sukses download',
                description: 'sukses disimpan di $path',
              );
            },
          );
        }, onError: (error) => defaultErrorResponse(error: error))
        .whenComplete(() => hideLoadingPopup());
  }

  void downloadDiscountItems(discount) {
    showLoadingPopup();
    server
        .get('discounts/${discount.id}/download_items', type: 'xlsx')
        .then((response) async {
          if (response.statusCode != 200) {
            flash.showBanner(
              title: 'Gagal Download',
              description: 'Gagal Download discount item ${discount.code}',
              messageType: ToastificationType.error,
            );
          }
          String filename = response.headers.value('content-disposition') ?? '';
          if (filename.isEmpty) {
            return;
          }
          filename = filename.substring(
            filename.indexOf('filename="') + 10,
            filename.indexOf('xlsx";') + 4,
          );
          var downloader = const FileSaver();
          downloader.download(
            filename,
            response.data,
            'xlsx',
            onSuccess: (String path) {
              flash.showBanner(
                messageType: ToastificationType.success,
                title: 'Sukses download',
                description: 'sukses disimpan di $path',
              );
            },
          );
        }, onError: (error) => defaultErrorResponse(error: error))
        .whenComplete(() => hideLoadingPopup());
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
              enums: const {
                'calculation_type': DiscountCalculationType.values,
                'discount_type': DiscountType.values,
              },
              onSubmit: (value) {
                _filters = value;
                refreshTable();
              },
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                        MenuItemButton(
                          child: const Text('Download Aktif Diskon item'),
                          onPressed: () {
                            _controller.close();
                            downloadActiveDiscountItems();
                          },
                        ),
                      ],
                      child: const Icon(Icons.table_rows_rounded),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: bodyScreenHeight,
              child: CustomAsyncDataTable<Discount>(
                actionColumnWidth: 220,
                renderAction: (discount) => Row(
                  spacing: 10,
                  children: [
                    IconButton(
                      onPressed: () {
                        editForm(discount);
                      },
                      tooltip: 'Edit diskon',
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: () {
                        refreshPromotion(discount);
                      },
                      tooltip: 'Refresh item promotion',
                      icon: const Icon(Icons.refresh),
                    ),
                    IconButton(
                      onPressed: () {
                        downloadDiscountItems(discount);
                      },
                      tooltip: 'Download diskon Item',
                      icon: const Icon(Icons.download),
                    ),
                    IconButton(
                      onPressed: () {
                        showConfirmDeleteDialog(discount);
                      },
                      tooltip: 'Hapus diskon',
                      icon: const Icon(Icons.delete),
                    ),
                  ],
                ),
                columns: columns,
                onLoaded: (stateManager) {
                  _source = stateManager;
                  _source.sortDescending(_source.columns[17]);
                },
                fetchData: fetchDiscounts,
                fixedLeftColumns: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
