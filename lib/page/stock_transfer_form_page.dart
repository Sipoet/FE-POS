import 'package:collection/collection.dart';
import 'package:fe_pos/model/item_variant.dart';
import 'package:fe_pos/model/stock_transfer.dart';

import 'package:fe_pos/model/unit_of_measurement.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/authorizer_form_field.dart';
import 'package:fe_pos/widget/date_form_field.dart';
import 'package:fe_pos/widget/number_form_field.dart';
import 'package:fe_pos/widget/table_form.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class StockTransferFormPage extends StatefulWidget {
  final StockTransfer stockTransfer;
  const StockTransferFormPage({super.key, required this.stockTransfer});

  @override
  State<StockTransferFormPage> createState() => _StockTransferFormPageState();
}

class _StockTransferFormPageState extends State<StockTransferFormPage>
    with
        AutomaticKeepAliveClientMixin,
        LoadingPopup,
        HistoryPopup,
        TextFormatter,
        DefaultResponse {
  late Flash flash;

  final _formState = GlobalKey<FormState>();
  late StockTransfer stockTransfer;
  late final Server _server;
  late final Authorizer setting;
  late final TabManager tabManager;
  final ValueNotifier<bool> modelToggleNotifier = ValueNotifier(false);
  bool _showForm = true;
  double margin = 1;
  String roundType = 'mark';
  double markUpper = 900;
  double markLower = 500;
  double markSeparator = 500;
  final double width = 300;
  bool _showSummary = true;
  final menuController = MenuController();

  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    flash = Flash();
    setting = context.read<Authorizer>();
    _server = context.read<Server>();
    tabManager = context.read<TabManager>();
    stockTransfer = widget.stockTransfer;
    if (!stockTransfer.isNewRecord) {
      Future.delayed(Duration.zero, () => fetchStockTransfer());
    }
    super.initState();
  }

  bool get isReadOnly {
    if (stockTransfer.isNewRecord) {
      return false;
    } else {
      return stockTransfer.status != .draft;
    }
  }

  void fetchStockTransfer() {
    showLoadingPopup();
    setState(() {
      _showForm = false;
    });
    Future.wait([
      refreshStockTransferDetail(),
      stockTransfer
          .refresh(
            _server,
            include: [
              'supplier',
              'location',
              'cost_details',
              'purchase_order',
              'documents',
            ],
          )
          .then(
            (isSuccess) {
              if (isSuccess) {
                setState(() {
                  recalculateProductTotal();
                });
              }
            },
            onError: (error) {
              defaultErrorResponse(error: error);
            },
          ),
    ]).whenComplete(() {
      if (stockTransfer.stockTransferDetails.isEmpty) {
        Future.delayed(Durations.medium1, () {
          hideLoadingPopup();
          setState(() {
            _showForm = true;
          });
        });
      } else {
        hideLoadingPopup();
        setState(() {
          _showForm = true;
        });
      }
    });
  }

  void openUpdatePriceForm() {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final navigator = Navigator.of(context);
        return StatefulBuilder(
          builder: (BuildContext context, setstateDialog) => AlertDialog(
            title: const Text("Ubah Harga Jual"),
            content: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.percent),
                    hintText: 'margin on %',
                    helperText: 'margin on %',
                    labelText: 'Margin',
                    labelStyle: TextFormatter.labelStyle,
                    border: OutlineInputBorder(),
                  ),
                  initialValue: margin.toString(),
                  onChanged: (value) =>
                      margin = double.tryParse(value) ?? margin,
                ),
                const SizedBox(height: 10),
                DropdownMenu<String>(
                  label: const Text(
                    'Tipe Pembulatan',
                    style: TextFormatter.labelStyle,
                  ),
                  initialSelection: roundType,
                  onSelected: (value) => setstateDialog(() {
                    roundType = value ?? roundType;
                  }),
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(value: 'normal', label: 'Normal'),
                    DropdownMenuEntry(value: 'ceil', label: 'Pembulatan atas'),
                    DropdownMenuEntry(
                      value: 'floor',
                      label: 'Pembulatan bawah',
                    ),
                    DropdownMenuEntry(
                      value: 'mark',
                      label: 'Pembulatan berdasarkan mark',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Visibility(
                  visible: roundType == 'mark',
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Mark batasan',
                      labelStyle: TextFormatter.labelStyle,
                      border: OutlineInputBorder(),
                    ),
                    initialValue: markSeparator.toString(),
                    onChanged: (value) =>
                        markSeparator = double.tryParse(value) ?? markSeparator,
                  ),
                ),
                const SizedBox(height: 10),
                Visibility(
                  visible: roundType == 'mark',
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Mark Atas',
                      labelStyle: TextFormatter.labelStyle,
                      border: OutlineInputBorder(),
                    ),
                    initialValue: markUpper.toString(),
                    onChanged: (value) =>
                        markUpper = double.tryParse(value) ?? markUpper,
                  ),
                ),
                const SizedBox(height: 10),
                Visibility(
                  visible: roundType == 'mark',
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Mark Bawah',
                      labelStyle: TextFormatter.labelStyle,
                      border: OutlineInputBorder(),
                    ),
                    initialValue: markLower.toString(),
                    onChanged: (value) =>
                        markLower = double.tryParse(value) ?? markLower,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                child: const Text("Kembali"),
                onPressed: () {
                  navigator.pop(false);
                },
              ),
              ElevatedButton(
                child: const Text("Submit"),
                onPressed: () {
                  updatePrice().then((result) => navigator.pop(result));
                },
              ),
            ],
          ),
        );
      },
    ).then((result) {
      if (result == true) fetchStockTransfer();
    });
  }

  void recalculateStockTransfer() {
    for (final (index, stockTransferDetail)
        in stockTransfer.stockTransferDetails.indexed) {
      stockTransferDetail.rowNumber = index + 1;
    }
    recalculateProductTotal();
  }

  void recalculateProductTotal() {
    List<String> productTotal = [];
    double total = 0;
    for (final entries
        in stockTransfer.stockTransferDetails
            .groupListsBy((e) => e.uom?.name)
            .entries) {
      double value = entries.value.map<double>((e) => e.quantity).sum;
      total += value;
      productTotal.add('${value.format()} ${entries.key}');
    }
    stockTransfer.productTotal = total;
  }

  Future<bool> updatePrice() async {
    showLoadingPopup();
    final dataParams = {
      'code': stockTransfer.code,
      'margin': margin,
      'round_type': roundType,
      'mark_upper': markUpper,
      'mark_lower': markLower,
      'mark_separator': markSeparator,
    };
    try {
      final response = await _server.post(
        '/stock_transfers/${stockTransfer.id}/update_price',
        body: dataParams,
      );
      hideLoadingPopup();
      return response.statusCode == 200;
    } catch (e) {
      hideLoadingPopup();
      return false;
    }
  }

  void refreshSummary() {
    setState(() {
      _showSummary = false;
    });
    Future.delayed(Durations.short1, () {
      setState(() {
        modelToggleNotifier.value = !modelToggleNotifier.value;
        _showSummary = true;
      });
    });
  }

  void confirmInvoice() {
    _server.post('/stock_transfers/${stockTransfer.id}/confirmed').then((
      response,
    ) {
      if (response.statusCode == 200) {
        setState(() {
          stockTransfer.status = .confirmed;
        });
        flash.show(Text('Sukses Confirm Invoice Pembelian'), .success);
      } else if (response.statusCode == 409) {
        flash.showBanner(
          messageType: .error,
          title: 'Gagal Confirm Invoice Pembelian',
          description: (response.data['errors'] ?? []).join(','),
        );
      } else {
        flash.show(Text('Gagal Confirm Invoice Pembelian'), .error);
      }
    });
  }

  void redraftInvoice() {
    _server.post('/stock_transfers/${stockTransfer.id}/draft').then((response) {
      if (response.statusCode == 200) {
        setState(() {
          stockTransfer.status = .draft;
        });
        flash.show(Text('Sukses Draft Invoice Pembelian'), .success);
      } else if (response.statusCode == 409) {
        flash.showBanner(
          messageType: .error,
          title: 'Gagal Draft Invoice Pembelian',
          description: response.data['message'],
        );
      } else {
        flash.show(Text('Gagal Draft Invoice Pembelian'), .error);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Form(
          key: _formState,
          autovalidateMode: .onUnfocus,
          onChanged: () {
            Future.delayed(Durations.short1, () {
              setState(() {
                recalculateStockTransfer();
              });
            }).whenComplete(refreshSummary);
          },
          child: Visibility(
            visible: _showForm,
            child: Column(
              children: [
                Expanded(
                  child: VerticalBodyScroll(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Wrap(
                          alignment: .start,
                          runAlignment: .start,
                          crossAxisAlignment: .start,
                          spacing: 15,
                          children: [
                            Visibility(
                              visible: !stockTransfer.isNewRecord,
                              child: ElevatedButton.icon(
                                onPressed: () => fetchHistoryByRecord(
                                  'StockTransfer',
                                  stockTransfer.id,
                                ),
                                label: const Text('Riwayat'),
                                icon: const Icon(Icons.history),
                              ),
                            ),
                            Visibility(
                              visible: stockTransfer.status == .draft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 15.0),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (await showConfirmDialog2(
                                      message:
                                          'Apakah yakin confirm invoice pembelian ${stockTransfer.code}?',
                                    )) {
                                      confirmInvoice();
                                    }
                                  },
                                  child: const Text('Confirm'),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: stockTransfer.status == .confirmed,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 15.0),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (await showConfirmDialog2(
                                      message:
                                          'Apakah yakin redraft invoice pembelian ${stockTransfer.code}?',
                                    )) {
                                      redraftInvoice();
                                    }
                                  },
                                  child: const Text('Draft'),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: stockTransfer.status != null,
                              child: Text(
                                'Status: ${stockTransfer.status?.humanize()}',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            const Divider(),
                            Visibility(
                              visible: setting.canShow('stockTransfer', 'code'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 5,
                                ),
                                child: SizedBox(
                                  width: width,
                                  child: TextFormField(
                                    readOnly: isReadOnly,
                                    decoration: InputDecoration(
                                      labelText: setting.columnName(
                                        'stockTransfer',
                                        'code',
                                      ),
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.always,
                                      labelStyle: TextFormatter.labelStyle,
                                      border: const OutlineInputBorder(),
                                      hintText: 'Auto',
                                    ),
                                    onChanged: (value) =>
                                        stockTransfer.code = value,
                                    initialValue: stockTransfer.code,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: setting.canShow(
                                'stockTransfer',
                                'from_location',
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 5,
                                ),
                                child: SizedBox(
                                  width: width,
                                  child: AsyncDropdown<Location>(
                                    readOnly: isReadOnly,
                                    allowClear: false,
                                    label: Text(
                                      setting.columnName(
                                        'stockTransfer',
                                        'from_location',
                                      ),
                                      style: TextFormatter.labelStyle,
                                    ),
                                    validator: (value) {
                                      if (value == null) {
                                        return 'harus diisi';
                                      }
                                      return null;
                                    },
                                    modelClass: LocationClass(),
                                    textOnSearch: (location) => location.name,
                                    onChanged: (location) =>
                                        stockTransfer.fromLocation = location,
                                    selected: stockTransfer.fromLocation,
                                  ),
                                ),
                              ),
                            ),

                            Visibility(
                              visible: setting.canShow(
                                'stockTransfer',
                                'to_location',
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 5,
                                ),
                                child: SizedBox(
                                  width: width,
                                  child: AsyncDropdown<Location>(
                                    readOnly: isReadOnly,
                                    allowClear: false,
                                    label: Text(
                                      setting.columnName(
                                        'stockTransfer',
                                        'to_location',
                                      ),
                                      style: TextFormatter.labelStyle,
                                    ),
                                    validator: (value) {
                                      if (value == null) {
                                        return 'harus diisi';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) =>
                                        stockTransfer.toLocation = value,
                                    modelClass: LocationClass(),
                                    textOnSearch: (model) => model.name,
                                    selected: stockTransfer.toLocation,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: setting.canShow(
                                'stockTransfer',
                                'transaction_at',
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 5,
                                ),
                                child: SizedBox(
                                  width: width,
                                  child: DateFormField<DateTime>(
                                    readOnly: isReadOnly,
                                    label: Text(
                                      setting.columnName(
                                        'stockTransfer',
                                        'transaction_at',
                                      ),
                                      style: TextFormatter.labelStyle,
                                    ),
                                    validator: (value) {
                                      if (value == null) {
                                        return 'harus diisi';
                                      }
                                      return null;
                                    },
                                    dateType: DateTimeType(),
                                    onChanged: (value) =>
                                        stockTransfer.transactionAt = value,
                                    initialValue: stockTransfer.transactionAt,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "Item Detail",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Visibility(
                                  visible: !stockTransfer.isNewRecord,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 15.0,
                                      top: 5,
                                    ),
                                    child: IconButton(
                                      onPressed: refreshStockTransferDetail,
                                      icon: Icon(Icons.refresh),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  stockTransfer.stockTransferDetails.add(
                                    StockTransferDetail(
                                      rowNumber: stockTransfer
                                          .stockTransferDetails
                                          .length,
                                    ),
                                  );
                                  modelToggleNotifier.toggle();
                                });
                              },
                              icon: Icon(Icons.add),
                            ),

                            // SizedBox(
                            //   width: 50,
                            //   child: MenuAnchor(
                            //     menuChildren: [
                            //       MenuItemButton(
                            //         child: const Text('Tambah Detail'),
                            //         onPressed: () {
                            //           setState(() {
                            //             stockTransfer.stockTransferDetails
                            //                 .add(StockTransferDetail());
                            //           });
                            //           menuController.close();
                            //         },
                            //       ),
                            //       if (!stockTransfer.isNewRecord)
                            //         MenuItemButton(
                            //           child: const Text('Ganti Harga Jual'),
                            //           onPressed: () {
                            //             openUpdatePriceForm();
                            //             menuController.close();
                            //           },
                            //         ),
                            //     ],
                            //     controller: menuController,
                            //     child: IconButton(
                            //       onPressed: () => menuController.isOpen
                            //           ? menuController.close()
                            //           : menuController.open(),
                            //       icon: Icon(Icons.table_rows_rounded),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TableForm<StockTransferDetail>(
                          isRowReorderable: true,
                          // columnSpacing: 5,
                          onRowReorder: (rows, fromIndex, toIndex) {
                            setState(() {
                              for (final (index, detail) in rows.indexed) {
                                detail.rowNumber = index + 1;
                              }
                            });
                          },
                          columns: [
                            TableFormColumn(
                              title: '#',
                              isNumeric: true,
                              desktopWidth: FixedColumnWidth(40),
                              headerBuilder: (context) => Text(
                                '#',
                                style: TextFormatter.tableLabelStyle,
                                textAlign: .right,
                              ),
                              rowBuilder: (context, object, index) => Text(
                                object.rowNumber.toString(),
                                textAlign: .right,
                              ),
                            ),
                            if (setting.canShow(
                              'stockTransferDetail',
                              'product',
                            ))
                              TableFormColumn<StockTransferDetail>(
                                isColumnResizeable: true,
                                title: 'Produk',
                                // desktopWidth: FlexColumnWidth(1.5),
                                headerBuilder: (context) => Text(
                                  'Produk',
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder:
                                    (
                                      context,
                                      stockTransferDetail,
                                      index,
                                    ) => AsyncDropdown<Product>(
                                      readOnly: isReadOnly,
                                      textOnSearch: (model) =>
                                          "${model.barcode}-${model.supplierProductCode ?? model.description ?? model.tagDescription}",
                                      modelClass: ProductClass(),
                                      isShowItemDescription: true,
                                      selected:
                                          stockTransferDetail.product
                                              is ItemVariant
                                          ? (stockTransferDetail.product
                                                    as ItemVariant)
                                                .parent
                                          : stockTransferDetail.product,
                                      onChanged: (product) {
                                        setState(() {
                                          stockTransferDetail.product = product;
                                          if (product?.barcodeUsingBatch !=
                                              true) {
                                            stockTransferDetail.barcode =
                                                product?.barcode;
                                          }
                                          stockTransferDetail.uom =
                                              product?.baseUom;
                                          modelToggleNotifier.toggle();
                                        });
                                      },
                                    ),
                              ),
                            if (setting.canShow('stockTransferDetail', 'tags'))
                              TableFormColumn<StockTransferDetail>(
                                isColumnResizeable: true,
                                title: 'Varian',
                                headerBuilder: (context) => Text(
                                  'Varian',
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder:
                                    (
                                      context,
                                      stockTransferDetail,
                                      index,
                                    ) => AsyncDropdown<ItemVariant>(
                                      readOnly: isReadOnly,
                                      textOnSearch: (itemVariant) =>
                                          "${itemVariant.barcode} - ${itemVariant.supplierProductCode} - ${itemVariant.description}",
                                      textOnSelected: (itemVariant) =>
                                          itemVariant.supplierProductCode ??
                                          itemVariant.barcode,
                                      modelClass: ItemVariantClass(),
                                      request: (queryRequest) {
                                        int? parentId;
                                        if (stockTransferDetail.product
                                            is ItemVariant) {
                                          parentId =
                                              (stockTransferDetail.product
                                                      as ItemVariant)
                                                  .parentId;
                                        } else if (stockTransferDetail.product
                                            is Product) {
                                          parentId =
                                              stockTransferDetail.product?.id;
                                        }
                                        return ItemVariantClass().finds(
                                          _server,
                                          queryRequest,
                                          parentId: parentId,
                                        );
                                      },
                                      onChanged: (product) =>
                                          stockTransferDetail.product = product,
                                      selected: stockTransferDetail.itemVariant,
                                    ),
                              ),
                            if (setting.canShow(
                              'stockTransferDetail',
                              'barcode',
                            ))
                              TableFormColumn<StockTransferDetail>(
                                isColumnResizeable: true,
                                title: 'Barcode',
                                isNumeric: true,
                                headerBuilder: (context) => Text(
                                  'Barcode',
                                  textAlign: .right,
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder:
                                    (
                                      context,
                                      stockTransferDetail,
                                      index,
                                    ) => AuthorizerFormField(
                                      columnName: 'barcode',
                                      tableName: 'stockTransferDetail',
                                      notifier: modelToggleNotifier,
                                      valueCallback: () =>
                                          stockTransferDetail.barcode,
                                      childBuilder: (controller) =>
                                          TextFormField(
                                            controller: controller,
                                            readOnly: isReadOnly,
                                            textCapitalization: .characters,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .singleLineFormatter,
                                              UpperCaseTextFormatter(),
                                              FilteringTextInputFormatter(
                                                RegExp(r'[A-Z0-9]'),
                                                allow: true,
                                              ),
                                              CustomNumberInputFormatter(
                                                formatType: .bankAccount,
                                                maxLength: 15,
                                              ),
                                            ],
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) =>
                                                stockTransferDetail.barcode =
                                                    value,
                                          ),
                                    ),
                              ),
                            if (setting.canShow(
                              'stockTransferDetail',
                              'quantity',
                            ))
                              TableFormColumn<StockTransferDetail>(
                                isColumnResizeable: true,
                                title: 'Jumlah',
                                desktopWidth: FixedColumnWidth(100),
                                isNumeric: true,
                                headerBuilder: (context) => Text(
                                  'Jumlah',
                                  textAlign: .right,
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder:
                                    (context, stockTransferDetail, index) =>
                                        NumberFormField<double>(
                                          readOnly: isReadOnly,
                                          initialValue:
                                              stockTransferDetail.quantity,
                                          // isDense: true,
                                          onChanged: (value) =>
                                              stockTransferDetail.quantity =
                                                  value ?? 0,
                                        ),
                              ),
                            if (setting.canShow('stockTransferDetail', 'uom'))
                              TableFormColumn<StockTransferDetail>(
                                isColumnResizeable: true,
                                name: 'uom',
                                title: 'Satuan',
                                desktopWidth: FixedColumnWidth(170),
                                headerBuilder: (context) => Text(
                                  'Satuan',
                                  textAlign: .right,
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder:
                                    (
                                      context,
                                      stockTransferDetail,
                                      index,
                                    ) => AsyncDropdown<UnitOfMeasurement>(
                                      readOnly: isReadOnly,
                                      width: 200,
                                      valueFallback: () =>
                                          stockTransferDetail.uom,
                                      notifier: modelToggleNotifier,
                                      onChanged: (value) =>
                                          stockTransferDetail.uom = value,
                                      allowClear: false,
                                      modelClass: UnitOfMeasurementClass(),
                                      path:
                                          '/products/${stockTransferDetail.product?.id}/unit_of_measurements',
                                      textOnSearch: (model) => model.name ?? '',
                                    ),
                              ),
                          ],
                          actionColumn: TableFormColumn<StockTransferDetail>(
                            desktopWidth: FixedColumnWidth(60),
                            rowBuilder: (context, stockTransferDetail, index) =>
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      stockTransfer.stockTransferDetails.remove(
                                        stockTransferDetail,
                                      );
                                      recalculateStockTransfer();
                                      modelToggleNotifier.toggle();
                                    });
                                    refreshSummary();
                                  },
                                  icon: Icon(Icons.delete),
                                ),
                            headerBuilder: (context) => IconButton(
                              onPressed: () async {
                                if (await showConfirmDialog2()) {
                                  setState(() {
                                    stockTransfer.stockTransferDetails
                                        .removeAll();
                                  });
                                }
                              },
                              icon: Icon(Icons.delete),
                            ),
                          ),
                          rows: stockTransfer.stockTransferDetails,
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, constraint) {
                            final size = MediaQuery.of(context).size;
                            if (size.width < 650) {
                              return Wrap(
                                alignment: .start,
                                children: [...leftSummaries, ...rightSummaries],
                              );
                            } else {
                              return Row(
                                crossAxisAlignment: .start,
                                mainAxisAlignment: .spaceBetween,
                                children: [
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: .start,
                                      mainAxisAlignment: .start,
                                      children: leftSummaries,
                                    ),
                                  ),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: .end,
                                      children: rightSummaries,
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                const SizedBox(height: 10),
                Wrap(
                  runSpacing: 15,
                  spacing: 15,
                  children: [
                    ElevatedButton(
                      onPressed: _saveRecord,
                      child: Text('Simpan'),
                    ),
                    ElevatedButton(
                      onPressed: _resetRecord,
                      child: Text('Reset'),
                    ),
                    Visibility(
                      visible: !stockTransfer.isNewRecord,
                      child: ElevatedButton(
                        onPressed: _newRecord,
                        child: Text('Buat Baru'),
                      ),
                    ),
                    Visibility(
                      visible: !stockTransfer.isNewRecord,
                      child: ElevatedButton(
                        onPressed: _duplicateRecord,
                        child: Text('Menduplikasi'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future refreshStockTransferDetail() {
    return StockTransferDetailClass()
        .finds(
          _server,
          QueryRequest(
            page: 1,
            filters: [
              ComparisonFilterData(
                key: 'stock_transfer',
                value: stockTransfer.id,
              ),
            ],
            sorts: [SortData(key: 'row_number', isAscending: true)],
            include: [
              'uom',
              'product',
              'product_parent',
              'order_uom',
              'purchase_order_detail',
            ],
          ),
        )
        .then((queryResponse) {
          setState(() {
            stockTransfer.stockTransferDetails = queryResponse.models;
            recalculateProductTotal();
          });
        });
  }

  void updateProductSellPrice(Product product, Money value) {
    product.sellPrice = value;
    setState(() {
      product.statusSellPrice = .onProgress;
    });
    product
        .save(_server, only: ['sell_price'])
        .then(
          (isSuccess) {
            if (isSuccess) {
              setState(() {
                product.statusSellPrice = .success;
              });
            } else {
              setState(() {
                product.statusSellPrice = .failed;
              });
            }
          },
          onError: (error) {
            setState(() {
              product.statusSellPrice = .failed;
            });
          },
        );
  }

  void _saveRecord() {
    if (_formState.currentState?.validate() != true) {
      return;
    }
    // _formState.currentState?.save();

    stockTransfer
        .save(_server, contentType: .multipartForm)
        .then((result) {
          if (result) {
            setState(() {
              _showForm = false;
              recalculateProductTotal();
            });
            flash.show(Text('Sukses Simpan Invoice Pembelian'), .success);
            tabManager.changeTabHeader(
              widget,
              'Edit Produk ${stockTransfer.code}',
            );
            Future.delayed(Durations.short1, () {
              setState(() {
                _showForm = true;
              });
            });
          } else {
            flash.showBanner(
              messageType: .error,
              title: 'Gagal Simpan Invoice Pembelian',
              description: stockTransfer.errors.join(','),
            );
          }
        })
        .whenComplete(() {
          setState(() {
            _showForm = true;
          });
        });
  }

  void _resetRecord() {
    showConfirmDialog(
      message: 'Apakah yakin reset Invoice Pembelian "${stockTransfer.code}"',
      onSubmit: () {
        setState(() {
          _showForm = false;
        });
        stockTransfer.reset();
        Future.delayed(Durations.short1, () {
          setState(() {
            _showForm = true;
          });
        });
      },
    );
  }

  Future<double> convertQuantityUom({
    required UnitOfMeasurement fromUom,
    required UnitOfMeasurement toUom,
    required double quantity,
    required Product product,
  }) {
    return _server
        .get(
          'unit_of_measurements/convert',
          queryParam: {
            'from_uom_id': fromUom.id,
            'to_uom_id': toUom.id,
            'product_id': product.id,
            'quantity': quantity,
          },
        )
        .then(
          (response) {
            if (response.statusCode == 200) {
              return double.parse(response.data?['data']?['value']);
            } else {
              throw 'gagal hitung jumlah';
            }
          },
          onError: (error) {
            defaultErrorResponse(error: error);
            throw error;
          },
        );
  }

  void _duplicateRecord() {
    showConfirmDialog(
      message:
          'Apakah yakin duplikat Invoice Pembelian "${stockTransfer.code}"',
      onSubmit: () {
        stockTransfer.id = null;
        stockTransfer.code = '';
        for (final stockTransferDetail in stockTransfer.stockTransferDetails) {
          stockTransferDetail.id = null;
        }
        tabManager.changeTabHeader(widget, 'Tambah Invoice Pembelian');
      },
    );
  }

  void _newRecord() {
    tabManager.changeTabHeader(widget, 'Tambah Invoice Pembelian');
    setState(() {
      _showForm = false;
    });

    Future.delayed(Durations.short1, () {
      setState(() {
        stockTransfer = StockTransferClass().initModel();
        // controller.clearImages();
        _showForm = true;
      });
    });
  }

  List<Widget> get leftSummaries => [
    AuthorizerFormField(
      columnName: 'description',
      tableName: 'stockTransfer',
      notifier: modelToggleNotifier,
      valueCallback: () => stockTransfer.description,
      childBuilder: (controller) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: SizedBox(
          width: width,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: setting.columnName('stockTransfer', 'description'),
              labelStyle: TextFormatter.labelStyle,
              border: const OutlineInputBorder(),
            ),
            keyboardType: .multiline,
            minLines: 3,
            maxLines: 5,
            onChanged: (value) => stockTransfer.description = value,
          ),
        ),
      ),
    ),
  ];
  List<Widget> get rightSummaries => [
    Visibility(
      visible:
          setting.canShow('stockTransfer', 'product_total') && _showSummary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: SizedBox(
          width: width,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: setting.columnName('stockTransfer', 'product_total'),
              labelStyle: TextFormatter.labelStyle,
              border: const OutlineInputBorder(),
            ),
            readOnly: true,
            initialValue: stockTransfer.productTotal.toString(),
          ),
        ),
      ),
    ),
  ];
}
