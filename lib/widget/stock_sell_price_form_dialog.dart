import 'package:fe_pos/model/product_measurement.dart';
import 'package:fe_pos/model/stock_keeping_unit.dart';
import 'package:fe_pos/model/stock_sell_price.dart';
import 'package:fe_pos/model/unit_of_measurement.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/model_route.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/money_form_field.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/number_form_field.dart';
import 'package:fe_pos/widget/table_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StockSellPriceFormDialog extends StatefulWidget {
  final TabManager tabManager;
  final List<ProductMeasurement> productMeasurements;

  final NavigatorState navigator;
  final StockKeepingUnit stockKeepingUnit;
  const StockSellPriceFormDialog({
    super.key,
    required this.tabManager,
    required this.navigator,
    required this.stockKeepingUnit,
    required this.productMeasurements,
  });

  @override
  State<StockSellPriceFormDialog> createState() =>
      _StockSellPriceFormDialogState();
}

class _StockSellPriceFormDialogState extends State<StockSellPriceFormDialog>
    with TextFormatter {
  final scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  List<StockSellPrice> get stockSellPrices =>
      widget.stockKeepingUnit.stockSellPrices;
  NavigatorState get navigator => widget.navigator;
  TabManager get tabManager => widget.tabManager;
  late final Server _server;
  final router = ModelRoute();

  @override
  void initState() {
    _server = context.read<Server>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Form(
      key: _formKey,
      autovalidateMode: .always,
      child: AlertDialog(
        title: Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Flexible(
              child: Text(
                'SKU ${widget.stockKeepingUnit.uniqCode} untuk barcode ${widget.stockKeepingUnit.barcode}',
              ),
            ),
            IconButton(onPressed: closeDialog, icon: Icon(Icons.close)),
          ],
        ),
        content: SizedBox(
          height: size.height - 30,
          width: size.width - 30,
          child: Scrollbar(
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 8,
            controller: scrollController,
            child: SingleChildScrollView(
              controller: scrollController,
              child: TableForm<StockSellPrice>(
                columns: [
                  TableFormColumn(
                    title: 'Satuan',
                    headerBuilder: (context) =>
                        Text('Satuan', style: TextFormatter.tableLabelStyle),
                    rowBuilder: (context, stockSellPrice) =>
                        AsyncDropdown<UnitOfMeasurement>(
                          textOnSearch: (model) => model.name ?? '',
                          modelClass: UnitOfMeasurementClass(),
                          selected: stockSellPrice.uom,
                          validator: (uom) {
                            if (uom == null) {
                              return 'harus dipilih';
                            }
                            return null;
                          },
                          onChanged: (uom) => stockSellPrice.uom = uom,
                          request: (queryRequest) {
                            queryRequest.filters = [
                              ComparisonFilterData(
                                key: 'group_name',
                                value: widget.productMeasurements
                                    .map((e) => e.uom?.groupName)
                                    .toList(),
                              ),
                            ];
                            return UnitOfMeasurementClass().finds(
                              _server,
                              queryRequest,
                            );
                          },
                        ),
                  ),
                  TableFormColumn(
                    title: 'Maksimal Jumlah',
                    isNumeric: true,
                    headerBuilder: (context) => Row(
                      spacing: 10,
                      children: [
                        Flexible(
                          child: Text(
                            'Maksimal Jumlah',
                            style: TextFormatter.tableLabelStyle,
                          ),
                        ),
                        Tooltip(
                          message: 'kosongkan jika tidak ada maksimal jumlah',
                          child: Icon(Icons.help, size: 15),
                        ),
                      ],
                    ),
                    rowBuilder: (context, stockSellPrice) => NumberFormField(
                      initialValue: stockSellPrice.maxQuantity,
                      onChanged: (value) => stockSellPrice.maxQuantity = value,
                      validator: (value) {
                        if (value == null) {
                          return 'harus diisi';
                        }
                        if (value <= 0) {
                          return 'tidak boleh negatif dan 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  TableFormColumn(
                    title: 'Harga Jual',
                    isNumeric: true,
                    headerBuilder: (context) => Text(
                      'Harga Jual',
                      style: TextFormatter.tableLabelStyle,
                    ),
                    rowBuilder: (context, stockSellPrice) => MoneyFormField(
                      initialValue: stockSellPrice.sellPrice,
                      onChanged: (value) => stockSellPrice.sellPrice = value,
                      validator: (value) {
                        if (value == null) {
                          return 'harus diisi';
                        }
                        if (value <= 0) {
                          return 'tidak boleh negatif dan 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
                actionColumn: TableFormColumn(
                  headerBuilder: (context) => IconButton(
                    onPressed: () => setState(() {
                      stockSellPrices.add(StockSellPriceClass().initModel());
                    }),
                    icon: Icon(Icons.add),
                  ),
                  rowBuilder: (context, model) => IconButton(
                    onPressed: () {
                      setState(() {
                        if (model.isNewRecord) {
                          stockSellPrices.remove(model);
                        } else {
                          model.flagDestroy();
                        }
                      });
                    },
                    icon: Icon(Icons.delete),
                  ),
                ),
                rows: stockSellPrices,
              ),
            ),
          ),
        ),
        actionsPadding: .all(15),
        actionsAlignment: .start,
        actionsOverflowButtonSpacing: 20,
        actionsOverflowAlignment: .start,
        actionsOverflowDirection: .down,
        actions: [
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() != true) {
                return;
              }
              _formKey.currentState?.save();

              _saveRecords();
            },
            child: Text('Simpan'),
          ),
          const SizedBox(width: 20),
          ElevatedButton(onPressed: closeDialog, child: Text('Batal')),
        ],
      ),
    );
  }

  void closeDialog() {
    for (var stockSellPrice in stockSellPrices) {
      stockSellPrice.reset();
    }
    navigator.pop();
  }

  void _saveRecords() {
    widget.stockKeepingUnit
        .save(_server, only: ['stock_sell_prices_attributes'])
        .then((isSuccess) {
          final flash = Flash();
          if (isSuccess) {
            flash.show(Text('Sukses simpan Harga Jual'), .success);
          } else {
            flash.show(Text('Gagal simpan Harga Jual'), .error);
          }
        });
  }
}
