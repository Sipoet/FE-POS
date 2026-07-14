import 'package:collection/collection.dart';
import 'package:fe_pos/model/item_variant.dart';
import 'package:fe_pos/model/purchase_invoice.dart';
import 'package:fe_pos/model/purchase_order.dart';
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
import 'package:fe_pos/widget/cost_detail_form_dialog.dart';
import 'package:fe_pos/widget/date_form_field.dart';
import 'package:fe_pos/widget/discount_detail_form_dialog.dart';
import 'package:fe_pos/widget/enum_dropdown.dart';
import 'package:fe_pos/widget/file_form_field.dart';
import 'package:fe_pos/widget/money_form_field.dart';
import 'package:fe_pos/widget/number_form_field.dart';
import 'package:fe_pos/widget/percentage_form_field.dart';
import 'package:fe_pos/widget/table_form.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

class PurchaseInvoiceFormPage extends StatefulWidget {
  final PurchaseInvoice purchaseInvoice;
  const PurchaseInvoiceFormPage({super.key, required this.purchaseInvoice});

  @override
  State<PurchaseInvoiceFormPage> createState() =>
      _PurchaseInvoiceFormPageState();
}

class _PurchaseInvoiceFormPageState extends State<PurchaseInvoiceFormPage>
    with
        AutomaticKeepAliveClientMixin,
        LoadingPopup,
        HistoryPopup,
        TextFormatter,
        DefaultResponse {
  late Flash flash;

  final _formState = GlobalKey<FormState>();
  late PurchaseInvoice purchaseInvoice;
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
    purchaseInvoice = widget.purchaseInvoice;
    if (!purchaseInvoice.isNewRecord) {
      Future.delayed(Duration.zero, () => fetchPurchaseInvoice());
    }
    super.initState();
  }

  bool get isReadOnly {
    if (purchaseInvoice.isNewRecord) {
      return false;
    } else {
      return purchaseInvoice.status != .draft;
    }
  }

  void fetchPurchaseInvoice() {
    showLoadingPopup();
    setState(() {
      _showForm = false;
    });
    Future.wait([
      refreshPurchaseInvoiceDetail(),
      purchaseInvoice
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
      if (purchaseInvoice.purchaseInvoiceDetails.isEmpty) {
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
      if (result == true) fetchPurchaseInvoice();
    });
  }

  void recalculatePurchaseInvoice() {
    List<PurchaseDetailCalculatorResult> detailResults = [];
    final purchaseCalculator = PurchaseCalculator();
    for (final (index, purchaseInvoiceDetail)
        in purchaseInvoice.purchaseInvoiceDetails.indexed) {
      final detailResult = purchaseCalculator.detailCalculate(
        quantity: purchaseInvoiceDetail.quantity,
        price: purchaseInvoiceDetail.price,
        discountDetails: purchaseInvoiceDetail.discountDetails,
      );
      purchaseInvoiceDetail.rowNumber = index + 1;
      purchaseInvoiceDetail.subtotal = detailResult.subtotal;
      purchaseInvoiceDetail.discountAmount = detailResult.discountAmount;
      purchaseInvoiceDetail.total = detailResult.total;
      detailResults.add(detailResult);
    }
    final headerResult = purchaseCalculator.headerCalculate(
      details: detailResults,
      discountDetails: purchaseInvoice.discountDetails,
      costDetails: purchaseInvoice.costDetails,
      taxType: purchaseInvoice.taxType,
      taxValue: purchaseInvoice.taxValue,
    );
    purchaseInvoice.subtotal = headerResult.subtotal;
    purchaseInvoice.costTotal = headerResult.costTotal;
    purchaseInvoice.discountAmount = headerResult.discountAmount;
    purchaseInvoice.discountTotal = headerResult.discountTotal;
    purchaseInvoice.grandtotal = headerResult.grandtotal;
    purchaseInvoice.taxAmount = headerResult.taxAmount;
    recalculateProductTotal();
  }

  void recalculateProductTotal() {
    List<String> productTotal = [];
    double total = 0;
    for (final entries
        in purchaseInvoice.purchaseInvoiceDetails
            .groupListsBy((e) => e.uom?.name)
            .entries) {
      double value = entries.value.map<double>((e) => e.quantity).sum;
      total += value;
      productTotal.add('${value.format()} ${entries.key}');
    }
    purchaseInvoice.productTotal = total;
  }

  Future<bool> updatePrice() async {
    showLoadingPopup();
    final dataParams = {
      'code': purchaseInvoice.code,
      'margin': margin,
      'round_type': roundType,
      'mark_upper': markUpper,
      'mark_lower': markLower,
      'mark_separator': markSeparator,
    };
    try {
      final response = await _server.post(
        '/purchase_invoices/${purchaseInvoice.id}/update_price',
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

  void copyDataFromPurchaseOrder(PurchaseOrder purchaseOrder) {
    purchaseInvoice.supplier = purchaseOrder.supplier;
    purchaseInvoice.location = purchaseOrder.location;
    purchaseInvoice.discountAmount = purchaseOrder.discountAmount;
    purchaseInvoice.discountTotal = purchaseOrder.discountTotal;
    purchaseInvoice.costTotal = purchaseOrder.costTotal;
    purchaseInvoice.taxAmount = purchaseOrder.taxAmount;
    purchaseInvoice.taxType = purchaseOrder.taxType;
    purchaseInvoice.taxValue = purchaseOrder.taxValue;
    purchaseInvoice.description = purchaseOrder.description;
    purchaseInvoice.discountDetails = purchaseOrder.discountDetails
        ?.map<DiscountDetail>(
          (e) => DiscountDetail(type: e.type, value: e.value),
        )
        .toList();
    purchaseInvoice.purchaseInvoiceDetails.removeAll();
    purchaseInvoice.purchaseInvoiceDetails = purchaseOrder.purchaseOrderDetails
        .map<PurchaseInvoiceDetail>((purchaseOrderDetail) {
          final newPurchaseInvoiceDetail = PurchaseInvoiceDetail(
            product: purchaseOrderDetail.product,
            price: purchaseOrderDetail.price,
            rowNumber: purchaseOrderDetail.rowNumber,
            quantity: purchaseOrderDetail.quantity,
            uom: purchaseOrderDetail.uom,
            total: purchaseOrderDetail.total,
            purchaseOrderDetail: purchaseOrderDetail,
            subtotal: purchaseOrderDetail.subtotal,
            barcode: purchaseOrderDetail.product?.barcodeUsingBatch == true
                ? null
                : purchaseOrderDetail.product?.barcode,
            discountDetails: purchaseOrderDetail.discountDetails,
            discountAmount: purchaseOrderDetail.discountAmount,
          );
          for (final tagging in newPurchaseInvoiceDetail.taggings) {
            tagging.id = null;
          }
          return newPurchaseInvoiceDetail;
        })
        .toList();
    purchaseInvoice.costDetails = purchaseOrder.costDetails
        .map<CostDetail>(
          (e) => CostDetail(
            description: e.description,
            amount: e.amount,
            sourceCostId: e.sourceCostId,
            sourceCostType: e.sourceCostType,
          ),
        )
        .toList();
  }

  void confirmInvoice() {
    _server.post('/purchase_invoices/${purchaseInvoice.id}/confirmed').then((
      response,
    ) {
      if (response.statusCode == 200) {
        setState(() {
          purchaseInvoice.status = .confirmed;
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
    _server.post('/purchase_invoices/${purchaseInvoice.id}/draft').then((
      response,
    ) {
      if (response.statusCode == 200) {
        setState(() {
          purchaseInvoice.status = .draft;
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
                recalculatePurchaseInvoice();
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
                          children: [
                            Visibility(
                              visible: !purchaseInvoice.isNewRecord,
                              child: ElevatedButton.icon(
                                onPressed: () => fetchHistoryByRecord(
                                  'PurchaseInvoice',
                                  purchaseInvoice.id,
                                ),
                                label: const Text('Riwayat'),
                                icon: const Icon(Icons.history),
                              ),
                            ),
                            Visibility(
                              visible: purchaseInvoice.status == .draft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 15.0),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (await showConfirmDialog2(
                                      message:
                                          'Apakah yakin confirm invoice pembelian ${purchaseInvoice.code}?',
                                    )) {
                                      confirmInvoice();
                                    }
                                  },
                                  child: const Text('Confirm'),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: purchaseInvoice.status == .confirmed,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 15.0),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (await showConfirmDialog2(
                                      message:
                                          'Apakah yakin redraft invoice pembelian ${purchaseInvoice.code}?',
                                    )) {
                                      redraftInvoice();
                                    }
                                  },
                                  child: const Text('Draft'),
                                ),
                              ),
                            ),
                            const Divider(),
                            Visibility(
                              visible: setting.canShow(
                                'purchaseInvoice',
                                'code',
                              ),
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
                                        'purchaseInvoice',
                                        'code',
                                      ),
                                      labelStyle: TextFormatter.labelStyle,
                                      border: const OutlineInputBorder(),
                                      hintText: 'Auto',
                                    ),
                                    onChanged: (value) =>
                                        purchaseInvoice.code = value,
                                    initialValue: purchaseInvoice.code,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: setting.canShow(
                                'purchaseInvoice',
                                'supplier',
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 5,
                                ),
                                child: SizedBox(
                                  width: width,
                                  child: AsyncDropdown<Supplier>(
                                    readOnly: isReadOnly,
                                    allowClear: false,
                                    label: Text(
                                      setting.columnName(
                                        'purchaseInvoice',
                                        'supplier',
                                      ),
                                      style: TextFormatter.labelStyle,
                                    ),
                                    validator: (value) {
                                      if (value == null) {
                                        return 'harus diisi';
                                      }
                                      return null;
                                    },
                                    modelClass: SupplierClass(),
                                    textOnSelected: (supplier) => supplier.name,
                                    textOnSearch: (supplier) =>
                                        '${supplier.code} - ${supplier.name}',
                                    onChanged: (supplier) =>
                                        purchaseInvoice.supplier = supplier,
                                    selected: purchaseInvoice.supplier,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: setting.canShow(
                                'purchaseInvoice',
                                'purchase_order',
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 5,
                                ),
                                child: SizedBox(
                                  width: width,
                                  child: AsyncDropdown<PurchaseOrder>(
                                    readOnly: isReadOnly,
                                    label: Text(
                                      setting.columnName(
                                        'purchaseInvoice',
                                        'purchase_order',
                                      ),
                                      style: TextFormatter.labelStyle,
                                    ),
                                    allowClear: true,
                                    modelClass: PurchaseOrderClass(),
                                    request: (queryRequest) {
                                      queryRequest.sorts = [
                                        SortData(
                                          key: 'transaction_date',
                                          isAscending: false,
                                        ),
                                      ];
                                      queryRequest.filters = [
                                        ComparisonFilterData(
                                          key: 'supplier',
                                          value: purchaseInvoice.supplier?.id,
                                        ),
                                      ];
                                      return PurchaseOrderClass().finds(
                                        _server,
                                        queryRequest,
                                      );
                                    },
                                    textOnSelected: (purchaseOrder) =>
                                        purchaseOrder.code,
                                    textOnSearch: (purchaseOrder) =>
                                        '${purchaseOrder.code} - ${purchaseOrder.transactionDate?.format()}',
                                    onChanged: (purchaseOrder) {
                                      purchaseInvoice.purchaseOrder =
                                          purchaseOrder;
                                      if (purchaseOrder == null) {
                                        return;
                                      }
                                      purchaseOrder
                                          .refresh(
                                            _server,
                                            include: [
                                              'supplier',
                                              'location',
                                              'cost_details',
                                              'taggings',
                                              'tags',
                                              'purchase_order_details',
                                              'purchase_order_details.uom',
                                              'purchase_order_details.product',
                                              'purchase_order_details.product_parent',
                                            ],
                                          )
                                          .then((isSuccess) {
                                            if (isSuccess) {
                                              setState(() {
                                                copyDataFromPurchaseOrder(
                                                  purchaseOrder,
                                                );
                                                recalculatePurchaseInvoice();
                                              });
                                              refreshSummary();
                                            }
                                          });
                                    },
                                    selected: purchaseInvoice.purchaseOrder,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: setting.canShow(
                                'purchaseInvoice',
                                'location',
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
                                        'purchaseInvoice',
                                        'location',
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
                                        purchaseInvoice.location = value,
                                    modelClass: LocationClass(),
                                    textOnSearch: (model) => model.name,
                                    selected: purchaseInvoice.location,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: setting.canShow(
                                'purchaseInvoice',
                                'transaction_date',
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 5,
                                ),
                                child: SizedBox(
                                  width: width,
                                  child: DateFormField<Date>(
                                    readOnly: isReadOnly,
                                    label: Text(
                                      setting.columnName(
                                        'purchaseInvoice',
                                        'transaction_date',
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
                                        purchaseInvoice.transactionDate = value,
                                    initialValue:
                                        purchaseInvoice.transactionDate,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: setting.canShow(
                                'purchaseInvoice',
                                'barcoded_at',
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
                                        'purchaseInvoice',
                                        'barcoded_at',
                                      ),
                                      style: TextFormatter.labelStyle,
                                    ),
                                    onChanged: (value) =>
                                        purchaseInvoice.barcodedAt = value,
                                    initialValue: purchaseInvoice.barcodedAt,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: setting.canShow(
                                'purchaseInvoice',
                                'opened_at',
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
                                        'purchaseInvoice',
                                        'opened_at',
                                      ),
                                      style: TextFormatter.labelStyle,
                                    ),

                                    onChanged: (value) =>
                                        purchaseInvoice.openedAt = value,
                                    initialValue: purchaseInvoice.openedAt,
                                  ),
                                ),
                              ),
                            ),
                            FileFormField(
                              fileTypes: [.document, .image],
                              initialFiles: purchaseInvoice.documents,
                              onChanged: (files) => setState(() {
                                purchaseInvoice.documents = files;
                              }),
                            ),
                          ],
                        ),
                        Visibility(
                          visible: purchaseInvoice.status != null,
                          child: Text(
                            'Status: ${purchaseInvoice.status?.humanize()}',
                            style: TextStyle(fontSize: 16),
                          ),
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
                                  visible: !purchaseInvoice.isNewRecord,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 15.0,
                                      top: 5,
                                    ),
                                    child: IconButton(
                                      onPressed: refreshPurchaseInvoiceDetail,
                                      icon: Icon(Icons.refresh),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  purchaseInvoice.purchaseInvoiceDetails.add(
                                    PurchaseInvoiceDetail(
                                      rowNumber: purchaseInvoice
                                          .purchaseInvoiceDetails
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
                            //             purchaseInvoice.purchaseInvoiceDetails
                            //                 .add(PurchaseInvoiceDetail());
                            //           });
                            //           menuController.close();
                            //         },
                            //       ),
                            //       if (!purchaseInvoice.isNewRecord)
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
                        TableForm<PurchaseInvoiceDetail>(
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
                              'purchaseInvoiceDetail',
                              'product',
                            ))
                              TableFormColumn<PurchaseInvoiceDetail>(
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
                                      purchaseInvoiceDetail,
                                      index,
                                    ) => AsyncDropdown<Product>(
                                      readOnly: isReadOnly,
                                      textOnSearch: (model) =>
                                          "${model.barcode}-${model.supplierProductCode ?? model.description ?? model.tagDescription}",
                                      modelClass: ProductClass(),
                                      isShowItemDescription: true,
                                      request: (queryRequest) {
                                        queryRequest.include = ['base_uom'];
                                        queryRequest.filters = [
                                          ComparisonFilterData(
                                            key: 'supplier',
                                            value: [
                                              purchaseInvoice.supplier?.id,
                                              'null',
                                            ],
                                          ),
                                        ];
                                        return ProductClass().finds(
                                          _server,
                                          queryRequest,
                                        );
                                      },
                                      selected:
                                          purchaseInvoiceDetail.product
                                              is ItemVariant
                                          ? (purchaseInvoiceDetail.product
                                                    as ItemVariant)
                                                .parent
                                          : purchaseInvoiceDetail.product,
                                      onChanged: (product) {
                                        setState(() {
                                          purchaseInvoiceDetail.product =
                                              product;
                                          if (product?.barcodeUsingBatch !=
                                              true) {
                                            purchaseInvoiceDetail.barcode =
                                                product?.barcode;
                                          }
                                          purchaseInvoiceDetail.uom =
                                              product?.baseUom;
                                          modelToggleNotifier.toggle();
                                        });
                                      },
                                    ),
                              ),
                            if (setting.canShow(
                              'purchaseInvoiceDetail',
                              'tags',
                            ))
                              TableFormColumn<PurchaseInvoiceDetail>(
                                isColumnResizeable: true,
                                title: 'Varian',
                                headerBuilder: (context) => Text(
                                  'Varian',
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder:
                                    (
                                      context,
                                      purchaseInvoiceDetail,
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
                                        if (purchaseInvoiceDetail.product
                                            is ItemVariant) {
                                          parentId =
                                              (purchaseInvoiceDetail.product
                                                      as ItemVariant)
                                                  .parentId;
                                        } else if (purchaseInvoiceDetail.product
                                            is Product) {
                                          parentId =
                                              purchaseInvoiceDetail.product?.id;
                                        }
                                        return ItemVariantClass().finds(
                                          _server,
                                          queryRequest,
                                          parentId: parentId,
                                        );
                                      },
                                      onChanged: (product) =>
                                          purchaseInvoiceDetail.product =
                                              product,
                                      selected:
                                          purchaseInvoiceDetail.itemVariant,
                                    ),
                              ),
                            if (setting.canShow(
                              'purchaseInvoiceDetail',
                              'barcode',
                            ))
                              TableFormColumn<PurchaseInvoiceDetail>(
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
                                      purchaseInvoiceDetail,
                                      index,
                                    ) => AuthorizerFormField(
                                      columnName: 'barcode',
                                      tableName: 'purchaseInvoiceDetail',
                                      notifier: modelToggleNotifier,
                                      valueCallback: () =>
                                          purchaseInvoiceDetail.barcode,
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
                                                purchaseInvoiceDetail.barcode =
                                                    value,
                                          ),
                                    ),
                              ),
                            if (setting.canShow(
                              'purchaseInvoiceDetail',
                              'quantity',
                            ))
                              TableFormColumn<PurchaseInvoiceDetail>(
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
                                    (context, purchaseInvoiceDetail, index) =>
                                        NumberFormField<double>(
                                          readOnly: isReadOnly,
                                          initialValue:
                                              purchaseInvoiceDetail.quantity,
                                          // isDense: true,
                                          onChanged: (value) =>
                                              purchaseInvoiceDetail.quantity =
                                                  value ?? 0,
                                        ),
                              ),
                            if (setting.canShow('purchaseInvoiceDetail', 'uom'))
                              TableFormColumn<PurchaseInvoiceDetail>(
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
                                      purchaseInvoiceDetail,
                                      index,
                                    ) => AsyncDropdown<UnitOfMeasurement>(
                                      readOnly: isReadOnly,
                                      width: 200,
                                      valueFallback: () =>
                                          purchaseInvoiceDetail.uom,
                                      notifier: modelToggleNotifier,
                                      onChanged: (value) =>
                                          purchaseInvoiceDetail.uom = value,
                                      allowClear: false,
                                      modelClass: UnitOfMeasurementClass(),
                                      path:
                                          '/products/${purchaseInvoiceDetail.product?.id}/unit_of_measurements',
                                      textOnSearch: (model) => model.name ?? '',
                                    ),
                              ),
                            if (setting.canShow(
                              'purchaseInvoiceDetail',
                              'note_quantity',
                            ))
                              TableFormColumn<PurchaseInvoiceDetail>(
                                isColumnResizeable: true,
                                title: 'Jumlah di Nota',
                                desktopWidth: FixedColumnWidth(120),
                                isNumeric: true,
                                headerBuilder: (context) => Text(
                                  'Jumlah di Nota',
                                  textAlign: .right,
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder:
                                    (
                                      context,
                                      purchaseInvoiceDetail,
                                      index,
                                    ) => NumberFormField<double>(
                                      readOnly: isReadOnly,
                                      initialValue:
                                          purchaseInvoiceDetail.noteQuantity,
                                      // isDense: true,
                                      onChanged: (value) =>
                                          purchaseInvoiceDetail.noteQuantity =
                                              value,
                                    ),
                              ),
                            if (setting.canShow(
                              'purchaseOrderDetail',
                              'quantity',
                            ))
                              TableFormColumn<PurchaseInvoiceDetail>(
                                isColumnResizeable: true,
                                title: 'Pesan',
                                desktopWidth: FixedColumnWidth(100),
                                isNumeric: true,
                                headerBuilder: (context) => Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Pesan',
                                        textAlign: .right,
                                        style: TextFormatter.tableLabelStyle,
                                      ),
                                    ),
                                    if (purchaseInvoice.purchaseOrder != null)
                                      IconButton(
                                        onPressed: refreshOrderQuantity,
                                        icon: Icon(Icons.refresh),
                                      ),
                                  ],
                                ),
                                rowBuilder:
                                    (context, purchaseInvoiceDetail, index) =>
                                        SelectableText(
                                          purchaseInvoiceDetail
                                                  .orderQuantityBasedDetailUom
                                                  ?.format() ??
                                              '',
                                          style: const TextStyle(fontSize: 16),
                                          textAlign: .right,
                                        ),
                              ),
                            if (setting.canShow(
                              'purchaseInvoiceDetail',
                              'price',
                            ))
                              TableFormColumn<PurchaseInvoiceDetail>(
                                isColumnResizeable: true,
                                title: 'Harga per Satuan',
                                isNumeric: true,
                                headerBuilder: (context) => Text(
                                  'Harga',
                                  textAlign: .right,
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder:
                                    (context, purchaseInvoiceDetail, index) =>
                                        MoneyFormField(
                                          readOnly: isReadOnly,
                                          initialValue:
                                              purchaseInvoiceDetail.price,
                                          // isDense: true,
                                          onChanged: (value) =>
                                              purchaseInvoiceDetail.price =
                                                  value ?? const Money(0),
                                        ),
                              ),
                            if (setting.canShow('product', 'sell_price'))
                              TableFormColumn<PurchaseInvoiceDetail>(
                                isColumnResizeable: true,
                                title: 'Harga Jual',
                                isNumeric: true,
                                headerBuilder: (context) => Text(
                                  'Harga Jual',
                                  textAlign: .right,
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder:
                                    (
                                      context,
                                      purchaseInvoiceDetail,
                                      index,
                                    ) => Row(
                                      children: [
                                        Flexible(
                                          child: MoneyFormField(
                                            notifier: modelToggleNotifier,
                                            readOnly:
                                                purchaseInvoiceDetail.product ==
                                                    null ||
                                                isReadOnly,
                                            validator: (value) {
                                              if (purchaseInvoiceDetail
                                                      .product ==
                                                  null) {
                                                return null;
                                              }
                                              if (value == null) {
                                                return 'tidak boleh kosong';
                                              }
                                              if (value < 0) {
                                                return 'tidak boleh negatif';
                                              }
                                              return null;
                                            },
                                            valueCallback: () =>
                                                purchaseInvoiceDetail
                                                    .product
                                                    ?.sellPrice,
                                            onChanged: (value) {
                                              final product =
                                                  purchaseInvoiceDetail.product;
                                              if (product == null ||
                                                  value == null) {
                                                return;
                                              }
                                              updateProductSellPrice(
                                                product,
                                                value,
                                              );
                                            },
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: SizedBox(
                                            width: 25,
                                            height: 25,
                                            child: purchaseInvoiceDetail
                                                .product
                                                ?.statusSellPrice
                                                .icon,
                                          ),
                                        ),
                                      ],
                                    ),
                              ),
                            if (setting.canShow(
                              'purchaseInvoiceDetail',
                              'margin',
                            ))
                              TableFormColumn<PurchaseInvoiceDetail>(
                                isColumnResizeable: true,
                                title: 'Margin%',
                                isNumeric: true,
                                headerBuilder: (context) => Text(
                                  'Margin%',
                                  textAlign: .right,
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder:
                                    (context, purchaseInvoiceDetail, index) =>
                                        SelectableText(
                                          purchaseInvoiceDetail.margin
                                                  ?.format() ??
                                              '',
                                        ),
                              ),
                            if (setting.canShow(
                              'purchaseInvoiceDetail',
                              'subtotal',
                            ))
                              TableFormColumn<PurchaseInvoiceDetail>(
                                isColumnResizeable: true,
                                title: 'Subtotal',
                                isNumeric: true,
                                headerBuilder: (context) => Text(
                                  'Subtotal',
                                  textAlign: .right,
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder:
                                    (context, purchaseInvoiceDetail, index) =>
                                        SelectableText(
                                          purchaseInvoiceDetail.subtotal
                                              .format(),
                                          textAlign: .right,
                                        ),
                              ),
                            if (setting.canShow(
                              'purchaseInvoiceDetail',
                              'discount_amount',
                            ))
                              TableFormColumn<PurchaseInvoiceDetail>(
                                title: 'Diskon',
                                isColumnResizeable: true,
                                desktopWidth: FixedColumnWidth(250),
                                headerBuilder: (context) => Text(
                                  'Diskon',
                                  textAlign: .right,
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                isNumeric: true,
                                rowBuilder:
                                    (
                                      context,
                                      purchaseInvoiceDetail,
                                      index,
                                    ) => Row(
                                      spacing: 15,
                                      mainAxisAlignment: .spaceBetween,
                                      crossAxisAlignment: .center,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () =>
                                              _openDiscountDetail(
                                                purchaseInvoiceDetail
                                                    .discountDetails,
                                                description: [
                                                  Text(
                                                    'Produk:  ${purchaseInvoiceDetail.barcode} ${purchaseInvoiceDetail.product?.tagDescription}',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ],
                                              ).then((discountDetails) {
                                                if (discountDetails == null ||
                                                    !mounted) {
                                                  return;
                                                }
                                                setState(() {
                                                  purchaseInvoiceDetail
                                                          .discountDetails =
                                                      discountDetails;
                                                  recalculatePurchaseInvoice();
                                                });
                                                refreshSummary();
                                              }),
                                          child: Text('Detail'),
                                        ),
                                        Text(
                                          purchaseInvoiceDetail.discountAmount
                                              .format(),
                                          textAlign: .right,
                                        ),
                                      ],
                                    ),
                              ),
                            if (setting.canShow(
                              'purchaseInvoiceDetail',
                              'total',
                            ))
                              TableFormColumn<PurchaseInvoiceDetail>(
                                title: 'Total',
                                isColumnResizeable: true,
                                headerBuilder: (context) => Text(
                                  'Total',
                                  textAlign: .right,
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                isNumeric: true,
                                rowBuilder:
                                    (context, purchaseInvoiceDetail, index) =>
                                        Text(
                                          purchaseInvoiceDetail.total.format(),
                                          textAlign: .right,
                                        ),
                              ),
                            if (setting.canShow(
                              'purchaseInvoiceDetail',
                              'expired_date',
                            ))
                              TableFormColumn<PurchaseInvoiceDetail>(
                                title: 'Tanggal Kadaluarsa',
                                isColumnResizeable: true,
                                headerBuilder: (context) => Text(
                                  'Tanggal Kadaluarsa',
                                  textAlign: .right,
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                isNumeric: true,
                                rowBuilder:
                                    (context, purchaseInvoiceDetail, index) =>
                                        DateFormField<Date>(
                                          dateType: DateType(),
                                          initialValue:
                                              purchaseInvoiceDetail.expiredDate,
                                          onChanged: (date) => setState(() {
                                            purchaseInvoiceDetail.expiredDate =
                                                date;
                                          }),
                                        ),
                              ),
                            if (setting.canShow(
                              'purchaseInvoiceDetail',
                              'production_date',
                            ))
                              TableFormColumn<PurchaseInvoiceDetail>(
                                title: 'Tanggal Produksi',
                                isColumnResizeable: true,
                                headerBuilder: (context) => Text(
                                  'Tanggal Produksi',
                                  textAlign: .right,
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                isNumeric: true,
                                rowBuilder:
                                    (
                                      context,
                                      purchaseInvoiceDetail,
                                      index,
                                    ) => DateFormField<Date>(
                                      dateType: DateType(),
                                      initialValue:
                                          purchaseInvoiceDetail.productionDate,
                                      onChanged: (date) => setState(() {
                                        purchaseInvoiceDetail.productionDate =
                                            date;
                                      }),
                                    ),
                              ),
                          ],
                          actionColumn: TableFormColumn<PurchaseInvoiceDetail>(
                            desktopWidth: FixedColumnWidth(60),
                            rowBuilder:
                                (context, purchaseInvoiceDetail, index) =>
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          purchaseInvoice.purchaseInvoiceDetails
                                              .remove(purchaseInvoiceDetail);
                                          recalculatePurchaseInvoice();
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
                                    purchaseInvoice.purchaseInvoiceDetails
                                        .removeAll();
                                  });
                                }
                              },
                              icon: Icon(Icons.delete),
                            ),
                          ),
                          rows: purchaseInvoice.purchaseInvoiceDetails,
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
                      visible: !purchaseInvoice.isNewRecord,
                      child: ElevatedButton(
                        onPressed: _newRecord,
                        child: Text('Buat Baru'),
                      ),
                    ),
                    Visibility(
                      visible: !purchaseInvoice.isNewRecord,
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

  Future refreshPurchaseInvoiceDetail() {
    return PurchaseInvoiceDetailClass()
        .finds(
          _server,
          QueryRequest(
            page: 1,
            filters: [
              ComparisonFilterData(
                key: 'purchase_invoice',
                value: purchaseInvoice.id,
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
            purchaseInvoice.purchaseInvoiceDetails = queryResponse.models;
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

    purchaseInvoice
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
              'Edit Produk ${purchaseInvoice.code}',
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
              description: purchaseInvoice.errors.join(','),
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
      message: 'Apakah yakin reset Invoice Pembelian "${purchaseInvoice.code}"',
      onSubmit: () {
        setState(() {
          _showForm = false;
        });
        purchaseInvoice.reset();
        Future.delayed(Durations.short1, () {
          setState(() {
            _showForm = true;
          });
        });
      },
    );
  }

  void refreshOrderQuantity() {
    for (final purchaseInvoiceDetail
        in purchaseInvoice.purchaseInvoiceDetails) {
      if (purchaseInvoiceDetail.purchaseOrderDetail == null) {
        continue;
      }
      fetchOrderQuantity(purchaseInvoiceDetail);
    }
  }

  void fetchOrderQuantity(PurchaseInvoiceDetail purchaseInvoiceDetail) {
    if (purchaseInvoiceDetail.product == null ||
        purchaseInvoiceDetail.orderQuantity == null ||
        purchaseInvoiceDetail.orderUom == null ||
        purchaseInvoiceDetail.uom == null) {
      setState(() {
        purchaseInvoiceDetail.orderQuantityBasedDetailUom = null;
      });
    }
    if (purchaseInvoiceDetail.uom?.id == purchaseInvoiceDetail.orderUom?.id) {
      setState(() {
        purchaseInvoiceDetail.orderQuantityBasedDetailUom =
            purchaseInvoiceDetail.orderQuantity;
      });
    }
    convertQuantityUom(
      fromUom: purchaseInvoiceDetail.orderUom!,
      toUom: purchaseInvoiceDetail.uom!,
      quantity: purchaseInvoiceDetail.orderQuantity!,
      product: purchaseInvoiceDetail.product!,
    ).then(
      (value) => setState(() {
        purchaseInvoiceDetail.orderQuantityBasedDetailUom = value;
      }),
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
          'Apakah yakin duplikat Invoice Pembelian "${purchaseInvoice.code}"',
      onSubmit: () {
        purchaseInvoice.id = null;
        purchaseInvoice.code = '';
        for (final purchaseInvoiceDetail
            in purchaseInvoice.purchaseInvoiceDetails) {
          purchaseInvoiceDetail.id = null;
          for (var tagging in purchaseInvoiceDetail.taggings) {
            tagging.id = null;
          }
        }
        for (final costDetail in purchaseInvoice.costDetails) {
          costDetail.id = null;
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
        purchaseInvoice = PurchaseInvoiceClass().initModel();
        // controller.clearImages();
        _showForm = true;
      });
    });
  }

  List<Widget> get leftSummaries => [
    AuthorizerFormField(
      columnName: 'description',
      tableName: 'purchaseInvoice',
      notifier: modelToggleNotifier,
      valueCallback: () => purchaseInvoice.description,
      childBuilder: (controller) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: SizedBox(
          width: width,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: setting.columnName('purchaseInvoice', 'description'),
              labelStyle: TextFormatter.labelStyle,
              border: const OutlineInputBorder(),
            ),
            keyboardType: .multiline,
            minLines: 3,
            maxLines: 5,
            onChanged: (value) => purchaseInvoice.description = value,
          ),
        ),
      ),
    ),
    Visibility(
      visible:
          setting.canShow('purchaseInvoice', 'discount_total') && _showSummary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: SizedBox(
          width: width,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: setting.columnName(
                'purchaseInvoice',
                'discount_total',
              ),
              labelStyle: TextFormatter.labelStyle,
              border: const OutlineInputBorder(),
            ),
            readOnly: true,
            initialValue: purchaseInvoice.discountTotal.format(),
          ),
        ),
      ),
    ),
  ];
  List<Widget> get rightSummaries => [
    Visibility(
      visible:
          setting.canShow('purchaseInvoice', 'product_total') && _showSummary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: SizedBox(
          width: width,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: setting.columnName('purchaseInvoice', 'product_total'),
              labelStyle: TextFormatter.labelStyle,
              border: const OutlineInputBorder(),
            ),
            readOnly: true,
            initialValue: purchaseInvoice.productTotal.toString(),
          ),
        ),
      ),
    ),
    Visibility(
      visible: setting.canShow('purchaseInvoice', 'subtotal') && _showSummary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: SizedBox(
          width: width,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: setting.columnName('purchaseInvoice', 'subtotal'),
              labelStyle: TextFormatter.labelStyle,
              border: const OutlineInputBorder(),
            ),
            readOnly: true,
            initialValue: moneyFormat(purchaseInvoice.subtotal),
          ),
        ),
      ),
    ),
    Visibility(
      visible:
          setting.canShow('purchaseInvoice', 'discount_amount') && _showSummary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Container(
          constraints: BoxConstraints(maxWidth: width + 100),
          child: Row(
            mainAxisSize: .min,
            spacing: 15,
            children: [
              ElevatedButton(
                onPressed: () =>
                    _openDiscountDetail(purchaseInvoice.discountDetails).then((
                      discountDetails,
                    ) {
                      if (discountDetails == null || !mounted) {
                        return;
                      }
                      setState(() {
                        purchaseInvoice.discountDetails = discountDetails;
                        recalculatePurchaseInvoice();
                      });
                      refreshSummary();
                    }),
                child: Text('Detail'),
              ),
              Flexible(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: setting.columnName(
                      'purchaseInvoice',
                      'discount_amount',
                    ),
                    labelStyle: TextFormatter.labelStyle,
                    border: const OutlineInputBorder(),
                  ),
                  readOnly: true,
                  initialValue: purchaseInvoice.discountAmount.format(),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    Visibility(
      visible: setting.canShow('purchaseInvoice', 'tax_value'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            child: EnumDropdown<TaxType>(
              width: width,
              label: Text(setting.columnName('purchaseInvoice', 'tax_type')),
              initialSelection: purchaseInvoice.taxType,
              onChanged: (taxType) => setState(() {
                purchaseInvoice.taxType = taxType ?? purchaseInvoice.taxType;
                recalculatePurchaseInvoice();
              }),
              values: TaxType.values,
            ),
          ),
          Visibility(
            visible: purchaseInvoice.taxType != .non,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              child: SizedBox(
                width: width,
                child: Row(
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    SizedBox(
                      width: 100,
                      child: PercentageFormField(
                        label: Text(
                          setting.columnName('purchaseInvoice', 'tax_value'),
                        ),
                        initialValue: purchaseInvoice.taxValue,
                        onChanged: (taxValue) => setState(() {
                          purchaseInvoice.taxValue = taxValue;
                        }),
                      ),
                    ),
                    Text(purchaseInvoice.taxAmount.format()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    Visibility(
      visible: setting.canShow('purchaseInvoice', 'cost_total') && _showSummary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Container(
          constraints: BoxConstraints(maxWidth: width + 100),
          child: Row(
            mainAxisSize: .min,
            spacing: 15,
            children: [
              ElevatedButton(
                onPressed: () => _openCostDetailForm(),
                child: Text('Detail'),
              ),
              Flexible(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: setting.columnName(
                      'purchaseInvoice',
                      'cost_total',
                    ),
                    labelStyle: TextFormatter.labelStyle,
                    border: const OutlineInputBorder(),
                  ),
                  readOnly: true,
                  initialValue: purchaseInvoice.costTotal.format(),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    Visibility(
      visible: setting.canShow('purchaseInvoice', 'grandtotal') && _showSummary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: SizedBox(
          width: width,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: setting.columnName('purchaseInvoice', 'grandtotal'),
              labelStyle: TextFormatter.labelStyle,
              border: const OutlineInputBorder(),
            ),
            readOnly: true,
            initialValue: moneyFormat(purchaseInvoice.grandtotal),
          ),
        ),
      ),
    ),
  ];

  void _openCostDetailForm() {
    final costDetails = purchaseInvoice.costDetails.toList();
    showDialog(
      context: context,
      builder: (context) {
        final navigator = Navigator.of(context);

        return CostDetailFormDialog(
          navigator: navigator,
          tabManager: tabManager,
          costDetails: costDetails,
          onSuccess: (newCostDetails) {
            setState(() {
              purchaseInvoice.costDetails = newCostDetails;
              recalculatePurchaseInvoice();
            });
            refreshSummary();
            navigator.pop();
          },
        );
      },
    );
  }

  Future<List<DiscountDetail>?> _openDiscountDetail(
    List<DiscountDetail>? sourceDiscountDetails, {
    List<Widget>? description,
  }) {
    return showDialog<List<DiscountDetail>?>(
      context: context,
      builder: (context) {
        final navigator = Navigator.of(context);
        return DiscountDetailFormDialog(
          tabManager: tabManager,
          navigator: navigator,
          discountDetails: sourceDiscountDetails,
          descriptions: description ?? [],
        );
      },
    );
  }
}
