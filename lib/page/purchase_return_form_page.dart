import 'package:fe_pos/model/purchase_return.dart';
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

class PurchaseReturnFormPage extends StatefulWidget {
  final PurchaseReturn purchaseReturn;
  const PurchaseReturnFormPage({super.key, required this.purchaseReturn});

  @override
  State<PurchaseReturnFormPage> createState() => _PurchaseReturnFormPageState();
}

class _PurchaseReturnFormPageState extends State<PurchaseReturnFormPage>
    with
        AutomaticKeepAliveClientMixin,
        LoadingPopup,
        HistoryPopup,
        TextFormatter,
        DefaultResponse {
  late Flash flash;

  final _formKey = GlobalKey<FormState>();
  PurchaseReturn get purchaseReturn => widget.purchaseReturn;
  late final Server _server;
  late final Setting setting;
  late final TrinaGridStateManager _source;
  late final List<TableColumn> _columns;
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    flash = Flash();
    setting = context.read<Setting>();
    _server = context.read<Server>();
    _columns = setting.tableColumn('ipos::PurchaseReturnItem');
    if (purchaseReturn.id != null) {
      Future.delayed(Duration.zero, () => fetchPurchaseReturn());
    }
    super.initState();
  }

  void fetchPurchaseReturn() {
    showLoadingPopup();

    _server.get('purchase_returns/show', queryParam: {
      'code': Uri.encodeComponent(purchaseReturn.id),
      'include': 'purchase_return_items,purchase_return_items.item,supplier'
    }).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          purchaseReturn.setFromJson(response.data['data'],
              included: response.data['included']);
          _source.setModels(purchaseReturn.purchaseItems, _columns);
        });
      }
    }, onError: (error) {
      defaultErrorResponse(error: error);
    }).whenComplete(() => hideLoadingPopup());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const labelStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  constraints: BoxConstraints.loose(const Size.fromWidth(600)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Visibility(
                      //   visible: purchaseReturn.id != null,
                      //   child: ElevatedButton.icon(
                      //       onPressed: () => fetchHistoryByRecord('PurchaseReturn', purchaseReturn.id),
                      //       label: const Text('Riwayat'),
                      //       icon: const Icon(Icons.history)),
                      // ),
                      // const Divider(),
                      Visibility(
                        visible: setting.canShow(
                            'ipos::PurchaseReturn', 'notransaksi'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::PurchaseReturn', 'notransaksi'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: purchaseReturn.code,
                          ),
                        ),
                      ),
                      Visibility(
                        visible: setting.canShow(
                            'ipos::PurchaseReturn', 'kodesupel'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::PurchaseReturn', 'kodesupel'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue:
                                "${purchaseReturn.supplierCode} - ${purchaseReturn.supplierName}",
                          ),
                        ),
                      ),
                      Visibility(
                        visible: setting.canShow(
                            'ipos::PurchaseReturn', 'kantortujuan'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::PurchaseReturn', 'kantortujuan'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: purchaseReturn.destLocation,
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            setting.canShow('ipos::PurchaseReturn', 'user1'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::PurchaseReturn', 'user1'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: purchaseReturn.userName,
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            setting.canShow('ipos::PurchaseReturn', 'tanggal'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::PurchaseReturn', 'tanggal'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue:
                                dateTimeFormat(purchaseReturn.datetime),
                          ),
                        ),
                      ),

                      Visibility(
                        visible: setting.canShow(
                            'ipos::PurchaseReturn', 'totalitem'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::PurchaseReturn', 'totalitem'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: purchaseReturn.totalItem.toString(),
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            setting.canShow('ipos::PurchaseReturn', 'subtotal'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::PurchaseReturn', 'subtotal'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: moneyFormat(purchaseReturn.subtotal),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: setting.canShow(
                            'ipos::PurchaseReturn', 'potnomfaktur'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::PurchaseReturn', 'potnomfaktur'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue:
                                moneyFormat(purchaseReturn.discountAmount),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: setting.canShow(
                            'ipos::PurchaseReturn', 'biayalain'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::PurchaseReturn', 'biayalain'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: moneyFormat(purchaseReturn.otherCost),
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            setting.canShow('ipos::PurchaseReturn', 'pajak'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::PurchaseReturn', 'pajak'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: moneyFormat(purchaseReturn.taxAmount),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: setting.canShow(
                            'ipos::PurchaseReturn', 'totalakhir'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::PurchaseReturn', 'totalakhir'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue:
                                moneyFormat(purchaseReturn.grandtotal),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: setting.canShow(
                            'ipos::PurchaseReturn', 'payment_type'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::PurchaseReturn', 'payment_type'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: purchaseReturn.paymentMethodType,
                          ),
                        ),
                      ),
                      Visibility(
                        visible: setting.canShow(
                            'ipos::PurchaseReturn', 'bank_code'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::PurchaseReturn', 'bank_code'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: purchaseReturn.bankCode,
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            setting.canShow('ipos::PurchaseReturn', 'jmltunai'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::PurchaseReturn', 'jmltunai'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue:
                                moneyFormat(purchaseReturn.cashAmount),
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            setting.canShow('ipos::PurchaseReturn', 'jmldebit'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::PurchaseReturn', 'jmldebit'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue:
                                moneyFormat(purchaseReturn.debitCardAmount),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: setting.canShow(
                            'ipos::PurchaseReturn', 'jmlkredit'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::PurchaseReturn', 'jmlkredit'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue:
                                moneyFormat(purchaseReturn.creditCardAmount),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: setting.canShow(
                            'ipos::PurchaseReturn', 'jmldeposit'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::PurchaseReturn', 'jmldeposit'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue:
                                moneyFormat(purchaseReturn.emoneyAmount),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: setting.canShow('ipos::PurchaseReturn', 'ppn'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::PurchaseReturn', 'ppn'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: purchaseReturn.taxType,
                          ),
                        ),
                      ),
                      Visibility(
                        visible: setting.canShow(
                            'ipos::PurchaseReturn', 'keterangan'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::PurchaseReturn', 'keterangan'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            minLines: 3,
                            maxLines: 5,
                            initialValue: purchaseReturn.description,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Item Detail",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 500,
                  child: SyncDataTable<PurchaseReturnItem>(
                    columns: _columns,
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
