import 'package:collection/collection.dart';
import 'package:fe_pos/model/item_variant.dart';
import 'package:fe_pos/model/product.dart';
import 'package:fe_pos/model/purchase_order.dart';
import 'package:fe_pos/model/unit_of_measurement.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/purchase_calculator.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/cost_detail_form_dialog.dart';
import 'package:fe_pos/widget/date_form_field.dart';
import 'package:fe_pos/widget/discount_detail_form_dialog.dart';
import 'package:fe_pos/widget/enum_dropdown.dart';
import 'package:fe_pos/widget/money_form_field.dart';
import 'package:fe_pos/widget/number_form_field.dart';
import 'package:fe_pos/widget/percentage_form_field.dart';
import 'package:fe_pos/widget/table_form.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

class PurchaseOrderFormPage extends StatefulWidget {
  final PurchaseOrder purchaseOrder;
  const PurchaseOrderFormPage({super.key, required this.purchaseOrder});

  @override
  State<PurchaseOrderFormPage> createState() => _PurchaseOrderFormPageState();
}

class _PurchaseOrderFormPageState extends State<PurchaseOrderFormPage>
    with
        AutomaticKeepAliveClientMixin,
        LoadingPopup,
        HistoryPopup,
        TextFormatter,
        DefaultResponse {
  late Flash flash;

  final _formState = GlobalKey<FormState>();
  late PurchaseOrder purchaseOrder;
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
  final menuController = MenuController();

  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    flash = Flash();
    setting = context.read<Authorizer>();
    _server = context.read<Server>();
    tabManager = context.read<TabManager>();
    purchaseOrder = widget.purchaseOrder;
    if (!purchaseOrder.isNewRecord) {
      Future.delayed(Duration.zero, () => fetchPurchaseOrder());
    }
    super.initState();
  }

  void fetchPurchaseOrder() {
    showLoadingPopup();

    setState(() {
      _showForm = false;
    });
    Future.wait([
      refreshPurchaseOrderDetail(),
      purchaseOrder
          .refresh(
            _server,
            include: [
              'supplier',
              'location',
              'cost_details',
              'taggings',
              'tags',
            ],
          )
          .then(
            (isSuccess) {
              if (isSuccess) {}
            },
            onError: (error) {
              defaultErrorResponse(error: error);
            },
          ),
    ]).whenComplete(() {
      recalculateProductTotal();
      hideLoadingPopup();
      setState(() {
        _showForm = true;
      });
    });
  }

  Future refreshPurchaseOrderDetail() {
    return PurchaseOrderDetailClass()
        .finds(
          _server,
          QueryRequest(
            page: 1,
            filters: [
              ComparisonFilterData(
                key: 'purchase_order',
                value: purchaseOrder.id,
              ),
            ],
            sorts: [SortData(key: 'row_number', isAscending: true)],
            include: ['uom', 'product', 'product_parent'],
          ),
        )
        .then((queryResponse) {
          setState(() {
            purchaseOrder.purchaseOrderDetails = queryResponse.models;
          });
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
                    floatingLabelBehavior: FloatingLabelBehavior.always,
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
                      floatingLabelBehavior: FloatingLabelBehavior.always,
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
                      floatingLabelBehavior: FloatingLabelBehavior.always,
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
                      floatingLabelBehavior: FloatingLabelBehavior.always,
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
      if (result == true) fetchPurchaseOrder();
    });
  }

  void recalculatePurchaseOrder() {
    List<PurchaseDetailCalculatorResult> detailResults = [];
    final purchaseCalculator = PurchaseCalculator();
    for (final (index, purchaseOrderDetail)
        in purchaseOrder.purchaseOrderDetails.indexed) {
      final detailResult = purchaseCalculator.detailCalculate(
        quantity: purchaseOrderDetail.quantity,
        price: purchaseOrderDetail.price,
        discountDetails: purchaseOrderDetail.discountDetails,
      );
      purchaseOrderDetail.rowNumber = index + 1;
      purchaseOrderDetail.subtotal = detailResult.subtotal;
      purchaseOrderDetail.discountAmount = detailResult.discountAmount;
      purchaseOrderDetail.total = detailResult.total;
      detailResults.add(detailResult);
    }
    final headerResult = purchaseCalculator.headerCalculate(
      details: detailResults,
      discountDetails: purchaseOrder.discountDetails,
      costDetails: purchaseOrder.costDetails,
      taxType: purchaseOrder.taxType,
      taxValue: purchaseOrder.taxValue,
    );
    purchaseOrder.subtotal = headerResult.subtotal;
    purchaseOrder.costTotal = headerResult.costTotal;
    purchaseOrder.discountAmount = headerResult.discountAmount;
    purchaseOrder.discountTotal = headerResult.discountTotal;
    purchaseOrder.grandtotal = headerResult.grandtotal;
    purchaseOrder.taxAmount = headerResult.taxAmount;
    recalculateProductTotal();
  }

  void recalculateProductTotal() {
    List<String> productTotal = [];
    double total = 0;
    for (final entries
        in purchaseOrder.purchaseOrderDetails
            .groupListsBy((e) => e.uom?.name)
            .entries) {
      double value = entries.value.map<double>((e) => e.quantity).sum;
      total += value;
      productTotal.add('${value.format()} ${entries.key}');
    }
    purchaseOrder.productTotal = total;
  }

  Future<bool> updatePrice() async {
    showLoadingPopup();
    final dataParams = {
      'code': purchaseOrder.code,
      'margin': margin,
      'round_type': roundType,
      'mark_upper': markUpper,
      'mark_lower': markLower,
      'mark_separator': markSeparator,
    };
    try {
      final response = await _server.post(
        '/purchase_orders/${purchaseOrder.id}/update_price',
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
        _showSummary = true;
      });
    });
  }

  final double width = 300;
  bool _showSummary = true;
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
                recalculatePurchaseOrder();
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
                              visible: !purchaseOrder.isNewRecord,
                              child: ElevatedButton.icon(
                                onPressed: () => fetchHistoryByRecord(
                                  'PurchaseOrder',
                                  purchaseOrder.id,
                                ),
                                label: const Text('Riwayat'),
                                icon: const Icon(Icons.history),
                              ),
                            ),
                            const Divider(),
                            Visibility(
                              visible: setting.canShow('purchaseOrder', 'code'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 5,
                                ),
                                child: SizedBox(
                                  width: width,
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                      labelText: setting.columnName(
                                        'purchaseOrder',
                                        'code',
                                      ),
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.always,
                                      labelStyle: TextFormatter.labelStyle,
                                      border: const OutlineInputBorder(),
                                      hintText: 'Auto',
                                    ),
                                    onChanged: (value) =>
                                        purchaseOrder.code = value,
                                    initialValue: purchaseOrder.code,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: setting.canShow(
                                'purchaseOrder',
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
                                    allowClear: false,
                                    label: Text(
                                      setting.columnName(
                                        'purchaseOrder',
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
                                        purchaseOrder.supplier = supplier,
                                    selected: purchaseOrder.supplier,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: setting.canShow(
                                'purchaseOrder',
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
                                    allowClear: false,
                                    label: Text(
                                      setting.columnName(
                                        'purchaseOrder',
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
                                        purchaseOrder.location = value,
                                    modelClass: LocationClass(),
                                    textOnSearch: (model) => model.name,
                                    selected: purchaseOrder.location,
                                  ),
                                ),
                              ),
                            ),

                            Visibility(
                              visible: setting.canShow(
                                'purchaseOrder',
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
                                    label: Text(
                                      setting.columnName(
                                        'purchaseOrder',
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
                                        purchaseOrder.transactionDate = value,
                                    initialValue: purchaseOrder.transactionDate,
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
                                  "Detail",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Visibility(
                                  visible: !purchaseOrder.isNewRecord,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 15.0,
                                      top: 5,
                                    ),
                                    child: IconButton(
                                      onPressed: refreshPurchaseOrderDetail,
                                      icon: Icon(Icons.refresh),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            IconButton(
                              onPressed: () {
                                setState(() {
                                  purchaseOrder.purchaseOrderDetails.add(
                                    PurchaseOrderDetail(),
                                  );
                                });
                              },
                              icon: Icon(Icons.add),
                            ),
                            // SizedBox(
                            //   width: 50,
                            //   child: MenuAnchor(
                            //     menuChildren: [
                            //       if (!purchaseOrder.isNewRecord)
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
                            //       onPressed: () {
                            //         if (menuController.isOpen) {
                            //           menuController.close();
                            //         } else {
                            //           menuController.open();
                            //         }
                            //       },
                            //       icon: Icon(Icons.table_rows_rounded),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TableForm<PurchaseOrderDetail>(
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
                                (index + 1).toString(),
                                textAlign: .right,
                              ),
                            ),
                            if (setting.canShow(
                              'purchaseOrderDetail',
                              'product',
                            ))
                              TableFormColumn<PurchaseOrderDetail>(
                                name: 'product',
                                title: 'Produk',
                                desktopWidth: FlexColumnWidth(1.5),
                                headerBuilder: (context) => Text(
                                  'Produk',
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder:
                                    (
                                      context,
                                      purchaseOrderDetail,
                                      index,
                                    ) => AsyncDropdown<Product>(
                                      allowClear: false,
                                      textOnSearch: (model) =>
                                          "${model.barcode}-${model.supplierProductCode}",
                                      isShowItemDescription: true,
                                      modelClass: ProductClass(),
                                      request: (queryRequest) {
                                        queryRequest.include = ['base_uom'];
                                        queryRequest.filters = [
                                          ComparisonFilterData(
                                            key: 'supplier',
                                            value: [
                                              purchaseOrder.supplier?.id,
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
                                          purchaseOrderDetail.product
                                              is ItemVariant
                                          ? (purchaseOrderDetail.product
                                                    as ItemVariant)
                                                .parent
                                          : purchaseOrderDetail.product,
                                      onChanged: (product) => setState(() {
                                        purchaseOrderDetail.product = product;
                                        purchaseOrderDetail.uom =
                                            product?.baseUom;
                                        modelToggleNotifier.toggle();
                                      }),
                                    ),
                              ),
                            if (setting.canShow(
                              'purchaseOrderDetail',
                              'product',
                            ))
                              TableFormColumn<PurchaseOrderDetail>(
                                title: 'Varian',
                                headerBuilder: (context) => Text(
                                  'Varian',
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder:
                                    (
                                      context,
                                      purchaseOrderDetail,
                                      index,
                                    ) => AsyncDropdown<ItemVariant>(
                                      textOnSearch: (itemVariant) =>
                                          "${itemVariant.barcode} - ${itemVariant.supplierProductCode} - ${itemVariant.description}",
                                      textOnSelected: (itemVariant) =>
                                          itemVariant.supplierProductCode ??
                                          itemVariant.barcode,
                                      modelClass: ItemVariantClass(),
                                      request: (queryRequest) {
                                        int? parentId;
                                        if (purchaseOrderDetail.product
                                            is ItemVariant) {
                                          parentId =
                                              (purchaseOrderDetail.product
                                                      as ItemVariant)
                                                  .parentId;
                                        } else if (purchaseOrderDetail.product
                                            is Product) {
                                          parentId =
                                              purchaseOrderDetail.product?.id;
                                        }
                                        return ItemVariantClass().finds(
                                          _server,
                                          queryRequest,
                                          parentId: parentId,
                                        );
                                      },
                                      onChanged: (product) =>
                                          purchaseOrderDetail.product = product,
                                      selected: purchaseOrderDetail.itemVariant,
                                    ),
                              ),
                            if (setting.canShow(
                              'purchaseOrderDetail',
                              'quantity',
                            ))
                              TableFormColumn<PurchaseOrderDetail>(
                                name: 'quantity',
                                title: 'Jumlah',
                                desktopWidth: FixedColumnWidth(90),
                                isNumeric: true,
                                headerBuilder: (context) => Text(
                                  'Jumlah',
                                  textAlign: .right,
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder:
                                    (context, purchaseOrderDetail, index) =>
                                        NumberFormField<double>(
                                          initialValue:
                                              purchaseOrderDetail.quantity,
                                          // isDense: true,
                                          onChanged: (value) =>
                                              purchaseOrderDetail.quantity =
                                                  value ?? 0,
                                        ),
                              ),
                            if (setting.canShow('purchaseOrderDetail', 'uom'))
                              TableFormColumn<PurchaseOrderDetail>(
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
                                      purchaseOrderDetail,
                                      index,
                                    ) => AsyncDropdown<UnitOfMeasurement>(
                                      width: 200,
                                      valueFallback: () =>
                                          purchaseOrderDetail.uom,
                                      notifier: modelToggleNotifier,
                                      onChanged: (value) => setState(() {
                                        purchaseOrderDetail.uom = value;
                                      }),
                                      allowClear: false,
                                      modelClass: UnitOfMeasurementClass(),
                                      path:
                                          '/products/${purchaseOrderDetail.product?.id}/unit_of_measurements',
                                      textOnSearch: (model) => model.name ?? '',
                                    ),
                              ),
                            if (setting.canShow(
                              'purchaseInvoiceDetail',
                              'quantity',
                            ))
                              TableFormColumn<PurchaseOrderDetail>(
                                title: 'Diterima',
                                desktopWidth: FixedColumnWidth(90),
                                isNumeric: true,
                                headerBuilder: (context) => Text(
                                  'Diterima',
                                  textAlign: .right,
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder:
                                    (context, purchaseOrderDetail, index) =>
                                        Text(
                                          purchaseOrderDetail.receivedQuantity
                                                  ?.format() ??
                                              '',
                                        ),
                              ),
                            if (setting.canShow('purchaseOrderDetail', 'price'))
                              TableFormColumn<PurchaseOrderDetail>(
                                name: 'price',
                                title: 'Harga per Satuan',
                                isNumeric: true,
                                headerBuilder: (context) => Text(
                                  'Harga',
                                  textAlign: .right,
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder:
                                    (context, purchaseOrderDetail, index) =>
                                        MoneyFormField(
                                          initialValue:
                                              purchaseOrderDetail.price,
                                          // isDense: true,
                                          onChanged: (value) =>
                                              purchaseOrderDetail.price =
                                                  value ?? const Money(0),
                                        ),
                              ),
                            if (setting.canShow('product', 'sell_price'))
                              TableFormColumn<PurchaseOrderDetail>(
                                name: 'sell_price',
                                title: 'Harga Jual',
                                isNumeric: true,
                                headerBuilder: (context) => Text(
                                  'Harga Jual per Satuan utama',
                                  textAlign: .right,
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder:
                                    (
                                      context,
                                      purchaseOrderDetail,
                                      index,
                                    ) => Row(
                                      children: [
                                        Flexible(
                                          child: MoneyFormField(
                                            notifier: modelToggleNotifier,
                                            readOnly:
                                                purchaseOrderDetail.product ==
                                                null,
                                            validator: (value) {
                                              if (purchaseOrderDetail.product ==
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
                                                purchaseOrderDetail
                                                    .product
                                                    ?.sellPrice,
                                            onChanged: (value) {
                                              final product =
                                                  purchaseOrderDetail.product;
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
                                            child: purchaseOrderDetail
                                                .product
                                                ?.statusSellPrice
                                                .icon,
                                          ),
                                        ),
                                      ],
                                    ),
                              ),
                            if (setting.canShow(
                              'purchaseOrderDetail',
                              'margin',
                            ))
                              TableFormColumn<PurchaseOrderDetail>(
                                name: 'margin',
                                title: 'Margin%',
                                isNumeric: true,
                                headerBuilder: (context) => Text(
                                  'Margin%',
                                  textAlign: .right,
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder:
                                    (context, purchaseOrderDetail, index) =>
                                        Text(
                                          purchaseOrderDetail.margin
                                                  ?.format() ??
                                              '',
                                        ),
                              ),
                            if (setting.canShow(
                              'purchaseOrderDetail',
                              'subtotal',
                            ))
                              TableFormColumn<PurchaseOrderDetail>(
                                name: 'subtotal',
                                title: 'Subtotal',
                                isNumeric: true,
                                headerBuilder: (context) => Text(
                                  'Subtotal',
                                  textAlign: .right,
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                rowBuilder:
                                    (context, purchaseOrderDetail, index) =>
                                        Container(
                                          height: 50,
                                          alignment: .centerRight,
                                          child: SelectableText(
                                            purchaseOrderDetail.subtotal
                                                .format(),
                                            textAlign: .right,
                                          ),
                                        ),
                              ),
                            if (setting.canShow(
                              'purchaseOrderDetail',
                              'discount_amount',
                            ))
                              TableFormColumn<PurchaseOrderDetail>(
                                title: 'Diskon',
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
                                      purchaseOrderDetail,
                                      index,
                                    ) => SizedBox(
                                      height: 50,
                                      child: Row(
                                        spacing: 15,
                                        mainAxisAlignment: .spaceBetween,
                                        crossAxisAlignment: .center,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () =>
                                                _openDiscountDetail(
                                                  purchaseOrderDetail
                                                      .discountDetails,
                                                  description: [
                                                    Text(
                                                      'Produk: ${purchaseOrderDetail.product?.description} ${purchaseOrderDetail.product?.tagDescription}',
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
                                                    purchaseOrderDetail
                                                            .discountDetails =
                                                        discountDetails;
                                                    recalculatePurchaseOrder();
                                                  });
                                                  refreshSummary();
                                                }),
                                            child: Text('Detail'),
                                          ),
                                          Text(
                                            purchaseOrderDetail.discountAmount
                                                .format(),
                                            textAlign: .right,
                                          ),
                                        ],
                                      ),
                                    ),
                              ),
                            if (setting.canShow('purchaseOrderDetail', 'total'))
                              TableFormColumn<PurchaseOrderDetail>(
                                title: 'Total',
                                headerBuilder: (context) => Text(
                                  'Total',
                                  textAlign: .right,
                                  style: TextFormatter.tableLabelStyle,
                                ),
                                isNumeric: true,
                                rowBuilder:
                                    (context, purchaseOrderDetail, index) =>
                                        Container(
                                          height: 50,
                                          alignment: .centerEnd,
                                          child: Text(
                                            purchaseOrderDetail.total.format(),
                                            textAlign: .right,
                                          ),
                                        ),
                              ),
                          ],
                          actionColumn: TableFormColumn<PurchaseOrderDetail>(
                            desktopWidth: FixedColumnWidth(60),
                            rowBuilder: (context, purchaseOrderDetail, index) =>
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      purchaseOrder.purchaseOrderDetails.remove(
                                        purchaseOrderDetail,
                                      );
                                      recalculatePurchaseOrder();
                                    });
                                    refreshSummary();
                                  },
                                  icon: Icon(Icons.delete),
                                ),
                          ),
                          rows: purchaseOrder.purchaseOrderDetails,
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
                      visible: !purchaseOrder.isNewRecord,
                      child: ElevatedButton(
                        onPressed: _newRecord,
                        child: Text('Buat Baru'),
                      ),
                    ),
                    Visibility(
                      visible: !purchaseOrder.isNewRecord,
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

    purchaseOrder
        .save(_server)
        .then((result) {
          if (result) {
            setState(() {
              _showForm = false;
              recalculateProductTotal();
            });
            flash.show(Text('Sukses Simpan Pesanan Pembelian'), .success);
            tabManager.changeTabHeader(
              widget,
              'Edit Produk ${purchaseOrder.code}',
            );
            Future.delayed(Durations.short1, () {
              setState(() {
                _showForm = true;
              });
            });
          } else {
            flash.showBanner(
              messageType: .error,
              title: 'Gagal Simpan Pesanan Pembelian',
              description: purchaseOrder.errors.join(','),
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
      message: 'Apakah yakin reset Pesanan Pembelian "${purchaseOrder.code}"',
      onSubmit: () {
        setState(() {
          _showForm = false;
        });
        purchaseOrder.reset();
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
          'Apakah yakin duplikat Pesanan Pembelian "${purchaseOrder.code}"',
      onSubmit: () {
        purchaseOrder.id = null;
        purchaseOrder.code = '';
        for (final purchaseOrderDetail in purchaseOrder.purchaseOrderDetails) {
          purchaseOrderDetail.id = null;
          for (var tagging in purchaseOrderDetail.taggings) {
            tagging.id = null;
          }
        }
        for (final costDetail in purchaseOrder.costDetails) {
          costDetail.id = null;
        }

        tabManager.changeTabHeader(widget, 'Tambah Pesanan Pembelian');
      },
    );
  }

  void _newRecord() {
    tabManager.changeTabHeader(widget, 'Tambah Pesanan Pembelian');
    setState(() {
      _showForm = false;
    });

    Future.delayed(Durations.short1, () {
      setState(() {
        purchaseOrder = PurchaseOrderClass().initModel();
        // controller.clearImages();
        _showForm = true;
      });
    });
  }

  List<Widget> get leftSummaries => [
    Visibility(
      visible: setting.canShow('purchaseOrder', 'description'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: SizedBox(
          width: width,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: setting.columnName('purchaseOrder', 'description'),
              labelStyle: TextFormatter.labelStyle,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
            ),
            keyboardType: .multiline,
            minLines: 3,
            maxLines: 5,
            onChanged: (value) => purchaseOrder.description = value,
            initialValue: purchaseOrder.description,
          ),
        ),
      ),
    ),
    Visibility(
      visible:
          setting.canShow('purchaseOrder', 'discount_total') && _showSummary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: SizedBox(
          width: width,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: setting.columnName('purchaseOrder', 'discount_total'),
              labelStyle: TextFormatter.labelStyle,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
            ),
            readOnly: true,
            initialValue: purchaseOrder.discountTotal.format(),
          ),
        ),
      ),
    ),
  ];
  List<Widget> get rightSummaries => [
    Visibility(
      visible:
          setting.canShow('purchaseOrder', 'product_total') && _showSummary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: SizedBox(
          width: width,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: setting.columnName('purchaseOrder', 'product_total'),
              labelStyle: TextFormatter.labelStyle,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
            ),
            readOnly: true,
            initialValue: purchaseOrder.productTotal.toString(),
          ),
        ),
      ),
    ),
    Visibility(
      visible: setting.canShow('purchaseOrder', 'subtotal') && _showSummary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: SizedBox(
          width: width,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: setting.columnName('purchaseOrder', 'subtotal'),
              labelStyle: TextFormatter.labelStyle,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
            ),
            readOnly: true,
            initialValue: moneyFormat(purchaseOrder.subtotal),
          ),
        ),
      ),
    ),
    Visibility(
      visible:
          setting.canShow('purchaseOrder', 'discount_amount') && _showSummary,
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
                    _openDiscountDetail(purchaseOrder.discountDetails).then((
                      discountDetails,
                    ) {
                      if (discountDetails == null || !mounted) {
                        return;
                      }
                      setState(() {
                        purchaseOrder.discountDetails = discountDetails;
                        recalculatePurchaseOrder();
                      });
                      refreshSummary();
                    }),
                child: Text('Detail'),
              ),
              Flexible(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: setting.columnName(
                      'purchaseOrder',
                      'discount_amount',
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelStyle: TextFormatter.labelStyle,
                    border: const OutlineInputBorder(),
                  ),
                  readOnly: true,
                  initialValue: purchaseOrder.discountAmount.format(),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    Visibility(
      visible: setting.canShow('purchaseOrder', 'tax_value'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            child: EnumDropdown<TaxType>(
              width: width,
              label: Text(setting.columnName('purchaseOrder', 'tax_type')),
              initialSelection: purchaseOrder.taxType,
              onChanged: (taxType) => setState(() {
                purchaseOrder.taxType = taxType ?? purchaseOrder.taxType;
                recalculatePurchaseOrder();
              }),
              values: TaxType.values,
            ),
          ),
          Visibility(
            visible: purchaseOrder.taxType != .non,
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
                          setting.columnName('purchaseOrder', 'tax_value'),
                        ),
                        initialValue: purchaseOrder.taxValue,
                        onChanged: (taxValue) => setState(() {
                          purchaseOrder.taxValue = taxValue;
                        }),
                      ),
                    ),
                    Text(purchaseOrder.taxAmount.format()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    Visibility(
      visible: setting.canShow('purchaseOrder', 'cost_total') && _showSummary,
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
                      'purchaseOrder',
                      'cost_total',
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelStyle: TextFormatter.labelStyle,
                    border: const OutlineInputBorder(),
                  ),
                  readOnly: true,
                  initialValue: purchaseOrder.costTotal.format(),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    Visibility(
      visible: setting.canShow('purchaseOrder', 'grandtotal') && _showSummary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: SizedBox(
          width: width,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: setting.columnName('purchaseOrder', 'grandtotal'),
              labelStyle: TextFormatter.labelStyle,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
            ),
            readOnly: true,
            initialValue: moneyFormat(purchaseOrder.grandtotal),
          ),
        ),
      ),
    ),
  ];

  void _openCostDetailForm() {
    final costDetails = purchaseOrder.costDetails.toList();
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
              purchaseOrder.costDetails = newCostDetails;
              recalculatePurchaseOrder();
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
