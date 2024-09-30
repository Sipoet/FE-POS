import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/payroll_type.dart';
import 'package:provider/provider.dart';

class PayrollTypeFormPage extends StatefulWidget {
  final PayrollType payrollType;
  const PayrollTypeFormPage({super.key, required this.payrollType});

  @override
  State<PayrollTypeFormPage> createState() => _PayrollTypeFormPageState();
}

class _PayrollTypeFormPageState extends State<PayrollTypeFormPage>
    with AutomaticKeepAliveClientMixin, HistoryPopup, LoadingPopup {
  late final Flash flash;
  final focusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  PayrollType get payrollType => widget.payrollType;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    flash = Flash(context);
    super.initState();
    focusNode.requestFocus();
  }

  void _submit() async {
    final server = context.read<Server>();
    Map body = {
      'data': {
        'type': 'payrollType',
        'id': payrollType.id,
        'attributes': payrollType.toJson(),
      }
    };
    Future request;
    if (payrollType.id == null) {
      request = server.post('payroll_types', body: body);
    } else {
      request = server.put('payroll_types/${payrollType.id}', body: body);
    }
    request.then((response) {
      if ([200, 201].contains(response.statusCode)) {
        var data = response.data['data'];
        setState(() {
          PayrollType.fromJson(data,
              included: response.data['included'] ?? [], model: payrollType);
          var tabManager = context.read<TabManager>();
          tabManager.changeTabHeader(
              widget, 'Edit Payroll Type ${payrollType.name}');
        });
        flash.show(const Text('Berhasil disimpan'), MessageType.success);
      } else if (response.statusCode == 409) {
        var data = response.data;
        flash.showBanner(
            title: data['message'],
            description: data['errors'].join('\n'),
            messageType: MessageType.failed);
      }
    }, onError: (error, stackTrace) {
      server.defaultErrorResponse(context: context, error: error);
    });
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
            child: Container(
              constraints: const BoxConstraints(maxWidth: 350),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextFormField(
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                        labelText: 'Nama',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    validator: (newValue) {
                      if (newValue == null || newValue.isEmpty) {
                        return 'harus diisi';
                      }
                      return null;
                    },
                    initialValue: payrollType.name,
                    onSaved: (newValue) {
                      payrollType.name = newValue.toString();
                    },
                    onChanged: (newValue) {
                      payrollType.name = newValue.toString();
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Initial',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    validator: (newValue) {
                      if (newValue == null || newValue.isEmpty) {
                        return 'harus diisi';
                      }
                      return null;
                    },
                    initialValue: payrollType.initial,
                    onSaved: (newValue) {
                      payrollType.initial = newValue.toString();
                    },
                    onChanged: (newValue) {
                      payrollType.initial = newValue.toString();
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Order',
                        labelStyle: labelStyle,
                        border: OutlineInputBorder()),
                    validator: (newValue) {
                      if (newValue == null || newValue.isEmpty) {
                        return 'harus diisi';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.number,
                    initialValue: payrollType.order.toString(),
                    onSaved: (newValue) {
                      payrollType.order =
                          int.tryParse(newValue ?? '') ?? payrollType.order;
                    },
                    onChanged: (newValue) {
                      payrollType.order =
                          int.tryParse(newValue) ?? payrollType.order;
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  CheckboxListTile(
                      title: const Text('Show on Payslip Description?'),
                      value: payrollType.isShowOnPayslipDesc,
                      onChanged: (value) => setState(() {
                            payrollType.isShowOnPayslipDesc =
                                value ?? payrollType.isShowOnPayslipDesc;
                          })),
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            flash.show(const Text('Loading'), MessageType.info);
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
      ),
    );
  }
}
