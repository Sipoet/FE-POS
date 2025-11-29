import 'package:fe_pos/model/consignment_in.dart';
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

class ConsignmentInFormPage extends StatefulWidget {
  final ConsignmentIn consignmentIn;
  const ConsignmentInFormPage({super.key, required this.consignmentIn});

  @override
  State<ConsignmentInFormPage> createState() => _ConsignmentInFormPageState();
}

class _ConsignmentInFormPageState extends State<ConsignmentInFormPage>
    with
        AutomaticKeepAliveClientMixin,
        LoadingPopup,
        HistoryPopup,
        TextFormatter,
        DefaultResponse {
  late Flash flash;

  final _formKey = GlobalKey<FormState>();
  ConsignmentIn get consignmentIn => widget.consignmentIn;
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
    _columns = setting.tableColumn('ipos::PurchaseItem');
    if (consignmentIn.id != null) {
      Future.delayed(Duration.zero, () => fetchConsignmentIn());
    }
    super.initState();
  }

  void fetchConsignmentIn() {
    showLoadingPopup();

    _server.get('consignment_ins/show', queryParam: {
      'code': Uri.encodeComponent(consignmentIn.id),
      'include':
          'purchase_items,purchase_items.item,supplier,purchase_items.item_report'
    }).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          consignmentIn.setFromJson(
            response.data['data'],
            included: response.data['included'],
          );
          _source.setModels(consignmentIn.purchaseItems, _columns);
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
                    updatePrice().then((result) {
                      navigator.pop(result);
                      flash.show(Text('sukses update harga jual'),
                          ToastificationType.success);
                    });
                  },
                ),
              ],
            ),
          );
        }).then((result) {
      if (result == true) fetchConsignmentIn();
    });
  }

  Future<bool> updatePrice() async {
    showLoadingPopup();
    final dataParams = {
      'code': consignmentIn.code,
      'margin': margin,
      'round_type': roundType,
      'mark_upper': markUpper,
      'mark_lower': markLower,
      'mark_separator': markSeparator,
    };
    try {
      final response = await _server.post('consignment_ins/code/update_price',
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
                Container(
                  constraints: BoxConstraints.loose(const Size.fromWidth(600)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Visibility(
                      //   visible: consignmentIn.id != null,
                      //   child: ElevatedButton.icon(
                      //       onPressed: () => fetchHistoryByRecord('ConsignmentIn', consignmentIn.id),
                      //       label: const Text('Riwayat'),
                      //       icon: const Icon(Icons.history)),
                      // ),
                      // const Divider(),
                      Visibility(
                        visible: setting.canShow(
                            'ipos::ConsignmentIn', 'notransaksi'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::ConsignmentIn', 'notransaksi'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: consignmentIn.code,
                          ),
                        ),
                      ),
                      Visibility(
                        visible: setting.canShow(
                            'ipos::ConsignmentIn', 'notrsorder'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::ConsignmentIn', 'notrsorder'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: consignmentIn.orderCode,
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            setting.canShow('ipos::ConsignmentIn', 'kodesupel'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::ConsignmentIn', 'kodesupel'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue:
                                "${consignmentIn.supplierCode} - ${consignmentIn.supplierName}",
                          ),
                        ),
                      ),
                      Visibility(
                        visible: setting.canShow(
                            'ipos::ConsignmentIn', 'kantortujuan'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::ConsignmentIn', 'kantortujuan'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: consignmentIn.destLocation,
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            setting.canShow('ipos::ConsignmentIn', 'user1'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::ConsignmentIn', 'user1'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: consignmentIn.userName,
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            setting.canShow('ipos::ConsignmentIn', 'note_date'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::ConsignmentIn', 'note_date'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: consignmentIn.noteDate == null
                                ? null
                                : dateTimeLocalFormat(
                                    consignmentIn.noteDate as DateTime),
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            setting.canShow('ipos::ConsignmentIn', 'tanggal'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::ConsignmentIn', 'tanggal'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue:
                                dateTimeLocalFormat(consignmentIn.datetime),
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            setting.canShow('ipos::ConsignmentIn', 'totalitem'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::ConsignmentIn', 'totalitem'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: consignmentIn.totalItem.toString(),
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            setting.canShow('ipos::ConsignmentIn', 'subtotal'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::ConsignmentIn', 'subtotal'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: moneyFormat(consignmentIn.subtotal),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: setting.canShow(
                            'ipos::ConsignmentIn', 'potnomfaktur'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::ConsignmentIn', 'potnomfaktur'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue:
                                moneyFormat(consignmentIn.discountAmount),
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            setting.canShow('ipos::ConsignmentIn', 'biayalain'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::ConsignmentIn', 'biayalain'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: moneyFormat(consignmentIn.otherCost),
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            setting.canShow('ipos::ConsignmentIn', 'pajak'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::ConsignmentIn', 'pajak'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: moneyFormat(consignmentIn.taxAmount),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: setting.canShow(
                            'ipos::ConsignmentIn', 'totalakhir'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::ConsignmentIn', 'totalakhir'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: moneyFormat(consignmentIn.grandtotal),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: setting.canShow(
                            'ipos::ConsignmentIn', 'payment_type'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::ConsignmentIn', 'payment_type'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: consignmentIn.paymentMethodType,
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            setting.canShow('ipos::ConsignmentIn', 'bank_code'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::ConsignmentIn', 'bank_code'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: consignmentIn.bankCode,
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            setting.canShow('ipos::ConsignmentIn', 'jmltunai'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::ConsignmentIn', 'jmltunai'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: moneyFormat(consignmentIn.cashAmount),
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            setting.canShow('ipos::ConsignmentIn', 'jmldebit'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::ConsignmentIn', 'jmldebit'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue:
                                moneyFormat(consignmentIn.debitCardAmount),
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            setting.canShow('ipos::ConsignmentIn', 'jmlkredit'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::ConsignmentIn', 'jmlkredit'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue:
                                moneyFormat(consignmentIn.creditCardAmount),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: setting.canShow(
                            'ipos::ConsignmentIn', 'jmldeposit'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::ConsignmentIn', 'jmldeposit'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue:
                                moneyFormat(consignmentIn.emoneyAmount),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: setting.canShow('ipos::ConsignmentIn', 'ppn'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::ConsignmentIn', 'ppn'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            initialValue: consignmentIn.taxType,
                          ),
                        ),
                      ),
                      Visibility(
                        visible: setting.canShow(
                            'ipos::ConsignmentIn', 'keterangan'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            decoration: InputDecoration(
                                labelText: setting.columnName(
                                    'ipos::ConsignmentIn', 'keterangan'),
                                labelStyle: labelStyle,
                                border: const OutlineInputBorder()),
                            readOnly: true,
                            minLines: 3,
                            maxLines: 5,
                            initialValue: consignmentIn.description,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                              child: const Text('refresh item'),
                              onPressed: () {
                                fetchConsignmentIn();
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
                  child: SyncDataTable<PurchaseItem>(
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
