import 'package:fe_pos/model/transfer.dart';
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

class TransferFormPage extends StatefulWidget {
  final Transfer transfer;
  const TransferFormPage({super.key, required this.transfer});

  @override
  State<TransferFormPage> createState() => _TransferFormPageState();
}

class _TransferFormPageState extends State<TransferFormPage>
    with
        AutomaticKeepAliveClientMixin,
        LoadingPopup,
        HistoryPopup,
        TextFormatter,
        DefaultResponse {
  late Flash flash;

  final _formKey = GlobalKey<FormState>();
  Transfer get transfer => widget.transfer;
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
    _columns = setting.tableColumn('ipos::TransferItem');

    if (transfer.id != null) {
      Future.delayed(Duration.zero, () => fetchTransfer());
    }
    super.initState();
  }

  void fetchTransfer() {
    showLoadingPopup();

    _server.get('transfers/show', queryParam: {
      'code': Uri.encodeComponent(transfer.id),
      'include': 'transfer_items,transfer_items.item'
    }).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          Transfer.fromJson(response.data['data'],
              included: response.data['included'], model: transfer);
          _source.setModels(transfer.transferItems, _columns);
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
                  //   visible: transfer.id != null,
                  //   child: ElevatedButton.icon(
                  //       onPressed: () => fetchHistoryByRecord('Transfer', transfer.id),
                  //       label: const Text('Riwayat'),
                  //       icon: const Icon(Icons.history)),
                  // ),
                  // const Divider(),
                  Visibility(
                    visible: setting.canShow('ipos::Transfer', 'notransaksi'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Transfer', 'notransaksi'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: transfer.code,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Transfer', 'kantordari'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Transfer', 'kantordari'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: transfer.sourceLocation,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Transfer', 'kantortujuan'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Transfer', 'kantortujuan'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: transfer.destLocation,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Transfer', 'user1'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText:
                                setting.columnName('ipos::Transfer', 'user1'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: transfer.userName,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Transfer', 'tanggal'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText:
                                setting.columnName('ipos::Transfer', 'tanggal'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: dateTimeFormat(transfer.datetime),
                      ),
                    ),
                  ),

                  Visibility(
                    visible: setting.canShow('ipos::Transfer', 'totalitem'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Transfer', 'totalitem'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: transfer.totalItem.toString(),
                      ),
                    ),
                  ),

                  Visibility(
                    visible: setting.canShow('ipos::Transfer', 'shiftkerja'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Transfer', 'shiftkerja'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: transfer.shift,
                      ),
                    ),
                  ),

                  Visibility(
                    visible: setting.canShow('ipos::Transfer', 'keterangan'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Transfer', 'keterangan'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        minLines: 3,
                        maxLines: 5,
                        initialValue: transfer.description,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: setting.canShow('ipos::Transfer', 'updated_at'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                'ipos::Transfer', 'updated_at'),
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        initialValue: transfer.updatedAt == null
                            ? ''
                            : dateTimeFormat(transfer.updatedAt!),
                      ),
                    ),
                  ),
                  const Text(
                    "Item Detail",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 500,
                    child: SyncDataTable<TransferItem>(
                      columns: _columns,
                      onLoaded: (stateManager) => _source = stateManager,
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
