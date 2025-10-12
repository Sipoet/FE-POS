import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/payment_type.dart';
import 'package:provider/provider.dart';

class PaymentTypeFormPage extends StatefulWidget {
  final PaymentType paymentType;
  const PaymentTypeFormPage({super.key, required this.paymentType});

  @override
  State<PaymentTypeFormPage> createState() => _PaymentTypeFormPageState();
}

class _PaymentTypeFormPageState extends State<PaymentTypeFormPage>
    with
        AutomaticKeepAliveClientMixin,
        HistoryPopup,
        LoadingPopup,
        DefaultResponse {
  late final Flash flash;
  final codeInputWidget = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  PaymentType get paymentType => widget.paymentType;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    flash = Flash();
    super.initState();
    if (paymentType.id != null) {
      Future.delayed(Duration.zero, fetchPaymentType);
    }
  }

  void fetchPaymentType() {
    showLoadingPopup();
    final server = context.read<Server>();
    server.get('paymentTypes/${paymentType.id}', queryParam: {
      'include':
          'column_authorizes,access_authorizes,paymentType_work_schedules'
    }).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          paymentType.setFromJson(response.data['data'],
              included: response.data['included']);
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
        'type': 'paymentType',
        'id': paymentType.id,
        'attributes': paymentType.toJson(),
      }
    };
    Future request;
    if (paymentType.id == null) {
      request = server.post('payment_types', body: body);
    } else {
      request = server.put('payment_types/${paymentType.id}', body: body);
    }
    request.then((response) {
      if ([200, 201].contains(response.statusCode)) {
        var data = response.data['data'];
        setState(() {
          paymentType.setFromJson(data,
              included: response.data['included'] ?? []);
          var tabManager = context.read<TabManager>();
          tabManager.changeTabHeader(
              widget, 'Edit paymentType ${paymentType.name}');
        });
        flash.show(const Text('Berhasil disimpan'), ToastificationType.success);
      } else if (response.statusCode == 409) {
        var data = response.data;
        flash.showBanner(
            title: data['message'],
            description: data['errors'].join('\n'),
            messageType: ToastificationType.error);
      }
    }, onError: (error, stackTrace) {
      defaultErrorResponse(error: error);
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
          child: Container(
            constraints: BoxConstraints.loose(const Size.fromWidth(600)),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
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
                    onSaved: (newValue) {
                      paymentType.name = newValue.toString();
                    },
                    onChanged: (newValue) {
                      paymentType.name = newValue.toString();
                    },
                    controller: codeInputWidget,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
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
      ),
    );
  }
}
