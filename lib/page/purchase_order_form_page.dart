import 'package:collection/collection.dart';
import 'package:fe_pos/model/product.dart';
import 'package:fe_pos/model/purchase_order.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/model_route.dart';
import 'package:fe_pos/tool/purchase_calculator.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_form_field.dart';
import 'package:fe_pos/widget/enum_dropdown.dart';
import 'package:fe_pos/widget/money_form_field.dart';
import 'package:fe_pos/widget/number_form_field.dart';
import 'package:fe_pos/widget/percentage_form_field.dart';
import 'package:fe_pos/widget/sync_data_table.dart';
import 'package:fe_pos/widget/table_form.dart';

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

  final _formKey = GlobalKey<FormState>();
  PurchaseOrder get purchaseOrder => widget.purchaseOrder;
  late final Server _server;
  late final Setting setting;
  late final SyncTableController _source;
  late final TabManager tabManager;
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
    setting = context.read<Setting>();
    _server = context.read<Server>();
    tabManager = context.read<TabManager>();
    if (!purchaseOrder.isNewRecord) {
      Future.delayed(Duration.zero, () => fetchPurchaseOrder());
    }
    super.initState();
  }

  void fetchPurchaseOrder() {
    showLoadingPopup();
    purchaseOrder
        .refresh(
          _server,
          include: [
            'purchase_order_details',
            'supplier',
            'purchase_order_details.product',
          ],
        )
        .then(
          (isSuccess) {
            if (isSuccess) {
              setState(() {
                _source.setModels(purchaseOrder.purchaseOrderDetails);
                _source.refreshTable();
              });
            }
          },
          onError: (error) {
            defaultErrorResponse(error: error);
          },
        )
        .whenComplete(() => hideLoadingPopup());
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
      if (result == true) fetchPurchaseOrder();
    });
  }

  void recalculatePurchaseOrder() {
    List<PurchaseDetailCalculatorResult> detailResults = [];
    final purchaseCalculator = PurchaseCalculator();
    for (var purchaseOrderDetail in purchaseOrder.purchaseOrderDetails) {
      final detailResult = purchaseCalculator.detailCalculate(
        quantity: purchaseOrderDetail.quantity,
        price: purchaseOrderDetail.price,
        discountDetails: purchaseOrderDetail.discountDetail,
      );
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
    List<String> productTotal = [];
    for (final entries
        in purchaseOrder.purchaseOrderDetails
            .groupListsBy((e) => e.uom)
            .entries) {
      double value = entries.value.map<double>((e) => e.quantity).sum;
      productTotal.add('${value.format()} ${entries.key}');
    }
    purchaseOrder.productTotal = productTotal.join(', ');
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
        'ipos/purchase_orders/code/update_price',
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

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Center(
          child: Form(
            key: _formKey,
            autovalidateMode: .onUnfocus,
            onChanged: () {
              setState(() {
                recalculatePurchaseOrder();
                _showSummary = false;
              });
              refreshSummary();
            },
            child: Column(
              // mainAxisAlignment: .start,
              crossAxisAlignment: .start,
              children: [
                Wrap(
                  // runSpacing: 10,
                  // spacing: 15,
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
                              labelStyle: TextFormatter.labelStyle,
                              border: const OutlineInputBorder(),
                              hintText: 'Auto',
                            ),

                            initialValue: purchaseOrder.code,
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: setting.canShow('purchaseOrder', 'supplier'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 5,
                        ),
                        child: SizedBox(
                          width: width,
                          child: AsyncDropdown<Supplier>(
                            label: Text(
                              setting.columnName('purchaseOrder', 'supplier'),
                              style: TextFormatter.labelStyle,
                            ),
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
                      visible: setting.canShow('purchaseOrder', 'location'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 5,
                        ),
                        child: SizedBox(
                          width: width,
                          child: AsyncDropdown<Location>(
                            label: Text(
                              setting.columnName('purchaseOrder', 'location'),
                              style: TextFormatter.labelStyle,
                            ),
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
                          child: DateFormField(
                            label: Text(
                              setting.columnName(
                                'purchaseOrder',
                                'transaction_date',
                              ),
                              style: TextFormatter.labelStyle,
                            ),
                            dateType: DateType(),
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
                    const Text(
                      "Item Detail",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: SubmenuButton(
                        menuChildren: [
                          MenuItemButton(
                            child: const Text('Tambah Detail'),
                            onPressed: () {
                              setState(() {
                                purchaseOrder.purchaseOrderDetails.add(
                                  PurchaseOrderDetail(),
                                );
                              });
                              menuController.close();
                            },
                          ),
                          if (!purchaseOrder.isNewRecord)
                            MenuItemButton(
                              child: const Text('Ganti Harga Jual'),
                              onPressed: () {
                                openUpdatePriceForm();
                                menuController.close();
                              },
                            ),
                        ],
                        controller: menuController,
                        onHover: (isHover) {
                          if (isHover) {
                            // menuController.open();
                          } else {
                            // menuController.close();
                          }
                        },
                        child: const Icon(Icons.table_rows_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: .horizontal,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 1700),
                    child: TableForm<PurchaseOrderDetail>(
                      columns: [
                        TableFormColumn<PurchaseOrderDetail>(
                          name: 'product',
                          title: 'Produk',
                          headerBuilder: (context) =>
                              Text('Produk', style: TextFormatter.labelStyle),
                          rowBuilder: (context, purchaseOrderDetail) =>
                              AsyncDropdown<Product>(
                                textOnSearch: (model) =>
                                    "${model.barcode}-${model.description}",
                                modelClass: ProductClass(),
                                selected: purchaseOrderDetail.product,
                                onChanged: (model) =>
                                    purchaseOrderDetail.product = model,
                              ),
                        ),
                        TableFormColumn<PurchaseOrderDetail>(
                          name: 'tags',
                          title: 'Tag',
                          headerBuilder: (context) =>
                              Text('Tag', style: TextFormatter.labelStyle),
                          rowBuilder: (context, purchaseOrderDetail) =>
                              AsyncDropdownMultiple<Tag>(
                                textOnSearch: (tag) => tag.modelValue,
                                textOnSelected: (tag) => tag.modelValue,
                                modelClass: TagClass(),
                                selecteds: purchaseOrderDetail.tags,
                                onChanged: (tags) =>
                                    purchaseOrderDetail.setTags(tags),
                              ),
                        ),
                        TableFormColumn<PurchaseOrderDetail>(
                          name: 'quantity',
                          title: 'Jumlah',
                          headerBuilder: (context) => Text(
                            'Jumlah',
                            textAlign: .right,
                            style: TextFormatter.labelStyle,
                          ),
                          rowBuilder: (context, purchaseOrderDetail) =>
                              NumberFormField<double>(
                                initialValue: purchaseOrderDetail.quantity,
                                onChanged: (value) =>
                                    purchaseOrderDetail.quantity = value ?? 0,
                              ),
                        ),
                        TableFormColumn<PurchaseOrderDetail>(
                          name: 'uom',
                          title: 'Satuan',
                          headerBuilder: (context) => Text(
                            'Satuan',
                            textAlign: .right,
                            style: TextFormatter.labelStyle,
                          ),
                          rowBuilder: (context, purchaseOrderDetail) =>
                              DropdownMenu<String>(
                                width: 200,
                                enableFilter: true,

                                initialSelection: purchaseOrderDetail.uom,
                                onSelected: (value) => setState(() {
                                  purchaseOrderDetail.uom = value ?? '';
                                }),
                                dropdownMenuEntries: [
                                  DropdownMenuEntry(value: 'pcs', label: 'PCS'),
                                ],
                              ),
                        ),
                        TableFormColumn<PurchaseOrderDetail>(
                          name: 'price',
                          title: 'Harga',
                          headerBuilder: (context) => Text(
                            'Harga',
                            textAlign: .right,
                            style: TextFormatter.labelStyle,
                          ),
                          rowBuilder: (context, purchaseOrderDetail) =>
                              MoneyFormField(
                                initialValue: purchaseOrderDetail.price,
                                onChanged: (value) =>
                                    purchaseOrderDetail.price =
                                        value ?? const Money(0),
                              ),
                        ),
                        TableFormColumn<PurchaseOrderDetail>(
                          name: 'subtotal',
                          title: 'Subtotal',
                          headerBuilder: (context) => Text(
                            'Subtotal',
                            textAlign: .right,
                            style: TextFormatter.labelStyle,
                          ),
                          rowBuilder: (context, purchaseOrderDetail) =>
                              Container(
                                height: 50,
                                alignment: .centerRight,
                                child: SelectableText(
                                  purchaseOrderDetail.subtotal.format(),
                                  textAlign: .right,
                                ),
                              ),
                        ),
                        TableFormColumn<PurchaseOrderDetail>(
                          name: 'discount_amount',
                          title: 'Diskon',
                          desktopWidth: FixedColumnWidth(250),
                          headerBuilder: (context) => Text(
                            'Diskon',
                            textAlign: .right,
                            style: TextFormatter.labelStyle,
                          ),
                          rowBuilder: (context, purchaseOrderDetail) => SizedBox(
                            height: 50,
                            child: Row(
                              spacing: 15,
                              mainAxisAlignment: .spaceBetween,
                              crossAxisAlignment: .center,
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      _openDiscountDetail(
                                        purchaseOrderDetail.discountDetail,
                                        description: [
                                          Text(
                                            'Produk: ${purchaseOrderDetail.product?.description} ${purchaseOrderDetail.product?.tagDescription}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                            ),
                                          ),
                                          Text(
                                            'Tag: ${purchaseOrderDetail.tagDescription}',
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
                                          purchaseOrderDetail.discountDetail =
                                              discountDetails;
                                          recalculatePurchaseOrder();
                                        });
                                        refreshSummary();
                                      }),
                                  child: Text('Detail'),
                                ),
                                Text(
                                  purchaseOrderDetail.discountAmount.format(),
                                  textAlign: .right,
                                ),
                              ],
                            ),
                          ),
                        ),
                        TableFormColumn<PurchaseOrderDetail>(
                          name: 'total',
                          title: 'Total',
                          headerBuilder: (context) => Text(
                            'Total',
                            textAlign: .right,
                            style: TextFormatter.labelStyle,
                          ),
                          rowBuilder: (context, purchaseOrderDetail) =>
                              Container(
                                height: 50,
                                alignment: .centerEnd,
                                child: Text(
                                  purchaseOrderDetail.total.format(),
                                  textAlign: .right,
                                ),
                              ),
                        ),
                        TableFormColumn<PurchaseOrderDetail>(
                          name: 'action',
                          desktopWidth: FixedColumnWidth(60),
                          rowBuilder: (context, purchaseOrderDetail) =>
                              IconButton(
                                onPressed: () => setState(() {
                                  purchaseOrder.purchaseOrderDetails.remove(
                                    purchaseOrderDetail,
                                  );
                                }),
                                icon: Icon(Icons.delete),
                              ),
                        ),
                      ],
                      rows: purchaseOrder.purchaseOrderDetails,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraint) {
                    final size = MediaQuery.of(context).size;
                    if (size.width < 650) {
                      return Wrap(
                        alignment: .start,
                        children: [
                          Visibility(
                            visible: setting.canShow(
                              'purchaseOrder',
                              'description',
                            ),
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
                                      'description',
                                    ),
                                    labelStyle: TextFormatter.labelStyle,
                                    border: const OutlineInputBorder(),
                                  ),
                                  readOnly: true,
                                  keyboardType: .multiline,
                                  minLines: 3,
                                  maxLines: 5,
                                  initialValue: purchaseOrder.description,
                                ),
                              ),
                            ),
                          ),
                          ...orderSummaries,
                        ],
                      );
                    } else {
                      return Row(
                        mainAxisAlignment: .spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: .start,
                            children: [
                              Visibility(
                                visible: setting.canShow(
                                  'purchaseOrder',
                                  'description',
                                ),
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
                                          'description',
                                        ),
                                        labelStyle: TextFormatter.labelStyle,
                                        border: const OutlineInputBorder(),
                                      ),
                                      readOnly: true,
                                      keyboardType: .multiline,
                                      minLines: 3,
                                      maxLines: 5,
                                      initialValue: purchaseOrder.description,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: .end,
                            children: orderSummaries,
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
      ),
    );
  }

  List<Widget> get orderSummaries => [
    Visibility(
      visible:
          setting.canShow('purchaseOrder', 'product_total') || _showSummary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: SizedBox(
          width: width,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: setting.columnName('purchaseOrder', 'product_total'),
              labelStyle: TextFormatter.labelStyle,
              border: const OutlineInputBorder(),
            ),
            readOnly: true,
            initialValue: purchaseOrder.productTotal.toString(),
          ),
        ),
      ),
    ),
    Visibility(
      visible: setting.canShow('purchaseOrder', 'subtotal') || _showSummary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: SizedBox(
          width: width,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: setting.columnName('purchaseOrder', 'subtotal'),
              labelStyle: TextFormatter.labelStyle,
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
          setting.canShow('purchaseOrder', 'discount_amount') || _showSummary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Row(
          mainAxisSize: .min,
          spacing: 15,
          children: [
            ElevatedButton(
              onPressed: () =>
                  _openDiscountDetail(purchaseOrder.discountDetails),
              child: Text('Detail'),
            ),
            SizedBox(
              width: width,
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: setting.columnName(
                    'purchaseOrder',
                    'discount_amount',
                  ),
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
    Visibility(
      visible: setting.canShow('purchaseOrder', 'tax_value'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            child: SizedBox(
              width: width,
              child: EnumDropdown<TaxType>(
                label: Text(setting.columnName('purchaseOrder', 'tax_type')),
                initialSelection: purchaseOrder.taxType,
                onChanged: (taxType) => setState(() {
                  purchaseOrder.taxType = taxType ?? purchaseOrder.taxType;
                }),
                values: TaxType.values,
              ),
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
                      width: 90,
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
      visible: setting.canShow('purchaseOrder', 'cost_total') || _showSummary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Row(
          spacing: 15,
          children: [
            ElevatedButton(
              onPressed: () => _openCostDetailForm(),
              child: Text('Detail'),
            ),
            SizedBox(
              width: width,
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: setting.columnName('purchaseOrder', 'cost_total'),
                  labelStyle: TextFormatter.labelStyle,
                  border: const OutlineInputBorder(),
                ),
                readOnly: true,
                initialValue: moneyFormat(purchaseOrder.costTotal),
              ),
            ),
          ],
        ),
      ),
    ),
    Visibility(
      visible: setting.canShow('purchaseOrder', 'grandtotal') || _showSummary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: SizedBox(
          width: width,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: setting.columnName('purchaseOrder', 'grandtotal'),
              labelStyle: TextFormatter.labelStyle,
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
    final route = ModelRoute();
    showDialog(
      context: context,
      builder: (context) {
        final navigator = Navigator.of(context);
        final scrollController = ScrollController();

        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Flexible(child: Text('Detail Biaya lain')),
                IconButton(
                  onPressed: () => navigator.pop(),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            content: SizedBox(
              height: 1000,
              width: 1000,
              child: Scrollbar(
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 8,
                controller: scrollController,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: TableForm<CostDetail>(
                    cellPadding: .all(10),
                    columns: [
                      TableFormColumn<CostDetail>(
                        name: 'Source',
                        headerBuilder: (context) => Text(
                          'Sumber',
                          textAlign: .right,
                          style: TextFormatter.titleStyle,
                        ),
                        rowBuilder: (context, object) => TextButton(
                          onPressed: () {
                            if (object.source == null) {
                              return;
                            }
                            final detailPage = route.detailPageOf(
                              object.source!,
                            );
                            if (detailPage == null) {
                              return;
                            }
                            tabManager.addTab(
                              'Edit ${object.sourceId}',
                              detailPage,
                            );
                          },
                          child: Text(
                            object.sourceId == null
                                ? ''
                                : '${object.sourceType} ${object.sourceId}',
                          ),
                        ),
                      ),
                      TableFormColumn<CostDetail>(
                        name: 'description',
                        headerBuilder: (context) => Text(
                          'Deskripsi',
                          textAlign: .right,
                          style: TextFormatter.titleStyle,
                        ),
                        rowBuilder: (context, object) => TextFormField(
                          initialValue: object.description,
                          keyboardType: .multiline,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          minLines: 1,
                          maxLines: 5,
                          onChanged: (value) => object.description = value,
                        ),
                      ),
                      TableFormColumn<CostDetail>(
                        name: 'amount',
                        headerBuilder: (context) => Text(
                          'Jumlah(Rp)',
                          textAlign: .right,
                          style: TextFormatter.titleStyle,
                        ),
                        rowBuilder: (context, object) => MoneyFormField(
                          initialValue: object.amount,
                          validator: (value) {
                            if (value == null) {
                              return 'harus diisi';
                            }
                            return null;
                          },
                          onChanged: (value) =>
                              object.amount = value ?? const Money(0),
                        ),
                      ),
                      TableFormColumn<CostDetail>(
                        name: 'action',
                        desktopWidth: FixedColumnWidth(130),
                        headerBuilder: (context) => Row(
                          mainAxisAlignment: .spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => setStateDialog(() {
                                costDetails.add(CostDetail());
                              }),
                              icon: Icon(Icons.add),
                            ),
                          ],
                        ),
                        rowBuilder: (context, object) => Visibility(
                          visible: object.source == null,
                          child: IconButton(
                            onPressed: () => setStateDialog(() {
                              if (object.isNewRecord) {
                                costDetails.remove(object);
                              } else {
                                object.flagDestroy();
                              }
                            }),
                            icon: Icon(Icons.delete),
                          ),
                        ),
                      ),
                    ],
                    rows: costDetails.whereNot((e) => e.isDestroyed).toList(),
                  ),
                ),
              ),
            ),
            actionsPadding: .all(10),
            actions: [
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() != true) {
                    return;
                  }
                  purchaseOrder.costDetails = costDetails;
                  navigator.pop();
                },

                child: Text('Edit'),
              ),
              ElevatedButton(
                onPressed: () => navigator.pop(),
                child: Text('Batal'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<DiscountDetail>?> _openDiscountDetail(
    List<DiscountDetail>? sourceDiscountDetails, {
    List<Widget>? description,
  }) {
    final scrollController = ScrollController();
    return showDialog<List<DiscountDetail>?>(
      context: context,
      builder: (context) {
        final discountDetails = (sourceDiscountDetails ?? []).toList();
        final navigator = Navigator.of(context);
        return StatefulBuilder(
          builder: (context, setStateDialog) => Center(
            child: AlertDialog(
              title: Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  Flexible(child: Text('Detail Diskon')),
                  IconButton(
                    onPressed: () => navigator.pop(),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              content: SizedBox(
                height: 1000,
                width: 1000,
                child: Scrollbar(
                  thumbVisibility: true,
                  trackVisibility: true,
                  thickness: 8,
                  controller: scrollController,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        ...?description,
                        TableForm<DiscountDetail>(
                          cellPadding: .all(10),
                          columns: [
                            TableFormColumn<DiscountDetail>(
                              name: 'Tipe',
                              headerBuilder: (context) => Text(
                                'Tipe',
                                textAlign: .right,
                                style: TextFormatter.titleStyle,
                              ),
                              rowBuilder: (context, object) =>
                                  DropdownMenu<DiscountDetailType>(
                                    width: 150,
                                    onSelected: (value) => setStateDialog(() {
                                      object.type = value ?? object.type;
                                    }),
                                    initialSelection: object.type,
                                    dropdownMenuEntries: DiscountDetailType
                                        .values
                                        .map<
                                          DropdownMenuEntry<DiscountDetailType>
                                        >(
                                          (value) =>
                                              DropdownMenuEntry<
                                                DiscountDetailType
                                              >(
                                                value: value,
                                                label: value.humanize(),
                                              ),
                                        )
                                        .toList(),
                                  ),
                            ),
                            TableFormColumn<DiscountDetail>(
                              name: 'Value',
                              headerBuilder: (context) => Text(
                                'Value',
                                textAlign: .right,
                                style: TextFormatter.titleStyle,
                              ),
                              rowBuilder: (context, object) {
                                if (object.type == .percentage) {
                                  return PercentageFormField(
                                    initialValue: Percentage(object.value),
                                    onChanged: (value) =>
                                        object.value = value?.value ?? 0,
                                  );
                                } else if (object.type == .nominal) {
                                  return MoneyFormField(
                                    initialValue: Money(object.value),
                                    onChanged: (value) =>
                                        object.value = value?.value ?? 0,
                                  );
                                } else {
                                  return NumberFormField<double>(
                                    initialValue: object.value,
                                    onChanged: (value) =>
                                        object.value = value ?? 0,
                                  );
                                }
                              },
                            ),
                            TableFormColumn<DiscountDetail>(
                              name: 'action',
                              desktopWidth: FixedColumnWidth(130),
                              headerBuilder: (context) => Row(
                                mainAxisAlignment: .spaceBetween,
                                children: [
                                  IconButton(
                                    onPressed: () => setStateDialog(() {
                                      discountDetails.add(DiscountDetail());
                                    }),
                                    icon: Icon(Icons.add),
                                  ),
                                  IconButton(
                                    onPressed: () => setStateDialog(() {
                                      discountDetails.clear();
                                    }),
                                    icon: Icon(Icons.delete),
                                  ),
                                ],
                              ),
                              rowBuilder: (context, object) => IconButton(
                                onPressed: () => setStateDialog(() {
                                  discountDetails.remove(object);
                                }),
                                icon: Icon(Icons.delete),
                              ),
                            ),
                          ],
                          rows: discountDetails,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actionsPadding: .all(10),
              actions: [
                ElevatedButton(
                  onPressed: () => navigator.pop(discountDetails),
                  child: Text('Edit'),
                ),
                ElevatedButton(
                  onPressed: () => navigator.pop(),
                  child: Text('Batal'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
