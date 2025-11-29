import 'package:fe_pos/model/purchase_order.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/text_formatter.dart';
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
  late final TrinaGridStateManager _source;
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
    _columns = setting.tableColumn('ipos::PurchaseOrderItem')
      ..removeWhere((line) => line.name == 'notransaksi');
    if (purchaseOrder.id != null) {
      Future.delayed(Duration.zero, () => fetchPurchaseOrder());
    }
    super.initState();
  }

  void fetchPurchaseOrder() {
    showLoadingPopup();
    _server.get('purchase_orders/show', queryParam: {
      'code': Uri.encodeComponent(purchaseOrder.id),
      'include': 'purchase_order_items,purchase_order_items.item,supplier'
    }).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          purchaseOrder.setFromJson(response.data['data'],
              included: response.data['included'] ?? []);
          _source.setModels(purchaseOrder.purchaseItems, _columns);
        });
      }
    }, onError: (error) {
      defaultErrorResponse(error: error);
    }).whenComplete(() => hideLoadingPopup());
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
                        border: OutlineInputBorder()),
                    initialValue: margin.toString(),
                    onChanged: (value) =>
                        margin = double.tryParse(value) ?? margin,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  DropdownMenu<String>(
                    label: const Text(
                      'Tipe Pembulatan',
                      style: labelStyle,
                    ),
                    initialSelection: roundType,
                    onSelected: (value) => setstateDialog(() {
                      roundType = value ?? roundType;
                    }),
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: 'normal', label: 'Normal'),
                      DropdownMenuEntry(
                          value: 'ceil', label: 'Pembulatan atas'),
                      DropdownMenuEntry(
                          value: 'floor', label: 'Pembulatan bawah'),
                      DropdownMenuEntry(
                          value: 'mark', label: 'Pembulatan berdasarkan mark'),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: roundType == 'mark',
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Mark batasan',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
                      initialValue: markSeparator.toString(),
                      onChanged: (value) => markSeparator =
                          double.tryParse(value) ?? markSeparator,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: roundType == 'mark',
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Mark Atas',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
                      initialValue: markUpper.toString(),
                      onChanged: (value) =>
                          markUpper = double.tryParse(value) ?? markUpper,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: roundType == 'mark',
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Mark Bawah',
                          labelStyle: labelStyle,
                          border: OutlineInputBorder()),
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
        }).then((result) {
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
      final response = await _server.post('purchase_orders/code/update_price',
          body: dataParams);
      hideLoadingPopup();
      return response.statusCode == 200;
    } catch (e) {
      hideLoadingPopup();
      return false;
    }
  }

  static const labelStyle =
      TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
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
                      constraints:
                          BoxConstraints.loose(const Size.fromWidth(600)),
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
                                'ipos::PurchaseOrder', 'notransaksi'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::PurchaseOrder', 'notransaksi'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue: purchaseOrder.code,
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::PurchaseOrder', 'kodesupel'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::PurchaseOrder', 'kodesupel'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue:
                                    '${purchaseOrder.supplierCode} - ${purchaseOrder.supplierName}',
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::PurchaseOrder', 'kantortujuan'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::PurchaseOrder', 'kantortujuan'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue: purchaseOrder.destLocation,
                              ),
                            ),
                          ),
                          Visibility(
                            visible:
                                setting.canShow('ipos::PurchaseOrder', 'user1'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::PurchaseOrder', 'user1'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue: purchaseOrder.userName,
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::PurchaseOrder', 'tanggal'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::PurchaseOrder', 'tanggal'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue:
                                    dateTimeLocalFormat(purchaseOrder.datetime),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::PurchaseOrder', 'tglkirim'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::PurchaseOrder', 'tglkirim'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue: dateTimeLocalFormat(
                                    purchaseOrder.deliveredDate),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::PurchaseOrder', 'totalitem'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::PurchaseOrder', 'totalitem'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue:
                                    purchaseOrder.totalItem.toString(),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::PurchaseOrder', 'subtotal'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::PurchaseOrder', 'subtotal'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue:
                                    moneyFormat(purchaseOrder.subtotal),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::PurchaseOrder', 'potnomfaktur'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::PurchaseOrder', 'potnomfaktur'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue:
                                    moneyFormat(purchaseOrder.discountAmount),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::PurchaseOrder', 'biayalain'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::PurchaseOrder', 'biayalain'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue:
                                    moneyFormat(purchaseOrder.otherCost),
                              ),
                            ),
                          ),
                          Visibility(
                            visible:
                                setting.canShow('ipos::PurchaseOrder', 'pajak'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::PurchaseOrder', 'pajak'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue:
                                    moneyFormat(purchaseOrder.taxAmount),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::PurchaseOrder', 'totalakhir'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::PurchaseOrder', 'totalakhir'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue:
                                    moneyFormat(purchaseOrder.grandtotal),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::PurchaseOrder', 'payment_type'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::PurchaseOrder', 'payment_type'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue: purchaseOrder.paymentMethodType,
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::PurchaseOrder', 'bank_code'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::PurchaseOrder', 'bank_code'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue: purchaseOrder.bankCode,
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::PurchaseOrder', 'jmltunai'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::PurchaseOrder', 'jmltunai'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue:
                                    moneyFormat(purchaseOrder.cashAmount),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::PurchaseOrder', 'jmldebit'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::PurchaseOrder', 'jmldebit'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue:
                                    moneyFormat(purchaseOrder.debitCardAmount),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::PurchaseOrder', 'jmlkredit'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::PurchaseOrder', 'jmlkredit'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue:
                                    moneyFormat(purchaseOrder.creditCardAmount),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::PurchaseOrder', 'jmldeposit'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::PurchaseOrder', 'jmldeposit'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue:
                                    moneyFormat(purchaseOrder.emoneyAmount),
                              ),
                            ),
                          ),
                          Visibility(
                            visible:
                                setting.canShow('ipos::PurchaseOrder', 'ppn'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::PurchaseOrder', 'ppn'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue: purchaseOrder.taxType,
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::PurchaseOrder', 'keterangan'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::PurchaseOrder', 'keterangan'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
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
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Item Detail",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                          child: const Icon(Icons.table_rows_rounded)),
                    )
                  ],
                ),
                SizedBox(
                  height: 500,
                  child: SyncDataTable<PurchaseOrderItem>(
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
