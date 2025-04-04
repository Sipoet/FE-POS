import 'package:fe_pos/model/account.dart';
import 'package:fe_pos/model/location.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_form_field.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PayslipPayPage extends StatefulWidget {
  final List<int> payslipIds;
  final bool isModal;
  const PayslipPayPage(
      {super.key, this.isModal = false, required this.payslipIds});

  @override
  State<PayslipPayPage> createState() => _PayslipPayPageState();
}

class _PayslipPayPageState extends State<PayslipPayPage> with LoadingPopup {
  Account? account;
  DateTime? paidAt;
  String? description;
  Location? location;
  final _formKey = GlobalKey<FormState>();
  late final Server server;
  @override
  void initState() {
    server = context.read<Server>();
    super.initState();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    showLoadingPopup();
    final navigator = Navigator.of(context);
    server.post('payslips/pay', body: {
      'paid_at': paidAt!.toIso8601String(),
      'payslip_ids': widget.payslipIds.map((e) => e.toString()).toList(),
      'cash_account': account!.id,
      'description': description,
      'location': location!.id,
    }).then((response) {
      final flash = Flash();
      if (response.statusCode != 200) {
        flash.showBanner(
          messageType: ToastificationType.error,
          title: 'gagal simpan pembayaran',
          description: response.data['message'],
        );
        return;
      }
      flash.show(
        Text('berhasil disimpan'),
        ToastificationType.success,
      );
      if (widget.isModal) {
        Future.delayed(Duration(seconds: 1), () => navigator.pop());
      }
    }).whenComplete(() => hideLoadingPopup());
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      child: VerticalBodyScroll(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DateFormField(
                label: Text("Tanggal Bayar"),
                allowClear: false,
                onChanged: (value) => paidAt = value,
                validator: (date) {
                  if (date == null) {
                    return "harus diisi";
                  }
                  return null;
                },
              ),
              const SizedBox(
                height: 10,
              ),
              AsyncDropdown<Account>(
                label: Text('Akun Pembayaran'),
                request: (
                    {required cancelToken,
                    int limit = 20,
                    int page = 1,
                    String searchText = ''}) {
                  return server.get('accounts',
                      queryParam: {
                        'search_text': searchText,
                        'filter[kasbank][eq]': 'true',
                        'filter[tipe][eq]': 'D',
                        'page[page]': page.toString(),
                        'page[limit]': limit.toString(),
                      },
                      cancelToken: cancelToken);
                },
                allowClear: false,
                textOnSearch: (model) => model.modelValue,
                converter: Account.fromJson,
                onChanged: (model) => account = model,
                validator: (model) {
                  if (model == null) {
                    return "harus diisi";
                  }
                  return null;
                },
              ),
              const SizedBox(
                height: 10,
              ),
              AsyncDropdown<Location>(
                label: Text('Lokasi'),
                path: 'locations',
                allowClear: false,
                textOnSearch: (model) => model.modelValue,
                converter: Location.fromJson,
                onChanged: (model) => location = model,
                validator: (model) {
                  if (model == null) {
                    return "harus diisi";
                  }
                  return null;
                },
              ),
              const SizedBox(
                height: 10,
              ),
              TextFormField(
                decoration: InputDecoration(
                    label: Text('Keterangan'), border: OutlineInputBorder()),
                minLines: 3,
                maxLines: 5,
                onChanged: (value) => description = value,
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(onPressed: _submit, child: Text('simpan')),
            ],
          ),
        ),
      ),
    );
  }
}
