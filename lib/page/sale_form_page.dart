import 'package:fe_pos/model/sale.dart';
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

class SaleFormPage extends StatefulWidget {
  final Sale sale;
  const SaleFormPage({super.key, required this.sale});

  @override
  State<SaleFormPage> createState() => _SaleFormPageState();
}

class _SaleFormPageState extends State<SaleFormPage>
    with
        AutomaticKeepAliveClientMixin,
        LoadingPopup,
        HistoryPopup,
        TextFormatter,
        DefaultResponse {
  late Flash flash;

  final _formKey = GlobalKey<FormState>();
  Sale get sale => widget.sale;
  late final Server _server;
  late final Setting setting;
  late final PlutoGridStateManager _source;
  late final List<TableColumn> _columns;
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    flash = Flash();
    setting = context.read<Setting>();
    _server = context.read<Server>();

    _columns = setting.tableColumn('ipos::SaleItem');

    if (sale.id != null) {
      Future.delayed(Duration.zero, () => fetchSale());
    }
    super.initState();
  }

  void fetchSale() {
    showLoadingPopup();

    _server.get('sales/show', queryParam: {
      'code': Uri.encodeComponent(sale.id),
      'include': 'sale_items'
    }).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          Sale.fromJson(response.data['data'],
              included: response.data['included'], model: sale);
          _source.setModels(sale.saleItems, _columns);
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    constraints:
                        BoxConstraints.loose(const Size.fromWidth(600)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Visibility(
                        //   visible: sale.id != null,
                        //   child: ElevatedButton.icon(
                        //       onPressed: () => fetchHistoryByRecord('Sale', sale.id),
                        //       label: const Text('Riwayat'),
                        //       icon: const Icon(Icons.history)),
                        // ),
                        // const Divider(),
                        Visibility(
                          visible: setting.canShow('ipos::Sale', 'notransaksi'),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: TextFormField(
                              decoration: InputDecoration(
                                  labelText: setting.columnName(
                                      'ipos::Sale', 'notransaksi'),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder()),
                              readOnly: true,
                              initialValue: sale.code,
                            ),
                          ),
                        ),
                        Visibility(
                          visible: setting.canShow('ipos::Sale', 'user1'),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              decoration: InputDecoration(
                                  labelText:
                                      setting.columnName('ipos::Sale', 'user1'),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder()),
                              readOnly: true,
                              initialValue: sale.userName,
                            ),
                          ),
                        ),
                        Visibility(
                          visible: setting.canShow('ipos::Sale', 'tanggal'),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              decoration: InputDecoration(
                                  labelText: setting.columnName(
                                      'ipos::Sale', 'tanggal'),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder()),
                              readOnly: true,
                              initialValue: dateTimeFormat(sale.datetime),
                            ),
                          ),
                        ),

                        Visibility(
                          visible: setting.canShow('ipos::Sale', 'totalitem'),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              decoration: InputDecoration(
                                  labelText: setting.columnName(
                                      'ipos::Sale', 'totalitem'),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder()),
                              readOnly: true,
                              initialValue: sale.totalItem.toString(),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: setting.canShow('ipos::Sale', 'subtotal'),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              decoration: InputDecoration(
                                  labelText: setting.columnName(
                                      'ipos::Sale', 'subtotal'),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder()),
                              readOnly: true,
                              initialValue: moneyFormat(sale.subtotal),
                            ),
                          ),
                        ),
                        Visibility(
                          visible:
                              setting.canShow('ipos::Sale', 'potnomfaktur'),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              decoration: InputDecoration(
                                  labelText: setting.columnName(
                                      'ipos::Sale', 'potnomfaktur'),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder()),
                              readOnly: true,
                              initialValue: moneyFormat(sale.discountAmount),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: setting.canShow('ipos::Sale', 'biayalain'),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              decoration: InputDecoration(
                                  labelText: setting.columnName(
                                      'ipos::Sale', 'biayalain'),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder()),
                              readOnly: true,
                              initialValue: moneyFormat(sale.otherCost),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: setting.canShow('ipos::Sale', 'pajak'),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              decoration: InputDecoration(
                                  labelText:
                                      setting.columnName('ipos::Sale', 'pajak'),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder()),
                              readOnly: true,
                              initialValue: moneyFormat(sale.taxAmount),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: setting.canShow('ipos::Sale', 'totalakhir'),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              decoration: InputDecoration(
                                  labelText: setting.columnName(
                                      'ipos::Sale', 'totalakhir'),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder()),
                              readOnly: true,
                              initialValue: moneyFormat(sale.grandtotal),
                            ),
                          ),
                        ),
                        Visibility(
                          visible:
                              setting.canShow('ipos::Sale', 'payment_type'),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              decoration: InputDecoration(
                                  labelText: setting.columnName(
                                      'ipos::Sale', 'payment_type'),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder()),
                              readOnly: true,
                              initialValue: sale.paymentMethodType,
                            ),
                          ),
                        ),
                        Visibility(
                          visible: setting.canShow('ipos::Sale', 'bank_code'),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              decoration: InputDecoration(
                                  labelText: setting.columnName(
                                      'ipos::Sale', 'bank_code'),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder()),
                              readOnly: true,
                              initialValue: sale.bankCode,
                            ),
                          ),
                        ),
                        Visibility(
                          visible: setting.canShow('ipos::Sale', 'jmltunai'),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              decoration: InputDecoration(
                                  labelText: setting.columnName(
                                      'ipos::Sale', 'jmltunai'),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder()),
                              readOnly: true,
                              initialValue: moneyFormat(sale.cashAmount),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: setting.canShow('ipos::Sale', 'jmldebit'),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              decoration: InputDecoration(
                                  labelText: setting.columnName(
                                      'ipos::Sale', 'jmldebit'),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder()),
                              readOnly: true,
                              initialValue: moneyFormat(sale.debitCardAmount),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: setting.canShow('ipos::Sale', 'jmlkk'),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              decoration: InputDecoration(
                                  labelText:
                                      setting.columnName('ipos::Sale', 'jmlkk'),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder()),
                              readOnly: true,
                              initialValue: moneyFormat(sale.creditCardAmount),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: setting.canShow('ipos::Sale', 'jmlemoney'),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              decoration: InputDecoration(
                                  labelText: setting.columnName(
                                      'ipos::Sale', 'jmlemoney'),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder()),
                              readOnly: true,
                              initialValue: moneyFormat(sale.emoneyAmount),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: setting.canShow('ipos::Sale', 'ppn'),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              decoration: InputDecoration(
                                  labelText:
                                      setting.columnName('ipos::Sale', 'ppn'),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder()),
                              readOnly: true,
                              initialValue: sale.taxType,
                            ),
                          ),
                        ),
                        Visibility(
                          visible: setting.canShow('ipos::Sale', 'keterangan'),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              decoration: InputDecoration(
                                  labelText: setting.columnName(
                                      'ipos::Sale', 'keterangan'),
                                  labelStyle: labelStyle,
                                  border: const OutlineInputBorder()),
                              readOnly: true,
                              minLines: 3,
                              maxLines: 5,
                              initialValue: sale.description,
                            ),
                          ),
                        ),
                      ],
                    )),
              ),
              const Text(
                "Item Detail",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 500,
                child: SyncDataTable<SaleItem>(
                  key: const ObjectKey('saleItemDetail'),
                  columns: _columns,
                  onLoaded: (stateManager) => _source = stateManager,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
