import 'package:fe_pos/model/sales_cashier.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/money_form_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesPaymentPage extends StatefulWidget {
  final SalesCashier salesCashier;
  const SalesPaymentPage({super.key, required this.salesCashier});

  @override
  State<SalesPaymentPage> createState() => _SalesPaymentPageState();
}

class _SalesPaymentPageState extends State<SalesPaymentPage> {
  static const labelStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 20);
  SalesCashier get salesCashier => widget.salesCashier;
  late final Setting setting;
  List<SalesPayment> get salesPayments => salesCashier.salesPayments;
  @override
  void initState() {
    setting = context.read<Setting>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 600,
      ),
      child: Column(mainAxisSize: MainAxisSize.max, children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            const Text(
              'Total: ',
              style: labelStyle,
            ),
            SizedBox(
              width: 300,
              child: TextFormField(
                initialValue: salesCashier.grandTotal.format(),
                readOnly: true,
                decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(10),
                    border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        Table(
          columnWidths: const {
            2: FixedColumnWidth(200),
            3: FixedColumnWidth(40)
          },
          border: TableBorder.all(),
          children: [
                TableRow(children: [
                  const TableCell(
                      child: Text(
                    'Metode Pembayaran',
                    style: labelStyle,
                  )),
                  const TableCell(
                      child: Text(
                    'EDC / Platform',
                    style: labelStyle,
                  )),
                  const TableCell(
                      child: Text(
                    'Jumlah',
                    style: labelStyle,
                  )),
                  TableCell(
                      child: Visibility(
                    visible: setting.canShow(
                        'salesPayment', 'multiple_payment_method'),
                    child: IconButton.filled(
                      iconSize: 25,
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() {
                        salesPayments.add(SalesPayment());
                      }),
                    ),
                  )),
                ]),
              ] +
              salesPayments
                  .map<TableRow>((salesPayment) => TableRow(children: [
                        TableCell(
                            child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: AsyncDropdown<PaymentType>(
                              allowClear: false,
                              textOnSearch: (paymentType) => paymentType.name,
                              selected: salesPayment.paymentType,
                              converter: PaymentType.fromJson,
                              onChanged: (paymentType) {
                                setState(() {
                                  salesPayment.paymentType =
                                      paymentType ?? PaymentType();
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'harus diisi';
                                }
                                return null;
                              },
                              path: 'payment_types'),
                        )),
                        TableCell(
                            child: Visibility(
                          visible: !salesPayment.isCash,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: AsyncDropdown<PaymentProvider>(
                              allowClear: false,
                              textOnSearch: (paymentProvider) =>
                                  paymentProvider.name,
                              selected: salesPayment.paymentProvider,
                              converter: PaymentProvider.fromJson,
                              request: (server, page, searchText, cancelToken) {
                                return server.get('payment_providers',
                                    queryParam: {
                                      'page[page]': page.toString(),
                                      'page[limit]': '20',
                                      'search_text': searchText,
                                      'filter[status][eq]':
                                          PaymentProviderStatus.active
                                              .toString(),
                                    },
                                    cancelToken: cancelToken);
                              },
                              validator: (value) {
                                if (value == null && !salesPayment.isCash) {
                                  return 'harus diisi';
                                }
                                return null;
                              },
                              onChanged: (paymentProvider) {
                                setState(() {
                                  salesPayment.paymentProvider =
                                      paymentProvider ?? PaymentProvider();
                                });
                              },
                            ),
                          ),
                        )),
                        TableCell(
                            child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: MoneyFormField(
                            initialValue: salesPayment.amount,
                            onChanged: (value) => setState(() {
                              salesPayment.amount =
                                  value ?? salesPayment.amount;
                            }),
                          ),
                        )),
                        TableCell(
                            child: Visibility(
                          visible: salesPayments.indexOf(salesPayment) > 0,
                          child: IconButton(
                              onPressed: () {
                                setState(() {
                                  salesPayments.remove(salesPayment);
                                });
                              },
                              icon: const Icon(Icons.close)),
                        )),
                      ]))
                  .toList(),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Row(
            children: [
              const Text(
                'Total Bayar: ',
                style: labelStyle,
              ),
              SizedBox(
                width: 300,
                child: TextFormField(
                  initialValue: salesCashier.payAmount.format(),
                  readOnly: true,
                  decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(10),
                      border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            const Text(
              'Kembali: ',
              style: labelStyle,
            ),
            SizedBox(
              width: 300,
              child: TextFormField(
                initialValue: salesCashier.grandTotal.format(),
                readOnly: true,
                decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(10),
                    border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.max,
          children: [
            ElevatedButton.icon(
                icon: const Icon(Icons.print),
                onPressed: () => _saveAndPrint,
                label: const Text('Simpan + Cetak')),
            Visibility(
              visible: !salesCashier.isNewRecord,
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    onPressed: () => _print,
                    label: const Text('Cetak')),
              ),
            ),
            Visibility(
              visible: !salesCashier.isNewRecord,
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    onPressed: () => _save,
                    label: const Text('Simpan')),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal')),
          ],
        )
      ]),
    );
  }

  void _saveAndPrint() {
    _save().then((result) {
      if (result == true) {
        _print();
      }
    });
  }

  Future<bool> _save() async {
    return false;
  }

  void _print() {}
}
