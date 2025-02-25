import 'package:fe_pos/model/sales_cashier.dart';
import 'package:fe_pos/page/item_modal_page.dart';
import 'package:fe_pos/page/sales_payment_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/history_popup.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_form_field.dart';
import 'package:fe_pos/widget/number_form_field.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

class SalesCashierFormPage extends StatefulWidget {
  final SalesCashier salesCashier;
  const SalesCashierFormPage({super.key, required this.salesCashier});

  @override
  State<SalesCashierFormPage> createState() => _SalesCashierFormPageState();
}

class _SalesCashierFormPageState extends State<SalesCashierFormPage>
    with
        AutomaticKeepAliveClientMixin,
        LoadingPopup,
        HistoryPopup,
        TextFormatter,
        DefaultResponse {
  late Flash flash;

  final _formKey = GlobalKey<FormState>();
  late final Server _server;
  late final Setting setting;
  late SalesCashier salesCashier;
  final barcodeController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  int quantity = 1;
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    salesCashier = widget.salesCashier;
    flash = Flash();
    setting = context.read<Setting>();
    _server = context.read<Server>();

    if (salesCashier.id != null) {
      Future.delayed(Duration.zero, () => fetchSalesCashier());
    }
    super.initState();
  }

  void fetchSalesCashier() {
    showLoadingPopup();

    _server.get('sales/show', queryParam: {
      'code': Uri.encodeComponent(salesCashier.id),
      'include': 'sale_items'
    }).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          SalesCashier.fromJson(response.data['data'],
              included: response.data['included'], model: salesCashier);
        });
      }
    }, onError: (error) {
      defaultErrorResponse(error: error);
    }).whenComplete(() => hideLoadingPopup());
  }

  Future<Item?> fetchDataItem(String barcode) async {
    try {
      var response = await _server
          .get('items/with_discount_rule', queryParam: {'barcode': barcode});
      if (response == null || response.statusCode != 200) {
        flash.showBanner(
            messageType: ToastificationType.error,
            title: 'barcode tidak ditemukan',
            description: 'barcode $barcode tidak ditemukan');
        return null;
      }
      var data = response.data;
      return Item.fromJson(
        data['data'],
        included: data['included'],
      );
    } catch (e) {
      return null;
    }
  }

  void addItem(
      {required Item item, required String barcode, required int quantity}) {
    final salesCashierItem = SalesCashierItem(
      item: item,
      itemBarcode: barcode,
      quantity: quantity,
      price: item.sellPrice,
    );
    checkDiscount(salesCashierItem, item.discountRules);
    salesCashier.salesCashierItems.add(salesCashierItem);
  }

  void checkDiscount(
      SalesCashierItem salesCashierItem, List<DiscountRule> discountRules) {}

  Future<Item?> openItemModal(String barcode) async {
    return showDialog<Item>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Daftar Item'),
        content: ItemModalPage(barcode: barcode),
      ),
    );
  }

  void _removeItem(SalesCashierItem salesCashierItem) {
    showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          final navigator = Navigator.of(context);
          return AlertDialog(
            actions: [
              ElevatedButton(
                  onPressed: () => navigator.pop(true),
                  child: const Text('Ya')),
              ElevatedButton(
                  onPressed: () => navigator.pop(false),
                  child: const Text('Tidak/Kembali')),
            ],
            content: Text(
                'Apakah Kamu Yakin hapus ${salesCashierItem.itemBarcode}?'),
          );
        }).then((result) {
      if (result == true) {
        setState(() {
          salesCashier.salesCashierItems.remove(salesCashierItem);
        });
      }
    });
  }

  void _openCashDrawer() {}
  void _displayDetailItem() {}
  void _displayItemPrice() {}
  static const labelStyle =
      TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Container(
          constraints: BoxConstraints.loose(const Size.fromWidth(600)),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    Visibility(
                      visible: true ?? setting.canShow('salesCashier', 'code'),
                      child: SizedBox(
                        width: 250,
                        height: 35,
                        child: TextFormField(
                          decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(5),
                              labelText: 'No Transaksi' ??
                                  setting.columnName('salesCashier', 'code'),
                              labelStyle: labelStyle,
                              border: const OutlineInputBorder()),
                          initialValue: salesCashier.code,
                        ),
                      ),
                    ),
                    Text('Lokasi: ${salesCashier.location}'),
                    Visibility(
                      visible: true ??
                          setting.canShow('salesCashier', 'transaction_date'),
                      child: SizedBox(
                        width: 250,
                        height: 35,
                        child: DateFormField(
                          label: Text(
                            'Tanggal' ??
                                setting.columnName(
                                    'salesCashier', 'transaction_date'),
                            style: labelStyle,
                          ),
                          initialValue: salesCashier.transactionDate,
                        ),
                      ),
                    ),
                    Visibility(
                      visible: true ??
                          setting.canShow('salesCashier', 'customer_code'),
                      child: SizedBox(
                        width: 250,
                        height: 35,
                        child: AsyncDropdown<Customer>(
                          label: Text(
                            'Pelanggan' ??
                                setting.columnName('salesCashier', 'customer'),
                            style: labelStyle,
                          ),
                          textOnSearch: (customer) =>
                              "${customer.code} - ${customer.name}",
                          converter: Customer.fromJson,
                          selected: salesCashier.customer,
                        ),
                      ),
                    ),
                    Visibility(
                      visible: true ??
                          setting.canShow('salesCashier', 'sales_person'),
                      child: SizedBox(
                        width: 250,
                        height: 35,
                        child: AsyncDropdown<Customer>(
                          label: Text(
                            'Sales' ??
                                setting.columnName(
                                    'salesCashier', 'sales_person'),
                            style: labelStyle,
                          ),
                          textOnSearch: (customer) =>
                              "${customer.code} - ${customer.name}",
                          converter: Customer.fromJson,
                          selected: salesCashier.customer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 5,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 70,
                      height: 35,
                      child: NumberFormField<int>(
                        controller: quantityController,
                        label: const Text('Jumlah', style: labelStyle),
                        onChanged: (value) => setState(() {
                          quantity = value ?? 0;
                        }),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    SizedBox(
                      width: 300,
                      height: 35,
                      child: TextField(
                        controller: barcodeController,
                        onSubmitted: (value) async {
                          if (value.isEmpty) return;
                          var item = await fetchDataItem(value);
                          item ??= await openItemModal(value);
                          if (item != null) {
                            addItem(
                                barcode: value, item: item, quantity: quantity);
                            barcodeController.text = '';
                            quantity = 1;
                            quantityController.setValue(quantity);
                          }
                        },
                        decoration: const InputDecoration(
                            contentPadding: EdgeInsets.all(5),
                            label: Text(
                              'Kode Item',
                              style: labelStyle,
                            ),
                            border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Table(
                  border: TableBorder.all(),
                  children: [
                        const TableRow(children: [
                          TableCell(child: Text('Barcode')),
                          TableCell(child: Text('Keterangan')),
                          TableCell(child: Text('Merek')),
                          TableCell(child: Text('Jenis')),
                          TableCell(child: Text('jumlah')),
                          TableCell(child: Text('satuan')),
                          TableCell(child: Text('harga')),
                          TableCell(child: Text('Pot%/ nom')),
                          TableCell(child: Text('Total')),
                          TableCell(child: Text('Tgl Exp')),
                          TableCell(child: SizedBox()),
                        ]),
                      ] +
                      salesCashier.salesCashierItems
                          .map<TableRow>(
                            (salesCashierItem) => TableRow(children: [
                              TableCell(
                                  child: Text(salesCashierItem.itemBarcode)),
                              TableCell(child: Text(salesCashierItem.itemName)),
                              TableCell(
                                  child: Text(salesCashierItem.brandName)),
                              TableCell(
                                  child: Text(salesCashierItem.itemTypeName)),
                              TableCell(
                                  child: Text(
                                      salesCashierItem.quantity.toString())),
                              TableCell(child: Text(salesCashierItem.uom)),
                              TableCell(
                                  child:
                                      Text(salesCashierItem.price.toString())),
                              TableCell(
                                  child: Text(
                                      "${salesCashierItem.discountAmount.toString()}( ${salesCashierItem.discountPercentage?.toString()} )")),
                              TableCell(
                                  child:
                                      Text(salesCashierItem.total.toString())),
                              TableCell(
                                  child: Text(
                                      salesCashierItem.expiredDate?.format() ??
                                          '-')),
                              TableCell(
                                  child: PopupMenuButton(
                                icon: const Icon(Icons.more_vert_outlined),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: const Text('Hapus'),
                                    onTap: () => _removeItem(salesCashierItem),
                                  )
                                ],
                              )),
                            ]),
                          )
                          .toList(),
                ),
                const SizedBox(
                  height: 10,
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton(
                        onPressed: () => {_openCashDrawer()},
                        child: const Text('Buka Laci')),
                    ElevatedButton(
                        onPressed: () => {_displayDetailItem()},
                        child: const Text('Detail Item')),
                    ElevatedButton(
                        onPressed: () => {_displayItemPrice()},
                        child: const Text('Lihat Harga')),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Visibility(
                      visible:
                          true ?? setting.canShow('salesCashier', 'voucher'),
                      child: SizedBox(
                        width: 250,
                        height: 35,
                        child: TextFormField(
                          decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(5),
                              labelText: 'Voucher' ??
                                  setting.columnName(
                                      'salesCashier', 'voucher') ??
                                  'Voucher',
                              labelStyle: labelStyle,
                              border: const OutlineInputBorder()),
                          initialValue: salesCashier.code,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Visibility(
                            visible: true ||
                                setting.canShow('salesCashier',
                                    'header_discount_percentage') ||
                                setting.canShow(
                                    'salesCashier', 'header_discount_amount'),
                            child: const Text(
                              'Potongan: ',
                              style: labelStyle,
                            )),
                        Visibility(
                          visible: true ??
                              setting.canShow(
                                  'salesCashier', 'header_discount_percentage'),
                          child: SizedBox(
                            width: 70,
                            height: 35,
                            child: TextFormField(
                              decoration: const InputDecoration(
                                  suffixIcon: Icon(Icons.percent),
                                  contentPadding: EdgeInsets.all(5),
                                  border: OutlineInputBorder()),
                              initialValue: salesCashier
                                  .headerDiscountPercentage
                                  ?.toString(),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: true ??
                              setting.canShow(
                                  'salesCashier', 'header_discount_amount'),
                          child: SizedBox(
                            width: 250,
                            height: 35,
                            child: TextFormField(
                              decoration: const InputDecoration(
                                  prefixText: 'Rp.',
                                  contentPadding: EdgeInsets.all(5),
                                  border: OutlineInputBorder()),
                              initialValue:
                                  salesCashier.headerDiscountAmount.toString(),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        const Text(
                          'Subtotal: ',
                          style: labelStyle,
                        ),
                        Visibility(
                          visible: true ??
                              setting.canShow('salesCashier', 'total_item'),
                          child: SizedBox(
                            width: 70,
                            height: 35,
                            child: TextFormField(
                              readOnly: true,
                              decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.all(5),
                                  border: OutlineInputBorder()),
                              initialValue: salesCashier.totalItem.toString(),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: true ??
                              setting.canShow('salesCashier', 'subtotal'),
                          child: SizedBox(
                            width: 250,
                            height: 35,
                            child: TextFormField(
                              readOnly: true,
                              decoration: const InputDecoration(
                                  prefixText: 'Rp.',
                                  contentPadding: EdgeInsets.all(5),
                                  border: OutlineInputBorder()),
                              initialValue: salesCashier.subtotal.format(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Visibility(
                      visible:
                          true ?? setting.canShow('salesCashier', 'tax_type'),
                      child: DropdownMenu<SalesTaxType>(
                        width: 200,
                        initialSelection: salesCashier.taxType,
                        label: Text('PPN' ??
                            setting.columnName('salesCashier', 'tax_type') ??
                            'PPN'),
                        dropdownMenuEntries: SalesTaxType.values
                            .map<DropdownMenuEntry<SalesTaxType>>((taxType) =>
                                DropdownMenuEntry<SalesTaxType>(
                                    value: taxType, label: taxType.toString()))
                            .toList(),
                        inputDecorationTheme: const InputDecorationTheme(
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.all(5)),
                      ),
                    ),
                    Row(
                      children: [
                        const Text(
                          'Pajak: ',
                          style: labelStyle,
                        ),
                        Visibility(
                          visible: true ??
                              setting.canShow('salesCashier', 'tax_percentage'),
                          child: SizedBox(
                            width: 70,
                            height: 35,
                            child: TextFormField(
                              readOnly: true,
                              decoration: const InputDecoration(
                                  suffixIcon: Icon(Icons.percent),
                                  contentPadding: EdgeInsets.all(5),
                                  border: OutlineInputBorder()),
                              initialValue:
                                  salesCashier.taxPercentage?.toString(),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: true ??
                              setting.canShow('salesCashier', 'tax_amount'),
                          child: SizedBox(
                            width: 250,
                            height: 35,
                            child: TextFormField(
                              readOnly: true,
                              decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.all(5),
                                  border: OutlineInputBorder()),
                              initialValue: salesCashier.taxAmount.format(),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        const Text(
                          'Selisih Pembulatan: ',
                          style: labelStyle,
                        ),
                        Visibility(
                          visible: true ??
                              setting.canShow('salesCashier', 'round_amount'),
                          child: SizedBox(
                            width: 250,
                            height: 35,
                            child: TextFormField(
                              readOnly: true,
                              decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.all(5),
                                  border: OutlineInputBorder()),
                              initialValue: salesCashier.roundAmount.format(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Visibility(
                      visible:
                          true ?? setting.canShow('salesCashier', 'location'),
                      child: Text("Keluar dari: ${salesCashier.location}"),
                    ),
                    Visibility(
                      visible: true ??
                          setting.canShow('salesCashier', 'round_amount'),
                      child: Row(
                        children: [
                          const Text(
                            'Biaya Lain: ',
                            style: labelStyle,
                          ),
                          SizedBox(
                            width: 250,
                            height: 35,
                            child: TextFormField(
                              readOnly: true,
                              decoration: const InputDecoration(
                                  prefixText: 'Rp.',
                                  contentPadding: EdgeInsets.all(5),
                                  border: OutlineInputBorder()),
                              initialValue: salesCashier.roundAmount.toString(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Visibility(
                  visible:
                      true ?? setting.canShow('salesCashier', 'description'),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      width: 300,
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: setting.columnName(
                                    'salesCashier', 'description') ??
                                'Keterangan',
                            labelStyle: labelStyle,
                            border: const OutlineInputBorder()),
                        readOnly: true,
                        minLines: 3,
                        maxLines: 5,
                        initialValue: salesCashier.description,
                      ),
                    ),
                  ),
                ),
                Wrap(
                  runSpacing: 10,
                  spacing: 10,
                  children: [
                    ElevatedButton(
                        onPressed: () => _updateSalesCashier(),
                        child: const Text('Simpan')),
                    Visibility(
                      visible: !salesCashier.isNewRecord,
                      child: ElevatedButton.icon(
                          icon: const Icon(Icons.print),
                          onPressed: () => _printReceipt(),
                          label: const Text('Cetak Struk')),
                    ),
                    ElevatedButton(
                        onPressed: () => _pay(), child: const Text('Bayar')),
                    Visibility(
                      visible: salesCashier.isNewRecord,
                      child: ElevatedButton(
                          onPressed: () => _openPending(),
                          child: const Text('Buka Pending')),
                    ),
                    Visibility(
                      visible: salesCashier.isNewRecord,
                      child: ElevatedButton(
                          onPressed: () => _moveToPending(),
                          child: const Text('Draft Pending')),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateSalesCashier() {}
  void _printReceipt() {}

  void _pay() {
    if (salesCashier.salesPayments.isEmpty) {
      salesCashier.salesPayments = [SalesPayment()];
    }
    showDialog<SalesCashier>(
      context: context,
      builder: (BuildContext context) {
        final navigator = Navigator.of(context);
        return AlertDialog(
          title: const Row(
            children: [Text("Pembayaran"), Icon(Icons.attach_money_rounded)],
          ),
          content: SalesPaymentPage(salesCashier: salesCashier),
        );
      },
    ).then((SalesCashier? newSalesCashier) {
      if (newSalesCashier != null) {
        setState(() {
          salesCashier = newSalesCashier;
        });
      }
    });
  }

  void _openPending() {}
  void _moveToPending() {}
}
