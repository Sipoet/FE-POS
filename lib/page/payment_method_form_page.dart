import 'package:fe_pos/model/bank.dart';
import 'package:fe_pos/model/payment_method.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PaymentMethodFormPage extends StatefulWidget {
  final PaymentMethod paymentMethod;
  const PaymentMethodFormPage({super.key, required this.paymentMethod});

  @override
  State<PaymentMethodFormPage> createState() => _PaymentMethodFormPageState();
}

class _PaymentMethodFormPageState extends State<PaymentMethodFormPage>
    with AutomaticKeepAliveClientMixin, LoadingPopup, HistoryPopup {
  final _formKey = GlobalKey<FormState>();
  PaymentMethod get paymentMethod => widget.paymentMethod;
  late final Server _server;
  late final Flash flash;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    flash = Flash(context);
    _server = context.read<Server>();
    super.initState();
  }

  void _submit() async {
    Map body = {
      'data': {
        'type': 'payment_method',
        'id': paymentMethod.id,
        'attributes': paymentMethod.toJson(),
      }
    };
    var request = paymentMethod.id == null
        ? _server.post('payment_methods', body: body)
        : _server.put('payment_methods/${paymentMethod.id}', body: body);

    request.then((response) {
      if ([200, 201].contains(response.statusCode)) {
        var data = response.data['data'];
        setState(() {
          PaymentMethod.fromJson(data,
              included: response.data['included'], model: paymentMethod);
          var tabManager = context.read<TabManager>();
          tabManager.changeTabHeader(
              widget, 'Edit Karyawan ${paymentMethod.name}');
        });

        flash.show(const Text('Berhasil disimpan'), MessageType.success);
      } else if (response.statusCode == 409) {
        var data = response.data;
        flash.showBanner(
            title: data['message'],
            description: (data['errors'] ?? []).join('\n'),
            messageType: MessageType.failed);
      }
    }, onError: (error, stackTrace) {
      _server.defaultErrorResponse(context: context, error: error);
    });
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
                    constraints:
                        BoxConstraints.loose(const Size.fromWidth(600)),
                    child: Form(
                        key: _formKey,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                decoration: const InputDecoration(
                                    labelText: 'Nama Metode Pembayaran',
                                    labelStyle: labelStyle,
                                    border: OutlineInputBorder()),
                                onSaved: (newValue) {
                                  paymentMethod.name = newValue.toString();
                                },
                                onChanged: (newValue) {
                                  paymentMethod.name = newValue.toString();
                                },
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Flexible(
                                child: AsyncDropdown<Bank>(
                                  path: '/banks',
                                  attributeKey: 'namabank',
                                  label: const Text(
                                    'Bank/Provider :',
                                    style: labelStyle,
                                  ),
                                  onSaved: (bank) {
                                    paymentMethod.bank = bank ?? Bank();
                                  },
                                  textOnSearch: (bank) =>
                                      "${bank.code} - ${bank.name}",
                                  converter: Bank.fromJson,
                                  selected: paymentMethod.bank,
                                  validator: (bank) {
                                    if (bank == null) {
                                      return 'harus diisi';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              DropdownMenu<PaymentType>(
                                  initialSelection: paymentMethod.paymentType,
                                  onSelected: ((value) =>
                                      paymentMethod.paymentType =
                                          value ?? PaymentType.other),
                                  dropdownMenuEntries: PaymentType.values
                                      .map<DropdownMenuEntry<PaymentType>>(
                                          (paymentType) => DropdownMenuEntry(
                                              value: paymentType,
                                              label: paymentType.humanize()))
                                      .toList()),
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 10, bottom: 10),
                                child: ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        flash.show(const Text('Loading'),
                                            MessageType.info);
                                        _submit();
                                      }
                                    },
                                    child: const Text('submit')),
                              )
                            ]))))));
  }
}
