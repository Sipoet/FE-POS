import 'package:fe_pos/widget/date_form_field.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';

class NewPurchaseFormPage extends StatefulWidget {
  const NewPurchaseFormPage({super.key});

  @override
  State<NewPurchaseFormPage> createState() => _NewPurchaseFormPageState();
}

class _NewPurchaseFormPageState extends State<NewPurchaseFormPage> {
  bool isConsignment = false;
  List details = [{}];
  void openDetailSkus(detail) {}

  void addDetail() {
    setState(() {
      details.add({});
    });
  }

  void removeDetail(detail) {
    setState(() {
      details.remove(detail);
    });
  }

  void addOtherCost() {}

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
        fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2);
    return VerticalBodyScroll(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            runSpacing: 20,
            spacing: 20,
            children: [
              SizedBox(
                width: 200,
                child: TextFormField(
                  decoration: InputDecoration(
                      label: Text('No Transaksi'),
                      isDense: true,
                      border: OutlineInputBorder()),
                ),
              ),
              SizedBox(
                width: 200,
                child: TextFormField(
                  decoration: InputDecoration(
                      isDense: true,
                      label: Text('No Faktur'),
                      border: OutlineInputBorder()),
                ),
              ),
              SizedBox(
                width: 200,
                child: DateFormField(
                  label: Text('Tanggal Faktur'),
                ),
              ),
              SizedBox(
                width: 200,
                child: DateFormField(
                  label: Text('Tgl Barang Datang'),
                ),
              ),
              SizedBox(
                width: 200,
                child: TextFormField(
                  decoration: InputDecoration(
                      isDense: true,
                      label: Text('Supplier'),
                      border: OutlineInputBorder()),
                ),
              ),
              SizedBox(
                width: 200,
                child: TextFormField(
                  decoration: InputDecoration(
                      isDense: true,
                      label: Text('Lokasi'),
                      border: OutlineInputBorder()),
                ),
              ),
              SizedBox(
                width: 200,
                child: CheckboxListTile(
                  value: isConsignment,
                  onChanged: (val) => setState(() {
                    isConsignment = val ?? false;
                  }),
                  title: Text('Konsinyasi?'),
                ),
              ),
              SizedBox(
                width: 200,
                child: TextFormField(
                  decoration: InputDecoration(
                      isDense: true,
                      label: Text('Tipe Pajak'),
                      border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 20,
          ),
          IconButton.filled(
            onPressed: addDetail,
            icon: Icon(Icons.add),
          ),
          SizedBox(
            height: 20,
          ),
          Table(
              border: TableBorder(horizontalInside: BorderSide()),
              defaultColumnWidth: FixedColumnWidth(220),
              children: [
                    TableRow(children: [
                      TableCell(
                        child: Text(
                          'Produk',
                          style: labelStyle,
                        ),
                      ),
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
                      TableCell(
                        child: Text(''),
                      ),
                    ])
                  ] +
                  details
                      .map<TableRow>(
                        (detail) => TableRow(children: [
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                children: [
                                  TextFormField(
                                    decoration: InputDecoration(
                                        isDense: true,
                                        border: OutlineInputBorder()),
                                  ),
                                  Row(
                                    children: [
                                      Text('Tags: '),
                                      Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: Text(
                                            'UK XL',
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ),
                                      ),
                                      Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: Text(
                                            'Warna Hitam',
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder()),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder()),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder()),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextFormField(
                                decoration: InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder()),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: DateFormField(),
                            ),
                          ),
                          TableCell(
                              child: Row(
                            children: [
                              IconButton(
                                  onPressed: () => openDetailSkus(detail),
                                  icon: Icon(Icons.arrow_downward_outlined)),
                              IconButton(
                                  onPressed: () => removeDetail(detail),
                                  icon: Icon(Icons.remove))
                            ],
                          ))
                        ]),
                      )
                      .toList()),
          SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
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
                            border: OutlineInputBorder()),
                      ),
                    )
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
                            border: OutlineInputBorder()),
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      child: TextFormField(
                        decoration: InputDecoration(
                            isDense: true,
                            label: Text('Header Diskon'),
                            border: OutlineInputBorder()),
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      child: TextFormField(
                        decoration: InputDecoration(
                            isDense: true,
                            label: Text('Pajak'),
                            border: OutlineInputBorder()),
                      ),
                    ),
                    Row(
                      children: [
                        Text('Biaya Lain : '),
                        IconButton.filled(
                            onPressed: addOtherCost, icon: Icon(Icons.add))
                      ],
                    ),
                    SizedBox(
                      width: 250,
                      child: TextFormField(
                        decoration: InputDecoration(
                            isDense: true,
                            label: Text('Grand Total'),
                            border: OutlineInputBorder()),
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      child: TextFormField(
                        decoration: InputDecoration(
                            isDense: true,
                            label: Text('DP'),
                            border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
