import 'package:fe_pos/model/item_with_discount.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/widget/sync_data_table.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_barcode_scanner_plus/flutter_barcode_scanner_plus.dart';
import 'package:async/async.dart';

class CheckPricePage extends StatefulWidget {
  const CheckPricePage({super.key});

  @override
  State<CheckPricePage> createState() => _CheckPricePageState();
}

class _CheckPricePageState extends State<CheckPricePage>
    with DefaultResponse, PlatformChecker, LoadingPopup {
  String? finalSearch;
  late final Server _server;
  final _controller = TextEditingController();
  SyncTableController? _source;
  List<ItemWithDiscount> models = [];
  CancelableOperation? searchOperation;
  late final List<TableColumn> _columns;

  @override
  void initState() {
    _server = context.read<Server>();
    _columns = [
      TableColumn(
        clientWidth: 120,
        frozen: TrinaColumnFrozen.start,
        name: 'item_code',
        humanizeName: 'Kode Item',
      ),
      TableColumn(
        clientWidth: 200,
        name: 'item_name',
        humanizeName: 'Nama Item',
      ),
      TableColumn(
        clientWidth: 140,
        type: MoneyTableColumnType(),
        name: 'sell_price',
        humanizeName: 'Harga Normal',
      ),
      TableColumn(
        clientWidth: 180,
        type: MoneyTableColumnType(),
        name: 'sell_price_after_discount',
        humanizeName: 'Harga Setelah Diskon',
        // frozen: TrinaColumnFrozen.end,
      ),
      TableColumn<ItemWithDiscount>(
        clientWidth: 120,
        type: TextTableColumnType(),
        renderBody: (model) {
          model as ItemWithDiscount;
          return GestureDetector(
            onTap: () => model.stockLeft == 0 ? null : showStockDialog(model),
            child: Tooltip(
              message: model.stockLocations
                  .map(
                    (e) =>
                        'Lokasi ${e.locationCode} : RAK ${e.rack ?? '-'} :${e.quantity.format()}',
                  )
                  .join('\n'),
              child: Text(
                model.stockLeft.format(),
                textAlign: .right,
                style: model.stockLeft == 0
                    ? null
                    : TextStyle(fontStyle: .italic, decoration: .underline),
              ),
            ),
          );
        },
        name: 'stock_left',
        humanizeName: 'Stok',
      ),
      TableColumn(
        clientWidth: 200,
        name: 'discount_desc',
        humanizeName: 'Promo Diskon',
      ),
      TableColumn(
        clientWidth: 160,
        type: MoneyTableColumnType(),
        name: 'discount_amount',
        humanizeName: 'Jumlah Diskon',
      ),

      TableColumn(clientWidth: 90, name: 'uom', humanizeName: 'Satuan'),
    ];
    super.initState();
  }

  void _openCamera() {
    FlutterBarcodeScanner.scanBarcode(
      '#ff6666',
      'Batal',
      true,
      ScanMode.BARCODE,
    ).then((res) {
      if (res.isNotEmpty && res != '-1') {
        setState(() {
          finalSearch = res;
        });
        _searchItem();
      }
    });
  }

  void showStockDialog(ItemWithDiscount model) {
    for (final stockLocation in model.stockLocations) {
      stockLocation['tempRack'] = stockLocation.rack;
    }
    showDialog(
      context: context,
      builder: (context) {
        bool onEdit = false;
        bool isProgress = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Text('Stok ${model.code}'),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: .min,
              mainAxisAlignment: .start,
              crossAxisAlignment: .start,
              spacing: 10,
              children: [
                Text('Nama Item: ${model.name}'),
                Table(
                  border: TableBorder.symmetric(inside: BorderSide()),
                  columnWidths: {
                    0: FlexColumnWidth(0.5),
                    2: FixedColumnWidth(65),
                  },
                  children: [
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 5.0, top: 10),
                          child: Text('Lokasi', style: labelStyle),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 5.0),
                          child: Row(
                            mainAxisAlignment: .spaceBetween,
                            children: [
                              Text('Rak', style: labelStyle),
                              Visibility(
                                visible: onEdit,
                                replacement: IconButton(
                                  onPressed: () => setStateDialog(() {
                                    onEdit = true;
                                  }),
                                  icon: Icon(Icons.edit),
                                ),
                                child: Row(
                                  mainAxisAlignment: .spaceEvenly,
                                  children: [
                                    IconButton(
                                      onPressed: () => setStateDialog(() {
                                        onEdit = false;
                                        isProgress = true;
                                        saveRack(model, setStateDialog).then(
                                          (value) => setStateDialog(() {
                                            isProgress = false;
                                          }),
                                        );
                                      }),
                                      icon: Icon(Icons.check),
                                    ),

                                    IconButton(
                                      onPressed: () => setStateDialog(() {
                                        onEdit = false;
                                        isProgress = true;
                                        Future.delayed(Durations.short2, () {
                                          setStateDialog(() {
                                            isProgress = false;
                                          });
                                        });
                                      }),
                                      icon: Icon(Icons.cancel),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 5.0, top: 10),
                          child: Text(
                            'Jumlah',
                            style: labelStyle,
                            textAlign: .right,
                          ),
                        ),
                      ],
                    ),
                    if (!isProgress)
                      ...model.stockLocations.map<TableRow>(
                        (stock) => TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Text(stock.locationCode),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: TextFormField(
                                readOnly: !onEdit,
                                initialValue: stock['tempRack'],
                                onChanged: (value) => setStateDialog(() {
                                  stock['tempRack'] = value;
                                }),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Text(
                                stock.quantity.format(),
                                textAlign: .right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isProgress)
                      TableRow(
                        children: [
                          const SizedBox(),
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: loadingWidget(),
                          ),
                          const SizedBox(),
                        ],
                      ),
                    if (!isProgress)
                      TableRow(
                        children: [
                          SizedBox(),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Text(
                              'Total',
                              style: labelStyle,
                              textAlign: .right,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Text(
                              model.stockLeft.format(),
                              textAlign: .right,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List> saveRack(
    ItemWithDiscount model,
    StateSetter setStateDialog,
  ) async {
    final server = context.read<Server>();
    return Future.wait(
      model.stockLocations.map<Future>((stockLocation) {
        stockLocation['beforeRack'] = stockLocation.rack;
        stockLocation.rack = stockLocation['tempRack'];
        return server
            .put(
              'ipos/item_stocks/${stockLocation.itemCode}',
              body: {
                'data': {
                  'id': stockLocation.itemCode,
                  'type': 'item_stock',
                  'attributes': stockLocation.toJson(),
                },
              },
            )
            .then(
              (response) {
                setStateDialog(() {
                  if (response.statusCode != 200) {
                    stockLocation.rack = stockLocation['beforeRack'];
                    return;
                  }
                  stockLocation.setFromJson(
                    response.data['data'],
                    included: response.data['included'] ?? [],
                  );
                });
              },
              onError: (error) {
                setStateDialog(() {
                  stockLocation.rack = stockLocation['beforeRack'];
                });
                defaultErrorResponse(error: error);
              },
            );
      }),
    );
  }

  Widget decorateStock(ItemWithDiscount model) => Column(
    mainAxisAlignment: .start,
    crossAxisAlignment: .start,
    mainAxisSize: .min,
    children:
        model.stockLocations
            .map<Widget>(
              (group) => Text(
                '${group.locationCode}: RAK ${group.rack}. jumlah: ${group.quantity} ${model.uom}',
              ),
            )
            .toList()
          ..add(Text('Total: ${model.stockLeft.format()}')),
  );

  void openStockFormDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog();
        },
      ),
    );
  }

  static const labelStyle = TextStyle(fontWeight: FontWeight.bold);
  final _focusNode = FocusNode();
  @override
  Widget build(BuildContext context) {
    return VerticalBodyScroll(
      child: Column(
        children: [
          Offstage(
            offstage: !(isIOS() || isAndroid()),
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: ElevatedButton.icon(
                icon: Icon(Icons.camera_alt_outlined, size: 45),
                onPressed: () => _openCamera(),
                label: Text('Open Camera'),
              ),
            ),
          ),
          TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: (value) {
              searchOperation?.cancel();
              searchOperation = CancelableOperation<String>.fromFuture(
                Future<String>.delayed(Durations.extralong3, () => value),
                onCancel: () => debugPrint('search cancel'),
              );
              searchOperation!.value.then((value) {
                setState(() {
                  finalSearch = value;
                  _searchItem();
                });
              });
            },
            onFieldSubmitted: (value) {
              setState(() {
                finalSearch = value;
                _controller.text = '';
              });
              _searchItem();
              _focusNode.requestFocus();
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
                icon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Visibility(
            visible: finalSearch != null,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: SelectableText("Kata Yang dicari: $finalSearch"),
            ),
          ),
          SizedBox(
            height: bodyScreenHeight,
            child: SyncDataTable<ItemWithDiscount>(
              showSearch: false,
              showFilter: false,
              columns: _columns,
              onLoaded: (stateManager) => _source = stateManager,
            ),
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
    _server
        .get(
          'ipos/items/with_discount',
          queryParam: {
            'search_text': finalSearch,
            'page[page]': '1',
            'page[limit]': '100',
            'include': 'stocks',
          },
        )
        .then((response) {
          if (mounted && response.statusCode == 200) {
            final data = response.data;
            setState(() {
              models = data['data']
                  .map<ItemWithDiscount>(
                    (row) => ItemWithDiscountClass().fromJson(
                      row,
                      included: data['included'] ?? [],
                    ),
                  )
                  .toList();
            });

            _source?.setModels(models);
          }
        }, onError: (error) => defaultErrorResponse(error: error))
        .whenComplete(() {
          _source?.setShowLoading(false);
        });
  }
}
