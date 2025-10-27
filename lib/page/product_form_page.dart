import 'package:fe_pos/model/stock_keeping_unit.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';

import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/model/product.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ProductFormPage extends StatefulWidget {
  final Product product;
  const ProductFormPage({required this.product, super.key});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage>
    with AutomaticKeepAliveClientMixin, DefaultResponse {
  final _formState = GlobalKey<FormState>();
  Product get product => widget.product;
  late final Server _server;
  bool isDetailListExpanded = false;
  final flash = Flash();
  static const labelStyle =
      TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  final descriptionController = TextEditingController();
  final supplierProductCodeController = TextEditingController();

  @override
  void initState() {
    _server = context.read<Server>();
    product.addListener(() {
      descriptionController.text = product.description;
      supplierProductCodeController.text = product.supplierProductCode ?? '';
    });

    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  void saveProduct() {
    product.save(_server).then((bool result) {
      if (result) {
        flash.show(Text('Sukses simpan produk'), ToastificationType.success);
      } else {
        flash.showBanner(
          title: 'Gagal simpan produk',
          description: product.errors.join('\n'),
          messageType: ToastificationType.error,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return VerticalBodyScroll(
      child: Form(
          key: _formState,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.start,
                runSpacing: 10,
                spacing: 10,
                children: [
                  SizedBox(
                    width: 350,
                    child: TextFormField(
                      controller: descriptionController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          label: Text(
                            'Nama Produk',
                            style: labelStyle,
                          ),
                          isDense: true,
                          border: OutlineInputBorder()),
                    ),
                  ),
                  SizedBox(
                    width: 250,
                    child: TextFormField(
                      controller: supplierProductCodeController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          label: Text(
                            'Kode Produk dari Supplier',
                            style: labelStyle,
                          ),
                          isDense: true,
                          border: OutlineInputBorder()),
                    ),
                  ),
                  SizedBox(
                    width: 250,
                    child: AsyncDropdown<ItemType>(
                        textOnSearch: (model) =>
                            "${model.name} -  ${model.description}",
                        textOnSelected: (model) => model.name,
                        selected: product.itemType,
                        allowClear: false,
                        label: Text(
                          'Jenis/Departemen',
                          style: labelStyle,
                        ),
                        path: 'item_types',
                        isDense: true,
                        onChanged: (model) => product.itemType = model,
                        modelClass: ItemTypeClass()),
                  ),
                  SizedBox(
                    width: 250,
                    child: AsyncDropdown<Brand>(
                        textOnSearch: (model) =>
                            "${model.name} -  ${model.description}",
                        textOnSelected: (model) => model.name,
                        label: Text(
                          'Merek',
                          style: labelStyle,
                        ),
                        path: 'brands',
                        allowClear: false,
                        isDense: true,
                        selected: product.brand,
                        onChanged: (model) => product.brand = model,
                        modelClass: BrandClass()),
                  ),
                  SizedBox(
                    width: 250,
                    child: AsyncDropdown<Supplier>(
                        textOnSearch: (model) =>
                            "${model.code} -  ${model.name}",
                        textOnSelected: (model) => model.name,
                        label: Text(
                          'Supplier',
                          style: labelStyle,
                        ),
                        allowClear: false,
                        path: 'suppliers',
                        isDense: true,
                        selected: product.supplier,
                        onChanged: (model) => product.supplier = model,
                        modelClass: SupplierClass()),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ExpansionPanelList(
                expansionCallback: (int index, bool isExpanded) {
                  setState(() {
                    isDetailListExpanded = isExpanded;
                  });
                },
                children: [
                  ExpansionPanel(
                    isExpanded: isDetailListExpanded,
                    headerBuilder: (context, isExpanded) => Row(
                      spacing: 10,
                      children: [
                        Text(
                          'Detail Produk',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        if (isDetailListExpanded)
                          IconButton.outlined(
                            onPressed: () => setState(() {
                              product.tags.add(ProductTag());
                            }),
                            icon: Icon(Icons.add),
                          ),
                      ],
                    ),
                    body: Table(
                      columnWidths: {2: FixedColumnWidth(150)},
                      border: TableBorder.symmetric(inside: BorderSide()),
                      children: [
                            TableRow(children: [
                              TableCell(
                                  child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Kategori',
                                  style: labelStyle,
                                ),
                              )),
                              TableCell(
                                  child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Value',
                                  style: labelStyle,
                                ),
                              )),
                              TableCell(
                                  child: IconButton(
                                      onPressed: () => showConfirmDialog(
                                          message: 'Apakah yakin hapus semua?',
                                          onSubmit: () => setState(() {
                                                product.tags.clear();
                                              })),
                                      icon: Icon(Icons.delete))),
                            ]),
                          ] +
                          product.tags.map(renderRowTag).toList(),
                    ),
                  ),
                  ExpansionPanel(
                      headerBuilder: (context, isExpanded) => Text('SKU'),
                      body: Expanded(
                        child: CustomAsyncDataTable2<StockKeepingUnit>(
                          fetchData: (QueryRequest request) {
                            request.filters.add(ComparisonFilterData(
                              key: 'product_id',
                              value: product.id.toString(),
                            ));
                            return StockKeepingUnitClass()
                                .finds(_server, request)
                                .then((queryResponse) =>
                                    DataTableResponse<StockKeepingUnit>(
                                        totalPage: queryResponse
                                                .metadata['total_pages'] ??
                                            1,
                                        models: queryResponse.models));
                          },
                          columns: [
                            TableColumn(
                                clientWidth: 200,
                                name: 'barcode',
                                humanizeName: 'Barcode'),
                            TableColumn(
                                clientWidth: 150,
                                name: 'prodDate',
                                type: TableColumnType.date,
                                humanizeName: 'Tanggal Produksi'),
                            TableColumn(
                                clientWidth: 200,
                                name: 'description',
                                humanizeName: 'Deskripsi'),
                            TableColumn(
                                clientWidth: 120,
                                name: 'quantity',
                                type: TableColumnType.number,
                                humanizeName: 'Jumlah'),
                            TableColumn(
                                clientWidth: 120,
                                name: 'uom',
                                humanizeName: 'Satuan'),
                            TableColumn(
                                clientWidth: 180,
                                name: 'cogs',
                                type: TableColumnType.money,
                                humanizeName: 'HPP'),
                            TableColumn(
                                clientWidth: 180,
                                name: 'sell_price',
                                type: TableColumnType.money,
                                humanizeName: 'Harga Jual'),
                            TableColumn(
                                clientWidth: 150,
                                name: 'expiredDate',
                                type: TableColumnType.date,
                                humanizeName: 'Tanggal Expired'),
                          ],
                          showFilter: true,
                          showSummary: true,
                        ),
                      )),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                spacing: 10,
                children: [
                  ElevatedButton(onPressed: saveProduct, child: Text('Simpan')),
                  // ElevatedButton(
                  //     onPressed: () {
                  //       setState(() {
                  //         product.reset();

                  //         descriptionController.text = product.description;
                  //         supplierProductCodeController.text =
                  //             product.supplierProductCode ?? '';
                  //       });
                  //     },
                  //     child: Text('Reset'))
                ],
              ),
            ],
          )),
    );
  }

  TableRow renderRowTag(ProductTag productTag) {
    return TableRow(children: [
      TableCell(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AsyncDropdown<Tag>(
            textOnSearch: (tag) => tag.name,
            path: 'tags',
            isDense: true,
            allowClear: false,
            selected: productTag.tag,
            modelClass: TagClass()),
      )),
      TableCell(
          child: Padding(
        padding: const EdgeInsets.only(left: 8.0, top: 15, right: 8),
        child: TextFormField(
          inputFormatters: [
            FilteringTextInputFormatter.singleLineFormatter,
            FilteringTextInputFormatter.allow(RegExp('[a-z0-9.,]')),
          ],
          decoration: InputDecoration(
            isDense: true,
            // border: UnderlineInputBorder(borderSide: BorderSide.none),
          ),
          initialValue: productTag.value,
        ),
      )),
      TableCell(
          child: IconButton(
              onPressed: () => setState(() {
                    product.tags.remove(productTag);
                  }),
              icon: Icon(Icons.delete)))
    ]);
  }
}
