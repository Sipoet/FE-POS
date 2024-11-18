import 'package:fe_pos/model/purchase.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/sync_data_table.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

class PurchaseFormPage extends StatefulWidget {
  final Purchase purchase;
  const PurchaseFormPage({super.key, required this.purchase});

  @override
  State<PurchaseFormPage> createState() => _PurchaseFormPageState();
}

class _PurchaseFormPageState extends State<PurchaseFormPage>
    with
        AutomaticKeepAliveClientMixin,
        LoadingPopup,
        HistoryPopup,
        TextFormatter {
  late Flash flash;

  final _formKey = GlobalKey<FormState>();
  Purchase get purchase => widget.purchase;
  late final Server _server;
  late final Setting setting;
  late final SyncDataTableSource<PurchaseItem> _source;
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    flash = Flash(context);
    setting = context.read<Setting>();
    _server = context.read<Server>();

    _source = SyncDataTableSource<PurchaseItem>(
        columns: setting.tableColumn('ipos::PurchaseItem'),
        sortColumn: setting.tableColumn('ipos::PurchaseItem')[1]);

    if (purchase.id != null) {
      Future.delayed(Duration.zero, () => fetchPurchase());
    }
    super.initState();
  }

  void fetchPurchase() {
    showLoadingPopup();

    _server.get('purchases/show', queryParam: {
      'code': Uri.encodeComponent(purchase.id),
      'include': 'purchase_items,purchase_items.item'
    }).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          Purchase.fromJson(response.data['data'],
              included: response.data['included'], model: purchase);
          _source.setData(purchase.purchaseItems);
        });
      }
    }, onError: (error) {
      _server.defaultErrorResponse(context: context, error: error);
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
          child: Container(
            constraints: BoxConstraints.loose(const Size.fromWidth(600)),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visibility(
                  //   visible: purchase.id != null,
                  //   child: ElevatedButton.icon(
                  //       onPressed: () => fetchHistoryByRecord('Purchase', purchase.id),
                  //       label: const Text('Riwayat'),
                  //       icon: const Icon(Icons.history)),
                  // ),
                  // const Divider(),
                  Visibility(
                    visible: setting.canShow('ipos::Purchase', 'notransaksi'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Purchase', 'notransaksi'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: purchase.code,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Purchase', 'notrsorder'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Purchase', 'notrsorder'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: purchase.orderCode,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Purchase', 'kantortujuan'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Purchase', 'kantortujuan'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: purchase.destLocation,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Purchase', 'user1'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText:
                                setting.columnName('ipos::Purchase', 'user1'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: purchase.userName,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Purchase', 'tanggal'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText:
                                setting.columnName('ipos::Purchase', 'tanggal'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: dateTimeFormat(purchase.datetime),
                      ),
                    ),
                  ),

                  Visibility(
                    visible: setting.canShow('ipos::Purchase', 'totalitem'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Purchase', 'totalitem'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: purchase.totalItem.toString(),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Purchase', 'subtotal'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Purchase', 'subtotal'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: moneyFormat(purchase.subtotal),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Purchase', 'potnomfaktur'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Purchase', 'potnomfaktur'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: moneyFormat(purchase.discountAmount),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Purchase', 'biayalain'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Purchase', 'biayalain'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: moneyFormat(purchase.otherCost),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Purchase', 'pajak'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText:
                                setting.columnName('ipos::Purchase', 'pajak'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: moneyFormat(purchase.taxAmount),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Purchase', 'totalakhir'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Purchase', 'totalakhir'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: moneyFormat(purchase.grandtotal),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Purchase', 'payment_type'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Purchase', 'payment_type'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: purchase.paymentMethodType,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Purchase', 'bank_code'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Purchase', 'bank_code'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: purchase.bankCode,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Purchase', 'jmltunai'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Purchase', 'jmltunai'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: moneyFormat(purchase.cashAmount),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Purchase', 'jmldebit'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Purchase', 'jmldebit'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: moneyFormat(purchase.debitCardAmount),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Purchase', 'jmlkredit'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Purchase', 'jmlkredit'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: moneyFormat(purchase.creditCardAmount),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Purchase', 'jmldeposit'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Purchase', 'jmldeposit'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: moneyFormat(purchase.emoneyAmount),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Purchase', 'ppn'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText:
                                setting.columnName('ipos::Purchase', 'ppn'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: purchase.taxType,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Purchase', 'keterangan'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Purchase', 'keterangan'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        minLines: 3,
                        maxLines: 5,
                        initialValue: purchase.description,
                      ),
                    ),
                  ),
                  const Text(
                    "Item Detail",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 500,
                    child: SyncDataTable(
                      controller: _source,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
