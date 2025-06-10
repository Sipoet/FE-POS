import 'package:fe_pos/model/consignment_in_order.dart';
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

class ConsignmentInOrderFormPage extends StatefulWidget {
  final ConsignmentInOrder consignmentInOrder;
  const ConsignmentInOrderFormPage(
      {super.key, required this.consignmentInOrder});

  @override
  State<ConsignmentInOrderFormPage> createState() =>
      _ConsignmentInOrderFormPageState();
}

class _ConsignmentInOrderFormPageState extends State<ConsignmentInOrderFormPage>
    with
        AutomaticKeepAliveClientMixin,
        LoadingPopup,
        HistoryPopup,
        TextFormatter,
        DefaultResponse {
  late Flash flash;

  final _formKey = GlobalKey<FormState>();
  ConsignmentInOrder get consignmentInOrder => widget.consignmentInOrder;
  late final Server _server;
  late final Setting setting;
  late final PlutoGridStateManager _source;
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
    if (consignmentInOrder.id != null) {
      Future.delayed(Duration.zero, () => fetchConsignmentInOrder());
    }
    super.initState();
  }

  void fetchConsignmentInOrder() {
    showLoadingPopup();
    _server.get('consignment_in_orders/show', queryParam: {
      'code': Uri.encodeComponent(consignmentInOrder.id),
      'include': 'purchase_order_items,purchase_order_items.item,supplier'
    }).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          ConsignmentInOrder.fromJson(response.data['data'],
              included: response.data['included'] ?? [],
              model: consignmentInOrder);
          _source.setModels(consignmentInOrder.purchaseOrderItems, _columns);
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
      if (result == true) fetchConsignmentInOrder();
    });
  }

  Future<bool> updatePrice() async {
    showLoadingPopup();
    final dataParams = {
      'code': consignmentInOrder.code,
      'margin': margin,
      'round_type': roundType,
      'mark_upper': markUpper,
      'mark_lower': markLower,
      'mark_separator': markSeparator,
    };
    try {
      final response = await _server
          .post('consignment_in_orders/code/update_price', body: dataParams);
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
                          //   visible: consignmentInOrder.id != null,
                          //   child: ElevatedButton.icon(
                          //       onPressed: () => fetchHistoryByRecord('ConsignmentInOrder', consignmentInOrder.id),
                          //       label: const Text('Riwayat'),
                          //       icon: const Icon(Icons.history)),
                          // ),
                          // const Divider(),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::ConsignmentInOrder', 'notransaksi'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::ConsignmentInOrder',
                                        'notransaksi'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue: consignmentInOrder.code,
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::ConsignmentInOrder', 'kodesupel'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::ConsignmentInOrder',
                                        'kodesupel'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue:
                                    '${consignmentInOrder.supplierCode} - ${consignmentInOrder.supplierName}',
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::ConsignmentInOrder', 'kantortujuan'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::ConsignmentInOrder',
                                        'kantortujuan'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue: consignmentInOrder.destLocation,
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::ConsignmentInOrder', 'user1'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::ConsignmentInOrder', 'user1'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue: consignmentInOrder.userName,
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::ConsignmentInOrder', 'tanggal'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::ConsignmentInOrder', 'tanggal'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue:
                                    dateTimeFormat(consignmentInOrder.datetime),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::ConsignmentInOrder', 'tglkirim'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::ConsignmentInOrder', 'tglkirim'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue: dateTimeFormat(
                                    consignmentInOrder.deliveredDate),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::ConsignmentInOrder', 'totalitem'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::ConsignmentInOrder',
                                        'totalitem'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue:
                                    consignmentInOrder.totalItem.toString(),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::ConsignmentInOrder', 'subtotal'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::ConsignmentInOrder', 'subtotal'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue:
                                    moneyFormat(consignmentInOrder.subtotal),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::ConsignmentInOrder', 'potnomfaktur'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::ConsignmentInOrder',
                                        'potnomfaktur'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue: moneyFormat(
                                    consignmentInOrder.discountAmount),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::ConsignmentInOrder', 'biayalain'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::ConsignmentInOrder',
                                        'biayalain'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue:
                                    moneyFormat(consignmentInOrder.otherCost),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::ConsignmentInOrder', 'pajak'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::ConsignmentInOrder', 'pajak'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue:
                                    moneyFormat(consignmentInOrder.taxAmount),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::ConsignmentInOrder', 'totalakhir'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::ConsignmentInOrder',
                                        'totalakhir'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue:
                                    moneyFormat(consignmentInOrder.grandtotal),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::ConsignmentInOrder', 'payment_type'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::ConsignmentInOrder',
                                        'payment_type'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue:
                                    consignmentInOrder.paymentMethodType,
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::ConsignmentInOrder', 'bank_code'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::ConsignmentInOrder',
                                        'bank_code'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue: consignmentInOrder.bankCode,
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::ConsignmentInOrder', 'jmltunai'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::ConsignmentInOrder', 'jmltunai'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue:
                                    moneyFormat(consignmentInOrder.cashAmount),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::ConsignmentInOrder', 'jmldebit'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::ConsignmentInOrder', 'jmldebit'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue: moneyFormat(
                                    consignmentInOrder.debitCardAmount),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::ConsignmentInOrder', 'jmlkredit'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::ConsignmentInOrder',
                                        'jmlkredit'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue: moneyFormat(
                                    consignmentInOrder.creditCardAmount),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::ConsignmentInOrder', 'jmldeposit'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::ConsignmentInOrder',
                                        'jmldeposit'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue: moneyFormat(
                                    consignmentInOrder.emoneyAmount),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::ConsignmentInOrder', 'ppn'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::ConsignmentInOrder', 'ppn'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                initialValue: consignmentInOrder.taxType,
                              ),
                            ),
                          ),
                          Visibility(
                            visible: setting.canShow(
                                'ipos::ConsignmentInOrder', 'keterangan'),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    labelText: setting.columnName(
                                        'ipos::ConsignmentInOrder',
                                        'keterangan'),
                                    labelStyle: labelStyle,
                                    border: const OutlineInputBorder()),
                                readOnly: true,
                                minLines: 3,
                                maxLines: 5,
                                initialValue: consignmentInOrder.description,
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
                                fetchConsignmentInOrder();
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
