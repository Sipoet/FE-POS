import 'package:fe_pos/model/edc_settlement.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/payment_provider.dart';

import 'package:provider/provider.dart';

class PaymentProviderFormPage extends StatefulWidget {
  final PaymentProvider paymentProvider;
  const PaymentProviderFormPage({super.key, required this.paymentProvider});

  @override
  State<PaymentProviderFormPage> createState() =>
      _PaymentProviderFormPageState();
}

class _PaymentProviderFormPageState extends State<PaymentProviderFormPage>
    with
        AutomaticKeepAliveClientMixin,
        HistoryPopup,
        LoadingPopup,
        DefaultResponse {
  late Flash flash;
  late final Setting setting;
  final _formKey = GlobalKey<FormState>();
  PaymentProvider get paymentProvider => widget.paymentProvider;
  final _focusNode = FocusNode();
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    setting = context.read<Setting>();
    flash = Flash();

    super.initState();
    if (paymentProvider.id != null) {
      Future.delayed(Duration.zero, () => fetchPaymentProvider());
    }
    _focusNode.requestFocus();
  }

  void fetchPaymentProvider() {
    showLoadingPopup();
    final server = context.read<Server>();
    server.get('payment_providers/${paymentProvider.id}',
        queryParam: {'include': 'payment_provider_edcs'}).then((response) {
      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          PaymentProvider.fromJson(data['data'],
              model: paymentProvider, included: data['included'] ?? []);
        });
      }
    }, onError: (error) {
      defaultErrorResponse(error: error);
    }).whenComplete(() => hideLoadingPopup());
  }

  void _submit() async {
    final server = context.read<Server>();
    Map body = {
      'data': {
        'type': 'payment_provider',
        'attributes': paymentProvider.toJson(),
        'relationships': {
          'payment_provider_edcs': {
            'data': paymentProvider.paymentProviderEdcs
                .map<Map>((paymentProviderEdc) => {
                      'id': paymentProviderEdc.id,
                      'type': 'payment_provider_edc',
                      'attributes': paymentProviderEdc.toJson()
                    })
                .toList()
          }
        }
      }
    };
    Future request;
    if (paymentProvider.id == null) {
      request = server.post('payment_providers', body: body);
    } else {
      request =
          server.put('payment_providers/${paymentProvider.id}', body: body);
    }
    request.then((response) {
      if ([200, 201].contains(response.statusCode)) {
        final data = response.data;
        setState(() {
          PaymentProvider.fromJson(data['data'],
              model: paymentProvider, included: data['included'] ?? []);

          var tabManager = context.read<TabManager>();
          tabManager.changeTabHeader(
              widget, 'Edit Payment Provider ${paymentProvider.id}');
        });
        flash.show(const Text('Berhasil disimpan'), ToastificationType.success);
      } else if (response.statusCode == 409) {
        final data = response.data;
        flash.showBanner(
            title: data['message'],
            description: data['errors'].join('\n'),
            messageType: ToastificationType.error);
      }
    }, onError: (error, stackTrace) {
      defaultErrorResponse(error: error);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // codeInputWidget.text = paymentProvider.name;
    const labelStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Visibility(
                          visible: paymentProvider.id != null,
                          child: ElevatedButton.icon(
                              onPressed: () => fetchHistoryByRecord(
                                  'PaymentProvider', paymentProvider.id),
                              label: const Text('Riwayat'),
                              icon: const Icon(Icons.history)),
                        ),
                        const Divider(),
                        TextFormField(
                          focusNode: _focusNode,
                          decoration: const InputDecoration(
                              labelText: 'Bank/Platform',
                              labelStyle: labelStyle,
                              border: OutlineInputBorder()),
                          initialValue: paymentProvider.bankOrProvider,
                          onSaved: (newValue) {
                            paymentProvider.bankOrProvider = newValue ?? '';
                          },
                          validator: (newValue) {
                            if (newValue == null || newValue.isEmpty) {
                              return 'harus diisi';
                            }
                            return null;
                          },
                          onChanged: (newValue) {
                            paymentProvider.bankOrProvider = newValue;
                          },
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'Keterangan',
                              labelStyle: labelStyle,
                              border: OutlineInputBorder()),
                          initialValue: paymentProvider.name,
                          onSaved: (newValue) {
                            paymentProvider.name = newValue ?? '';
                          },
                          validator: (newValue) {
                            if (newValue == null || newValue.isEmpty) {
                              return 'harus diisi';
                            }
                            return null;
                          },
                          onChanged: (newValue) {
                            paymentProvider.name = newValue;
                          },
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text(
                          'Status',
                          style: labelStyle,
                        ),
                        RadioListTile<PaymentProviderStatus>(
                            value: PaymentProviderStatus.inactive,
                            groupValue: paymentProvider.status,
                            title:
                                Text(PaymentProviderStatus.inactive.humanize()),
                            onChanged: (value) => setState(() {
                                  paymentProvider.status =
                                      value ?? paymentProvider.status;
                                })),
                        RadioListTile<PaymentProviderStatus>(
                            value: PaymentProviderStatus.active,
                            groupValue: paymentProvider.status,
                            title:
                                Text(PaymentProviderStatus.active.humanize()),
                            onChanged: (value) => setState(() {
                                  paymentProvider.status =
                                      value ?? paymentProvider.status;
                                })),
                        const SizedBox(
                          height: 10,
                        ),
                        DropdownMenu<String>(
                          dropdownMenuEntries: const [
                            DropdownMenuEntry(
                                value: 'IDR', label: 'Indonesia Rupiah'),
                            DropdownMenuEntry(value: 'USD', label: 'US Dollar'),
                            DropdownMenuEntry(
                                value: 'CNY', label: 'China Renmimbi'),
                          ],
                          label: const Text('Mata Uang'),
                          initialSelection: paymentProvider.currency,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'No Rekening',
                              labelStyle: labelStyle,
                              border: OutlineInputBorder()),
                          initialValue: paymentProvider.accountNumber,
                          onSaved: (newValue) {
                            paymentProvider.accountNumber = newValue ?? '';
                          },
                          validator: (newValue) {
                            if (newValue == null || newValue.isEmpty) {
                              return 'harus diisi';
                            }
                            return null;
                          },
                          onChanged: (newValue) {
                            paymentProvider.accountNumber = newValue;
                          },
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'Atas Nama Rekening',
                              labelStyle: labelStyle,
                              border: OutlineInputBorder()),
                          validator: (newValue) {
                            if (newValue == null || newValue.isEmpty) {
                              return 'harus diisi';
                            }
                            return null;
                          },
                          onSaved: (newValue) {
                            paymentProvider.accountRegisterName =
                                newValue ?? '';
                          },
                          onChanged: (newValue) {
                            paymentProvider.accountRegisterName = newValue;
                          },
                          initialValue: paymentProvider.accountRegisterName,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'Swift Code',
                              labelStyle: labelStyle,
                              border: OutlineInputBorder()),
                          initialValue: paymentProvider.swiftCode,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'harus diisi';
                            }
                            return null;
                          },
                          onSaved: (newValue) {
                            paymentProvider.swiftCode = newValue ?? '';
                          },
                          onChanged: (newValue) {
                            paymentProvider.swiftCode = newValue;
                          },
                        ),
                      ]),
                ),
                const SizedBox(
                  height: 10,
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 100,
                    showBottomBorder: true,
                    columns: [
                      const DataColumn(
                          label: Text(
                        'Merchant ID',
                        style: labelStyle,
                      )),
                      const DataColumn(
                          label: Text('Terminal ID', style: labelStyle)),
                      DataColumn(
                          label: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  paymentProvider.paymentProviderEdcs.clear();
                                });
                              },
                              child: const Text('Hapus Semua',
                                  style: labelStyle))),
                    ],
                    rows: paymentProvider.paymentProviderEdcs
                        .map<DataRow>((paymentProviderEdc) => DataRow(cells: [
                              DataCell(SizedBox(
                                width: 250,
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder()),
                                  initialValue: paymentProviderEdc.merchantId,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'harus diisi';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) =>
                                      paymentProviderEdc.merchantId = value,
                                  onSaved: (value) => paymentProviderEdc
                                      .merchantId = value ?? '',
                                  key: ValueKey(
                                      "paymentProviderEdc${paymentProviderEdc.id}-merchant_id"),
                                ),
                              )),
                              DataCell(SizedBox(
                                width: 250,
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder()),
                                  initialValue:
                                      paymentProviderEdc.terminalId.toString(),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) =>
                                      paymentProviderEdc.terminalId = value,
                                  onSaved: (value) => paymentProviderEdc
                                      .terminalId = value ?? '',
                                  key: ValueKey(
                                      "paymentProviderEdc${paymentProviderEdc.id}-terminal_id"),
                                ),
                              )),
                              DataCell(Row(
                                children: [
                                  Visibility(
                                    visible: paymentProviderEdc.id != null,
                                    child: IconButton(
                                      onPressed: () {
                                        fetchHistoryByRecord(
                                            'PaymentProviderEdc',
                                            paymentProviderEdc.id);
                                      },
                                      icon: const Icon(Icons.history),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        paymentProvider.paymentProviderEdcs
                                            .remove(paymentProviderEdc);
                                      });
                                    },
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ))
                            ]))
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ElevatedButton(
                      onPressed: () => setState(() {
                            paymentProvider.paymentProviderEdcs
                                .add(PaymentProviderEdc());
                          }),
                      child: const Text('Tambah')),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          flash.show(
                              const Text('Loading'), ToastificationType.info);
                          _submit();
                        }
                      },
                      child: const Text('submit')),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
