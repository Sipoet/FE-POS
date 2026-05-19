import 'package:fe_pos/model/purchase_order.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_form_field.dart';
import 'package:fe_pos/widget/sync_data_table.dart';

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
  late final List<TableColumn> _columns;
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
    _columns = setting.tableColumn('purchaseOrderDetail')
      ..removeWhere((line) => line.name == 'notransaksi');
    _columns.insert(
      6,
      TableColumn<PurchaseOrderDetail>(
        clientWidth: 180,
        name: 'margin',
        humanizeName: 'Margin(%)',
        type: PercentageTableColumnType(),
        getValue: (model) {
          model as PurchaseOrderDetail;
          if (model.product == null) {
            return '';
          }
          final result = (model.product!.sellPrice - model.price) / model.price;
          if (result.isNaM) {
            return Percentage(0);
          }
          return Percentage(result.value);
        },
      ),
    );
    if (purchaseOrder.id != null) {
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
                    labelStyle: labelStyle,
                    border: OutlineInputBorder(),
                  ),
                  initialValue: margin.toString(),
                  onChanged: (value) =>
                      margin = double.tryParse(value) ?? margin,
                ),
                const SizedBox(height: 10),
                DropdownMenu<String>(
                  label: const Text('Tipe Pembulatan', style: labelStyle),
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
                      labelStyle: labelStyle,
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
                      labelStyle: labelStyle,
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
                      labelStyle: labelStyle,
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

  static const labelStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
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
            child: Column(
              children: [
                Column(
                  children: [
                    Container(
                      constraints: BoxConstraints.loose(
                        const Size.fromWidth(600),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Visibility(
                          //   visible: purchaseOrder.id != null,
                          //   child: ElevatedButton.icon(
                          //       onPressed: () => fetchHistoryByRecord('PurchaseOrder', purchaseOrder.id),
                          //       label: const Text('Riwayat'),
                          //       icon: const Icon(Icons.history)),
                          // ),
                          // const Divider(),
                          Visibility(
                            visible: setting.canShow(
                              'purchaseOrder',
                              'notransaksi',
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: setting.columnName(
                                    'purchaseOrder',
                                    'notransaksi',
                                  ),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder(),
                                ),
                                readOnly: true,
                                initialValue: purchaseOrder.code,
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                              'purchaseOrder',
                              'supplier',
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: AsyncDropdown<Supplier>(
                                label: Text(
                                  setting.columnName(
                                    'purchaseOrder',
                                    'kodesupel',
                                  ),
                                  style: labelStyle,
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
                          Visibility(
                            visible: setting.canShow(
                              'purchaseOrder',
                              'location',
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: AsyncDropdown<Location>(
                                label: Text(
                                  setting.columnName(
                                    'purchaseOrder',
                                    'location',
                                  ),
                                  style: labelStyle,
                                ),
                                modelClass: LocationClass(),
                                textOnSearch: (model) => model.name,
                                selected: purchaseOrder.location,
                              ),
                            ),
                          ),
                          // Visibility(
                          //   visible: setting.canShow('purchaseOrder', 'user1'),
                          //   child: Padding(
                          //     padding: const EdgeInsets.only(bottom: 10),
                          //     child: TextFormField(
                          //       decoration: InputDecoration(
                          //         labelText: setting.columnName(
                          //           'purchaseOrder',
                          //           'user1',
                          //         ),
                          //         labelStyle: labelStyle,
                          //         border: const OutlineInputBorder(),
                          //       ),
                          //       readOnly: true,
                          //       initialValue: purchaseOrder.userName,
                          //     ),
                          //   ),
                          // ),
                          Visibility(
                            visible: setting.canShow(
                              'purchaseOrder',
                              'transaction_date',
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: DateFormField(
                                label: Text(
                                  setting.columnName(
                                    'purchaseOrder',
                                    'transaction_date',
                                  ),
                                  style: labelStyle,
                                ),
                                dateType: DateType(),
                                readOnly: true,
                                initialValue: purchaseOrder.transactionDate,
                              ),
                            ),
                          ),

                          Visibility(
                            visible: setting.canShow(
                              'purchaseOrder',
                              'product_total',
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: setting.columnName(
                                    'purchaseOrder',
                                    'product_total',
                                  ),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder(),
                                ),
                                readOnly: true,
                                initialValue: purchaseOrder.productTotal
                                    .toString(),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                              'purchaseOrder',
                              'subtotal',
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: setting.columnName(
                                    'purchaseOrder',
                                    'subtotal',
                                  ),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder(),
                                ),
                                readOnly: true,
                                initialValue: moneyFormat(
                                  purchaseOrder.subtotal,
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                              'purchaseOrder',
                              'potnomfaktur',
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: setting.columnName(
                                    'purchaseOrder',
                                    'potnomfaktur',
                                  ),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder(),
                                ),
                                readOnly: true,
                                initialValue: moneyFormat(
                                  purchaseOrder.discountAmount,
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                              'purchaseOrder',
                              'cost_total',
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: setting.columnName(
                                    'purchaseOrder',
                                    'cost_total',
                                  ),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder(),
                                ),
                                readOnly: true,
                                initialValue: moneyFormat(
                                  purchaseOrder.costTotal,
                                ),
                              ),
                            ),
                          ),
                          // Visibility(
                          //   visible: setting.canShow('purchaseOrder', 'pajak'),
                          //   child: Padding(
                          //     padding: const EdgeInsets.only(bottom: 10),
                          //     child: TextFormField(
                          //       decoration: InputDecoration(
                          //         labelText: setting.columnName(
                          //           'purchaseOrder',
                          //           'pajak',
                          //         ),
                          //         labelStyle: labelStyle,
                          //         border: const OutlineInputBorder(),
                          //       ),
                          //       readOnly: true,
                          //       initialValue: moneyFormat(
                          //         purchaseOrder.taxAmount,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          Visibility(
                            visible: setting.canShow(
                              'purchaseOrder',
                              'totalakhir',
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: setting.columnName(
                                    'purchaseOrder',
                                    'totalakhir',
                                  ),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder(),
                                ),
                                readOnly: true,
                                initialValue: moneyFormat(
                                  purchaseOrder.grandtotal,
                                ),
                              ),
                            ),
                          ),
                          // Visibility(
                          //   visible: setting.canShow(
                          //     'purchaseOrder',
                          //     'payment_type',
                          //   ),
                          //   child: Padding(
                          //     padding: const EdgeInsets.only(bottom: 10),
                          //     child: TextFormField(
                          //       decoration: InputDecoration(
                          //         labelText: setting.columnName(
                          //           'purchaseOrder',
                          //           'payment_type',
                          //         ),
                          //         labelStyle: labelStyle,
                          //         border: const OutlineInputBorder(),
                          //       ),
                          //       readOnly: true,
                          //       initialValue: purchaseOrder.paymentMethodType,
                          //     ),
                          //   ),
                          // ),
                          // Visibility(
                          //   visible: setting.canShow(
                          //     'purchaseOrder',
                          //     'bank_code',
                          //   ),
                          //   child: Padding(
                          //     padding: const EdgeInsets.only(bottom: 10),
                          //     child: TextFormField(
                          //       decoration: InputDecoration(
                          //         labelText: setting.columnName(
                          //           'purchaseOrder',
                          //           'bank_code',
                          //         ),
                          //         labelStyle: labelStyle,
                          //         border: const OutlineInputBorder(),
                          //       ),
                          //       readOnly: true,
                          //       initialValue: purchaseOrder.bankCode,
                          //     ),
                          //   ),
                          // ),
                          // Visibility(
                          //   visible: setting.canShow(
                          //     'purchaseOrder',
                          //     'jmltunai',
                          //   ),
                          //   child: Padding(
                          //     padding: const EdgeInsets.only(bottom: 10),
                          //     child: TextFormField(
                          //       decoration: InputDecoration(
                          //         labelText: setting.columnName(
                          //           'purchaseOrder',
                          //           'jmltunai',
                          //         ),
                          //         labelStyle: labelStyle,
                          //         border: const OutlineInputBorder(),
                          //       ),
                          //       readOnly: true,
                          //       initialValue: moneyFormat(
                          //         purchaseOrder.cashAmount,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          // Visibility(
                          //   visible: setting.canShow(
                          //     'purchaseOrder',
                          //     'jmldebit',
                          //   ),
                          //   child: Padding(
                          //     padding: const EdgeInsets.only(bottom: 10),
                          //     child: TextFormField(
                          //       decoration: InputDecoration(
                          //         labelText: setting.columnName(
                          //           'purchaseOrder',
                          //           'jmldebit',
                          //         ),
                          //         labelStyle: labelStyle,
                          //         border: const OutlineInputBorder(),
                          //       ),
                          //       readOnly: true,
                          //       initialValue: moneyFormat(
                          //         purchaseOrder.debitCardAmount,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          // Visibility(
                          //   visible: setting.canShow(
                          //     'purchaseOrder',
                          //     'jmlkredit',
                          //   ),
                          //   child: Padding(
                          //     padding: const EdgeInsets.only(bottom: 10),
                          //     child: TextFormField(
                          //       decoration: InputDecoration(
                          //         labelText: setting.columnName(
                          //           'purchaseOrder',
                          //           'jmlkredit',
                          //         ),
                          //         labelStyle: labelStyle,
                          //         border: const OutlineInputBorder(),
                          //       ),
                          //       readOnly: true,
                          //       initialValue: moneyFormat(
                          //         purchaseOrder.creditCardAmount,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          // Visibility(
                          //   visible: setting.canShow(
                          //     'purchaseOrder',
                          //     'jmldeposit',
                          //   ),
                          //   child: Padding(
                          //     padding: const EdgeInsets.only(bottom: 10),
                          //     child: TextFormField(
                          //       decoration: InputDecoration(
                          //         labelText: setting.columnName(
                          //           'purchaseOrder',
                          //           'jmldeposit',
                          //         ),
                          //         labelStyle: labelStyle,
                          //         border: const OutlineInputBorder(),
                          //       ),
                          //       readOnly: true,
                          //       initialValue: moneyFormat(
                          //         purchaseOrder.emoneyAmount,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          // Visibility(
                          //   visible: setting.canShow('purchaseOrder', 'ppn'),
                          //   child: Padding(
                          //     padding: const EdgeInsets.only(bottom: 10),
                          //     child: TextFormField(
                          //       decoration: InputDecoration(
                          //         labelText: setting.columnName(
                          //           'purchaseOrder',
                          //           'ppn',
                          //         ),
                          //         labelStyle: labelStyle,
                          //         border: const OutlineInputBorder(),
                          //       ),
                          //       readOnly: true,
                          //       initialValue: purchaseOrder.taxType,
                          //     ),
                          //   ),
                          // ),
                          Visibility(
                            visible: setting.canShow(
                              'purchaseOrder',
                              'description',
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: setting.columnName(
                                    'purchaseOrder',
                                    'description',
                                  ),
                                  labelStyle: labelStyle,
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
                        ],
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
                            child: const Text('Ganti Harga Jual'),
                            onPressed: () {
                              openUpdatePriceForm();
                            },
                          ),
                          MenuItemButton(
                            child: const Text('Refresh item'),
                            onPressed: () {
                              fetchPurchaseOrder();
                            },
                          ),
                        ],
                        controller: menuController,
                        onHover: (isHover) {
                          if (isHover) {
                            menuController.close();
                          }
                        },
                        child: const Icon(Icons.table_rows_rounded),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 500,
                  child: SyncDataTable<PurchaseOrderDetail>(
                    columns: _columns,
                    showSummary: true,
                    onLoaded: (stateManager) => _source = stateManager,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
