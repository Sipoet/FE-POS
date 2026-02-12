import 'package:fe_pos/model/purchase_header.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/date_form_field.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NewPurchaseFormPage extends StatefulWidget {
  final PurchaseHeader purchaseHeader;
  const NewPurchaseFormPage({super.key, required this.purchaseHeader});

  @override
  State<NewPurchaseFormPage> createState() => _NewPurchaseFormPageState();
}

class _NewPurchaseFormPageState extends State<NewPurchaseFormPage> {
  bool isConsignment = false;
  late final Server _server;
  PurchaseHeader get purchaseHeader => widget.purchaseHeader;
  final _formState = GlobalKey<FormState>();
  @override
  void initState() {
    _server = context.read<Server>();
    super.initState();
  }

  void openDetailSkus(detail) {}

  void addDetail() {
    setState(() {
      purchaseHeader.purchaseItems.add(PurchaseItem());
    });
  }

  void removeDetail(PurchaseItem detail) {
    setState(() {
      purchaseHeader.purchaseItems.remove(detail);
    });
  }

  void submitForm() {
    if (_formState.currentState?.validate() != true) {
      return;
    }
    _formState.currentState?.save();
    final flash = Flash();
    purchaseHeader.save(_server).then((result) {
      if (result) {
        flash.show(Text('Sukses Simpan Pembelian'), ToastificationType.success);
      } else {
        flash.showBanner(
          messageType: ToastificationType.error,
          title: 'Gagal Simpan Pembelian',
          description: purchaseHeader.errors.join(', '),
        );
      }
    });
  }

  void addOtherCost() {}

  static const _widthInput = 250.0;
  static const defaultInputDecoration = InputDecoration(
    isDense: true,
    border: OutlineInputBorder(),
  );
  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 18,
      letterSpacing: 1.2,
    );
    List<TableRow> tableBodies = [];
    for (final purchaseItem in purchaseHeader.purchaseItems) {
      tableBodies.add(
        TableRow(
          children: [
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: AsyncDropdown<Product>(
                  modelClass: ProductClass(),
                  allowClear: false,
                  selected: purchaseItem.product,
                  textOnSearch: (model) => model.name,
                  onChanged: (model) => purchaseItem.product = model,
                  isDense: true,
                ),
              ),
            ),
            TableCell(
              child: Table(
                border: TableBorder.all(),
                children: [
                  TableRow(
                    children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            decoration: defaultInputDecoration,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            decoration: defaultInputDecoration,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            decoration: defaultInputDecoration,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TableCell(child: TextFormField(decoration: defaultInputDecoration)),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(decoration: defaultInputDecoration),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(decoration: defaultInputDecoration),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(decoration: defaultInputDecoration),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DateFormField(isDense: true),
              ),
            ),
            TableCell(
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => openDetailSkus(purchaseItem),
                    icon: Icon(Icons.arrow_downward_outlined),
                  ),
                  IconButton(
                    onPressed: () => removeDetail(purchaseItem),
                    icon: Icon(Icons.delete),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        VerticalBodyScroll(
          child: Form(
            key: _formState,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  runSpacing: 15,
                  spacing: 15,
                  children: [
                    SizedBox(
                      width: _widthInput,
                      child: TextFormField(
                        decoration: InputDecoration(
                          label: Text('No Transaksi', style: labelStyle),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: _widthInput,
                      child: TextFormField(
                        decoration: InputDecoration(
                          isDense: true,
                          label: Text('No Faktur', style: labelStyle),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: _widthInput,
                      child: DateFormField(
                        isDense: true,
                        label: Text('Tanggal Faktur', style: labelStyle),
                      ),
                    ),
                    SizedBox(
                      width: _widthInput,
                      child: DateFormField(
                        isDense: true,
                        label: Text('Tgl Barang Datang', style: labelStyle),
                      ),
                    ),
                    SizedBox(
                      width: _widthInput,
                      child: AsyncDropdown<Supplier>(
                        path: 'suppliers',
                        modelClass: SupplierClass(),
                        allowClear: false,
                        isDense: true,
                        validator: (model) {
                          if (model == null) {
                            return 'Harus diisi';
                          }
                          return null;
                        },
                        textOnSearch: (model) =>
                            "${model.code} - ${model.name}",
                        textOnSelected: (model) => model.code,
                        label: Text('Supplier', style: labelStyle),
                        selected: purchaseHeader.supplier,
                      ),
                    ),
                    SizedBox(
                      width: _widthInput,
                      child: TextFormField(
                        decoration: InputDecoration(
                          isDense: true,
                          label: Text('Lokasi'),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: _widthInput,
                      child: CheckboxListTile(
                        value: isConsignment,
                        onChanged: (val) => setState(() {
                          isConsignment = val ?? false;
                        }),
                        title: Text('Konsinyasi?'),
                      ),
                    ),
                    SizedBox(
                      width: _widthInput,
                      child: TextFormField(
                        decoration: InputDecoration(
                          isDense: true,
                          label: Text('Tipe Pajak'),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    border: TableBorder(horizontalInside: BorderSide()),
                    defaultColumnWidth: FixedColumnWidth(220),
                    columnWidths: {6: FixedColumnWidth(90)},
                    children:
                        [
                          TableRow(
                            children: [
                              TableCell(
                                child: Text('Produk', style: labelStyle),
                              ),
                              TableCell(child: Text('Opsi', style: labelStyle)),
                              TableCell(
                                child: Text('Jumlah', style: labelStyle),
                              ),
                              TableCell(
                                child: Text('Satuan', style: labelStyle),
                              ),
                              TableCell(
                                child: Text('Harga', style: labelStyle),
                              ),
                              TableCell(
                                child: Text('Barcode', style: labelStyle),
                              ),
                              TableCell(
                                child: Text('Tgl Expired', style: labelStyle),
                              ),
                              TableCell(child: Text('')),
                            ],
                          ),
                        ] +
                        tableBodies,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton.filled(
                    onPressed: addDetail,
                    tooltip: 'Tambah Baris',
                    icon: Icon(Icons.add),
                  ),
                ),
                const Divider(),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 300,
                            child: TextFormField(
                              minLines: 3,
                              maxLines: 5,
                              decoration: InputDecoration(
                                isDense: true,
                                label: Text('Keterangan'),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        spacing: 15,
                        children: [
                          SizedBox(
                            width: 250,
                            child: TextFormField(
                              decoration: InputDecoration(
                                isDense: true,
                                label: Text('Subtotal'),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 250,
                            child: TextFormField(
                              decoration: InputDecoration(
                                isDense: true,
                                label: Text('Header Diskon'),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 250,
                            child: TextFormField(
                              decoration: InputDecoration(
                                isDense: true,
                                label: Text('Pajak'),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text('Biaya Lain : '),
                              IconButton.filled(
                                onPressed: addOtherCost,
                                icon: Icon(Icons.add),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 250,
                            child: TextFormField(
                              decoration: InputDecoration(
                                isDense: true,
                                label: Text('Grand Total'),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 250,
                            child: TextFormField(
                              decoration: InputDecoration(
                                isDense: true,
                                label: Text('DP'),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: FloatingActionButton(
            onPressed: submitForm,
            isExtended: true,
            elevation: 2,
            child: Text('Simpan'),
          ),
        ),
      ],
    );
  }
}
