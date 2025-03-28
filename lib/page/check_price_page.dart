import 'package:fe_pos/model/item_with_discount.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/widget/sync_data_table.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_barcode_scanner_plus/flutter_barcode_scanner_plus.dart';

class CheckPricePage extends StatefulWidget {
  const CheckPricePage({super.key});

  @override
  State<CheckPricePage> createState() => _CheckPricePageState();
}

class _CheckPricePageState extends State<CheckPricePage>
    with DefaultResponse, PlatformChecker {
  String? finalSearch;
  late final Server _server;
  final _controller = TextEditingController();
  PlutoGridStateManager? _source;
  List<ItemWithDiscount> models = [];
  final List<TableColumn> _columns = [
    TableColumn(
        clientWidth: 120,
        frozen: PlutoColumnFrozen.start,
        name: 'item_code',
        humanizeName: 'Kode Item'),
    TableColumn(clientWidth: 200, name: 'item_name', humanizeName: 'Nama Item'),
    TableColumn(
        clientWidth: 100,
        type: TableColumnType.number,
        name: 'store_stock',
        humanizeName: 'Stok Toko'),
    TableColumn(
        clientWidth: 160,
        type: TableColumnType.money,
        name: 'sell_price',
        humanizeName: 'Harga Jual'),
    TableColumn(
        clientWidth: 200, name: 'discount_desc', humanizeName: 'Promo Diskon'),
    TableColumn(
        clientWidth: 160,
        type: TableColumnType.money,
        name: 'discount_amount',
        humanizeName: 'Jumlah Diskon'),
    TableColumn(clientWidth: 90, name: 'uom', humanizeName: 'Satuan'),
    TableColumn(
        clientWidth: 110,
        type: TableColumnType.number,
        name: 'warehouse_stock',
        humanizeName: 'Stok Gudang'),
    TableColumn(
        clientWidth: 160,
        type: TableColumnType.money,
        name: 'sell_price_after_discount',
        humanizeName: 'Harga Setelah Diskon',
        frozen: PlutoColumnFrozen.end),
  ];

  @override
  void initState() {
    _server = context.read<Server>();
    super.initState();
  }

  void _openCamera() {
    FlutterBarcodeScanner.scanBarcode(
            '#ff6666', 'Batal', true, ScanMode.BARCODE)
        .then((res) {
      if (res.isNotEmpty && res != '-1') {
        setState(() {
          finalSearch = res;
        });
        _searchItem();
      }
    });
  }

  static const labelStyle = TextStyle(fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final padding = MediaQuery.of(context).padding;
    final size = MediaQuery.of(context).size;
    double tableHeight = size.height - padding.top - padding.bottom - 280;
    tableHeight = tableHeight < 400 ? 400 : tableHeight;
    return VerticalBodyScroll(
      child: Column(
        children: [
          Offstage(
            offstage: !(isIOS() || isAndroid()),
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: ElevatedButton.icon(
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    size: 45,
                  ),
                  onPressed: () => _openCamera(),
                  label: Text('Open Camera')),
            ),
          ),
          TextFormField(
            controller: _controller,
            onFieldSubmitted: (value) {
              setState(() {
                finalSearch = value;
                _controller.text = '';
              });
              _searchItem();
            },
            decoration: InputDecoration(
                label: Text('Barcode / keterangan barang'),
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        finalSearch = _controller.text;
                        _controller.text = '';
                      });
                    },
                    icon: Icon(Icons.search))),
          ),
          const SizedBox(
            height: 10,
          ),
          Visibility(
              visible: finalSearch != null,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: SelectableText("Kata Yang dicari: $finalSearch"),
              )),
          SizedBox(
            height: tableHeight,
            child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
              if (size.height > size.width || size.height <= 420) {
                return ListView(
                  children: models
                      .map<Widget>((model) => Card(
                            surfaceTintColor: colorScheme.outline,
                            child: ListTile(
                              key: ValueKey(model.code),
                              title: RichText(
                                text: TextSpan(
                                    text: "Kode Item: ",
                                    style: TextStyle(color: Colors.black),
                                    children: [
                                      TextSpan(
                                          text: model.code, style: labelStyle)
                                    ]),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Table(
                                    columnWidths: {
                                      0: FlexColumnWidth(1),
                                      1: FlexColumnWidth(2)
                                    },
                                    border: TableBorder(
                                      horizontalInside: BorderSide(
                                        color: Colors.grey.shade400
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    children: [
                                      TableRow(children: [
                                        TableCell(
                                            child: Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: Text(
                                            'Nama Item',
                                            style: labelStyle,
                                          ),
                                        )),
                                        TableCell(
                                            child: Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: Text(
                                            model.name,
                                          ),
                                        ))
                                      ]),
                                      TableRow(children: [
                                        TableCell(
                                            child: Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: Text(
                                            'Harga Jual',
                                            style: labelStyle,
                                          ),
                                        )),
                                        TableCell(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Align(
                                              alignment: Alignment.topRight,
                                              child: Text(model.sellPrice
                                                  .format(decimalDigits: 0)),
                                            ),
                                          ),
                                        ),
                                      ]),
                                      if (model.discountDesc != null &&
                                          model.discountDesc!.isNotEmpty)
                                        TableRow(children: [
                                          TableCell(
                                              child: Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Text(
                                              'Diskon',
                                              style: labelStyle,
                                            ),
                                          )),
                                          TableCell(
                                              child: Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Text(
                                              model.discountDesc ?? '',
                                            ),
                                          ))
                                        ]),
                                      if (model.sellPrice !=
                                          model.sellPriceAfterDiscount)
                                        TableRow(children: [
                                          TableCell(
                                              child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'Harga Setelah Diskon',
                                              style: labelStyle,
                                            ),
                                          )),
                                          TableCell(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Align(
                                                alignment: Alignment.topRight,
                                                child: Text(model
                                                    .sellPriceAfterDiscount
                                                    .format(decimalDigits: 0)),
                                              ),
                                            ),
                                          ),
                                        ]),
                                      TableRow(children: [
                                        TableCell(
                                            child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            'Stok',
                                            style: labelStyle,
                                          ),
                                        )),
                                        TableCell(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                                "TOKO: ${model.storeStock}, Gudang: ${model.warehouseStock}"),
                                          ),
                                        ),
                                      ]),
                                      TableRow(children: [
                                        TableCell(
                                            child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            'Satuan',
                                            style: labelStyle,
                                          ),
                                        )),
                                        TableCell(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(model.uom),
                                          ),
                                        ),
                                      ]),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                );
              } else {
                return SyncDataTable(
                  showFilter: false,
                  columns: _columns,
                  onLoaded: (stateManager) => _source = stateManager,
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  void _searchItem() {
    if (finalSearch == null || finalSearch!.trim().isEmpty) {
      return;
    }
    _source?.setShowLoading(true);
    _server.get('items/with_discount', queryParam: {
      'search_text': finalSearch,
      'page[page]': '1',
      'page[limit]': '100'
    }).then((response) {
      if (mounted && response.statusCode == 200) {
        final data = response.data;
        setState(() {
          models = data['data']
              .map<ItemWithDiscount>((row) => ItemWithDiscount.fromJson(row,
                  included: data['included'] ?? []))
              .toList();
        });

        _source?.setModels(models, _columns);
      }
    }, onError: (error) => defaultErrorResponse(error: error)).whenComplete(
        () => _source?.setShowLoading(false));
  }
}
