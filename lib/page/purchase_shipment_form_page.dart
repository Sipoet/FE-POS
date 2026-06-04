import 'package:collection/collection.dart';
import 'package:fe_pos/model/forwarder.dart';
import 'package:fe_pos/model/purchase_shipment.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/purchase_invoice.dart';
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
import 'package:fe_pos/widget/money_form_field.dart';
import 'package:fe_pos/widget/number_form_field.dart';
import 'package:fe_pos/widget/table_form.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:provider/provider.dart';

class PurchaseShipmentFormPage extends StatefulWidget {
  final PurchaseShipment purchaseShipment;
  const PurchaseShipmentFormPage({super.key, required this.purchaseShipment});

  @override
  State<PurchaseShipmentFormPage> createState() =>
      _PurchaseShipmentFormPageState();
}

class _PurchaseShipmentFormPageState extends State<PurchaseShipmentFormPage>
    with
        AutomaticKeepAliveClientMixin,
        LoadingPopup,
        HistoryPopup,
        TextFormatter,
        DefaultResponse {
  final _formState = GlobalKey<FormState>();
  late Flash flash;
  late PurchaseShipment purchaseShipment;
  late final Server _server;
  late final Setting setting;
  late final TabManager tabManager;
  final ValueNotifier<bool> modelToggleNotifier = ValueNotifier(false);
  bool _showForm = true;
  bool _showSummary = true;
  final double width = 300;
  final menuController = MenuController();
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    flash = Flash();
    setting = context.read<Setting>();
    _server = context.read<Server>();
    tabManager = context.read<TabManager>();
    purchaseShipment = widget.purchaseShipment;
    if (!purchaseShipment.isNewRecord) {
      Future.delayed(Duration.zero, () => fetchPurchaseShipment());
    }
    super.initState();
  }

  void _saveRecord() {
    if (_formState.currentState?.validate() != true) {
      return;
    }
    // _formState.currentState?.save();

    purchaseShipment
        .save(_server)
        .then((result) {
          if (result) {
            setState(() {
              _showForm = false;
            });
            flash.show(Text('Sukses Simpan Invoice Pembelian'), .success);
            tabManager.changeTabHeader(
              widget,
              'Edit Produk ${purchaseShipment.code}',
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
              description: purchaseShipment.errors.join(','),
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
      message:
          'Apakah yakin reset Invoice Pembelian "${purchaseShipment.code}"',
      onSubmit: () {
        setState(() {
          _showForm = false;
        });
        purchaseShipment.reset();
        Future.delayed(Durations.short1, () {
          setState(() {
            _showForm = true;
          });
        });
      },
    );
  }

  void _duplicateRecord() {
    showConfirmDialog(
      message:
          'Apakah yakin duplikat Invoice Pembelian "${purchaseShipment.code}"',
      onSubmit: () {
        purchaseShipment.id = null;
        purchaseShipment.code = '';
        for (final purchaseShipmentDetail
            in purchaseShipment.purchaseShipmentDetails) {
          purchaseShipmentDetail.id = null;
          purchaseShipmentDetail.costDetail = null;
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
        purchaseShipment = PurchaseShipmentClass().initModel();
        // controller.clearImages();
        _showForm = true;
      });
    });
  }

  void fetchPurchaseShipment() {
    showLoadingPopup();
    setState(() {
      _showForm = false;
    });
    purchaseShipment
        .refresh(
          _server,
          include: [
            'sender',
            'location',
            'purchase_shipment_details',
            'purchase_shipment_details.cost_detail',
            'purchase_shipment_details.purchase_invoice',
            'purchase_shipment_details.supplier',
          ],
        )
        .then(
          (isSuccess) {
            if (isSuccess) {
              setState(() {
                purchaseShipment.purchaseShipmentDetails;
              });
            }
          },
          onError: (error) {
            defaultErrorResponse(error: error);
          },
        )
        .whenComplete(() {
          hideLoadingPopup();
          setState(() {
            _showForm = true;
          });
        });
  }

  void recalculatePurchaseShipment() {
    purchaseShipment.grandtotal = purchaseShipment.purchaseShipmentDetails
        .whereNot((e) => e.isDestroyed)
        .map((e) => e.shippingCost)
        .sum;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: Padding(
        padding: .all(10),
        child: Form(
          key: _formState,
          autovalidateMode: .onUnfocus,
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
                          children: [
                            Visibility(
                              visible: !purchaseShipment.isNewRecord,
                              child: ElevatedButton.icon(
                                onPressed: () => fetchHistoryByRecord(
                                  'PurchaseShipment',
                                  purchaseShipment.id,
                                ),
                                label: const Text('Riwayat'),
                                icon: const Icon(Icons.history),
                              ),
                            ),
                            const Divider(),
                            Visibility(
                              visible: setting.canShow(
                                'purchaseShipment',
                                'code',
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 5,
                                ),
                                child: SizedBox(
                                  width: width,
                                  child: AuthorizerFormField(
                                    notifier: modelToggleNotifier,
                                    tableName: 'purchaseShipment',
                                    columnName: 'code',
                                    childBuilder: (controller) => TextFormField(
                                      decoration: InputDecoration(
                                        labelText: setting.columnName(
                                          'purchaseShipment',
                                          'code',
                                        ),
                                        labelStyle: TextFormatter.labelStyle,
                                        border: const OutlineInputBorder(),
                                        hintText: 'Auto',
                                      ),
                                      controller: controller,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'harus diisi';
                                        }
                                        return null;
                                      },
                                      onChanged: (value) =>
                                          purchaseShipment.code = value,
                                    ),
                                    valueCallback: () => purchaseShipment.code,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: setting.canShow(
                                'purchaseShipment',
                                'sender',
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 5,
                                ),
                                child: SizedBox(
                                  width: width,
                                  child: AsyncDropdown<Forwarder>(
                                    label: Text(
                                      setting.columnName(
                                        'purchaseShipment',
                                        'sender',
                                      ),
                                      style: TextFormatter.labelStyle,
                                    ),
                                    validator: (value) {
                                      if (value == null) {
                                        return 'harus diisi';
                                      }
                                      return null;
                                    },
                                    modelClass: ForwarderClass(),
                                    textOnSearch: (supplier) => supplier.name,
                                    onChanged: (forwarder) =>
                                        purchaseShipment.sender = forwarder,
                                    selected: purchaseShipment.sender,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: setting.canShow(
                                'purchaseShipment',
                                'receiver',
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 5,
                                ),
                                child: SizedBox(
                                  width: width,
                                  child: AuthorizerFormField(
                                    notifier: modelToggleNotifier,
                                    tableName: 'purchaseShipment',
                                    columnName: 'receiver',
                                    childBuilder: (controller) => TextFormField(
                                      decoration: InputDecoration(
                                        labelText: setting.columnName(
                                          'purchaseShipment',
                                          'receiver',
                                        ),
                                        labelStyle: TextFormatter.labelStyle,
                                        border: const OutlineInputBorder(),
                                      ),
                                      controller: controller,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'harus diisi';
                                        }
                                        return null;
                                      },
                                      onChanged: (value) =>
                                          purchaseShipment.receiver = value,
                                    ),
                                    valueCallback: () =>
                                        purchaseShipment.receiver,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: setting.canShow(
                                'purchaseShipment',
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
                                    label: Text(
                                      setting.columnName(
                                        'purchaseShipment',
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
                                        purchaseShipment.location = value,
                                    modelClass: LocationClass(),
                                    textOnSearch: (model) => model.name,
                                    selected: purchaseShipment.location,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: setting.canShow(
                                'purchaseShipment',
                                'shipped_at',
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 5,
                                ),
                                child: SizedBox(
                                  width: width,
                                  child: DateFormField<DateTime>(
                                    label: Text(
                                      setting.columnName(
                                        'purchaseShipment',
                                        'shipped_at',
                                      ),
                                      style: TextFormatter.labelStyle,
                                    ),
                                    validator: (datetime) {
                                      if (datetime == null) {
                                        return 'harus diisi';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) =>
                                        purchaseShipment.shippedAt = value,
                                    initialValue: purchaseShipment.shippedAt,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: setting.canShow(
                                'purchaseShipment',
                                'arrived_at',
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 5,
                                ),
                                child: SizedBox(
                                  width: width,
                                  child: DateFormField<DateTime>(
                                    label: Text(
                                      setting.columnName(
                                        'purchaseShipment',
                                        'arrived_at',
                                      ),
                                      style: TextFormatter.labelStyle,
                                    ),
                                    onChanged: (value) =>
                                        purchaseShipment.arrivedAt = value,
                                    initialValue: purchaseShipment.arrivedAt,
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
                            const Text(
                              "Item Detail",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  purchaseShipment.purchaseShipmentDetails.add(
                                    PurchaseShipmentDetail(),
                                  );
                                });
                              },
                              icon: Icon(Icons.add),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TableForm<PurchaseShipmentDetail>(
                          columns: [
                            TableFormColumn(
                              title: 'Invoice Pembelian',
                              headerBuilder: (context) => Text(
                                'Invoice Pembelian',
                                style: TextFormatter.tableLabelStyle,
                              ),
                              rowBuilder: (context, purchaseShipmentDetail) =>
                                  AsyncDropdown<PurchaseInvoice>(
                                    textOnSearch:
                                        setting.canShow('supplier', 'name')
                                        ? ((purchaseInvoice) =>
                                              '${purchaseInvoice.code} - ${purchaseInvoice.supplier?.name}')
                                        : ((purchaseInvoice) =>
                                              '${purchaseInvoice.code} - ${purchaseInvoice.supplier?.code}'),
                                    modelClass: PurchaseInvoiceClass(),
                                    request: (queryRequest) {
                                      queryRequest.include = ['supplier'];
                                      return PurchaseInvoiceClass().finds(
                                        _server,
                                        queryRequest,
                                      );
                                    },
                                    selected:
                                        purchaseShipmentDetail.purchaseInvoice,
                                    onChanged: (model) =>
                                        purchaseShipmentDetail.purchaseInvoice =
                                            model,
                                  ),
                            ),
                            if (setting.canShow(
                              'purchaseShipmentDetail',
                              'sack_quantity',
                            ))
                              TableFormColumn<PurchaseShipmentDetail>(
                                title: 'Jumlah karung/box',
                                headerBuilder: (context) => Text(
                                  'Jumlah karung/box',
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder: (context, purchaseShipmentDetail) =>
                                    NumberFormField<int>(
                                      initialValue:
                                          purchaseShipmentDetail.sackQuantity,
                                      onChanged: (value) =>
                                          purchaseShipmentDetail.sackQuantity =
                                              value ?? 0,
                                    ),
                              ),
                            if (setting.canShow(
                              'purchaseShipmentDetail',
                              'shipping_cost',
                            ))
                              TableFormColumn<PurchaseShipmentDetail>(
                                title: 'Biaya',
                                headerBuilder: (context) => Text(
                                  'Biaya',
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder: (context, purchaseShipmentDetail) =>
                                    MoneyFormField(
                                      initialValue:
                                          purchaseShipmentDetail.shippingCost,
                                      onChanged: (value) {
                                        setState(() {
                                          purchaseShipmentDetail.shippingCost =
                                              value ?? const Money(0);
                                          recalculatePurchaseShipment();
                                          modelToggleNotifier.value =
                                              !modelToggleNotifier.value;
                                        });
                                      },
                                    ),
                              ),
                            if (setting.canShow(
                              'purchaseShipmentDetail',
                              'description',
                            ))
                              TableFormColumn<PurchaseShipmentDetail>(
                                title: 'Deskripsi',
                                headerBuilder: (context) => Text(
                                  'Deskripsi',
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder: (context, purchaseShipmentDetail) =>
                                    AuthorizerFormField(
                                      columnName: 'description',
                                      tableName: 'purchaseShipmentDetail',
                                      notifier: modelToggleNotifier,
                                      valueCallback: () =>
                                          purchaseShipmentDetail.description,
                                      childBuilder: (controller) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 5,
                                        ),
                                        child: TextFormField(
                                          controller: controller,
                                          decoration: InputDecoration(
                                            labelText: setting.columnName(
                                              'purchaseShipmentDetail',
                                              'description',
                                            ),
                                            labelStyle:
                                                TextFormatter.labelStyle,
                                            border: const OutlineInputBorder(),
                                          ),
                                          keyboardType: .multiline,
                                          minLines: 3,
                                          maxLines: 5,
                                          onChanged: (value) =>
                                              purchaseShipmentDetail
                                                      .description =
                                                  value,
                                        ),
                                      ),
                                    ),
                              ),
                          ],
                          actionColumn: TableFormColumn<PurchaseShipmentDetail>(
                            desktopWidth: FixedColumnWidth(60),
                            rowBuilder: (context, purchaseInvoiceDetail) =>
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      purchaseShipment.purchaseShipmentDetails
                                          .remove(purchaseInvoiceDetail);
                                      recalculatePurchaseShipment();
                                      modelToggleNotifier.value =
                                          !modelToggleNotifier.value;
                                    });
                                  },
                                  icon: Icon(Icons.delete),
                                ),
                            headerBuilder: (context) => IconButton(
                              onPressed: () async {
                                if (await showConfirmDialog2()) {
                                  setState(() {
                                    purchaseShipment.purchaseShipmentDetails
                                        .removeAll();
                                  });
                                }
                              },
                              icon: Icon(Icons.delete),
                            ),
                          ),
                          rows: purchaseShipment.purchaseShipmentDetails,
                        ),
                        Row(
                          mainAxisAlignment: .spaceBetween,
                          children: [
                            AuthorizerFormField(
                              columnName: 'description',
                              tableName: 'purchaseShipment',
                              notifier: modelToggleNotifier,
                              valueCallback: () => purchaseShipment.description,
                              childBuilder: (controller) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 5,
                                ),
                                child: SizedBox(
                                  width: width,
                                  child: TextFormField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      labelText: setting.columnName(
                                        'purchaseShipment',
                                        'description',
                                      ),
                                      labelStyle: TextFormatter.labelStyle,
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType: .multiline,
                                    minLines: 3,
                                    maxLines: 5,
                                    onChanged: (value) =>
                                        purchaseShipment.description = value,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: MoneyFormField(
                                label: Text(
                                  'Grand Total',
                                  style: TextFormatter.labelStyle,
                                ),
                                readOnly: true,
                                notifier: modelToggleNotifier,
                                valueCallback: () =>
                                    purchaseShipment.grandtotal,
                              ),
                            ),
                          ],
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
                      visible: !purchaseShipment.isNewRecord,
                      child: ElevatedButton(
                        onPressed: _newRecord,
                        child: Text('Buat Baru'),
                      ),
                    ),
                    Visibility(
                      visible: !purchaseShipment.isNewRecord,
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
}
