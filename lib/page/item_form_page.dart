import 'package:fe_pos/model/item.dart';

import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
import 'package:fe_pos/widget/money_form_field.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ItemFormPage extends StatefulWidget {
  final Item item;
  const ItemFormPage({super.key, required this.item});

  @override
  State<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends State<ItemFormPage>
    with LoadingPopup, DefaultResponse {
  Item get item => widget.item;
  late final Setting _setting;
  late final Flash _flash;
  late final Server _server;
  final Map<String, TextEditingController> _controller = {};

  @override
  void initState() {
    _flash = Flash();
    _setting = context.read<Setting>();
    _server = context.read<Server>();
    item.toMap().forEach((key, value) {
      _controller[key] = TextEditingController(text: value.toString());
    });
    super.initState();
    if (item.rawData.isEmpty) {
      Future.delayed(Duration.zero, fetchItem);
    }
  }

  void fetchItem() {
    showLoadingPopup();
    item
        .refresh(_server)
        .then((isSuccess) {
          if (isSuccess) {
            setState(() {
              item.toMap().forEach((key, value) {
                _controller[key]!.text = value.toString();
              });
            });
          }
        })
        .whenComplete(() => hideLoadingPopup());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        SizedBox(
          height: bodyScreenHeight,
          child: VerticalBodyScroll(
            child: Column(
              spacing: 10,
              crossAxisAlignment: .start,
              children: [
                Visibility(
                  visible: _setting.canShow('ipos::Item', 'code'),
                  child: TextFormField(
                    controller: _controller['code'],
                    readOnly: true,
                    decoration: InputDecoration(
                      label: Text(_setting.columnName('ipos::Item', 'code')),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Visibility(
                  visible: _setting.canShow('ipos::Item', 'name'),
                  child: TextFormField(
                    controller: _controller['name'],
                    decoration: InputDecoration(
                      label: Text(_setting.columnName('ipos::Item', 'name')),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => item.name = value,
                  ),
                ),
                Visibility(
                  visible: _setting.canShow('ipos::Item', 'brand_name'),
                  child: IgnorePointer(
                    ignoring: !_setting.isAuthorize('brand', 'index'),
                    child: AsyncDropdown<Brand>(
                      allowClear: false,
                      textOnSearch: (e) => e.modelValue,
                      modelClass: BrandClass(),
                      label: Text(_setting.columnName('ipos::Item', 'brand')),
                      onChanged: (model) => item.brand = model,
                      selected: item.brand,
                    ),
                  ),
                ),
                Visibility(
                  visible: _setting.canShow('ipos::Item', 'item_type_name'),
                  child: IgnorePointer(
                    ignoring: !_setting.isAuthorize('itemType', 'index'),
                    child: AsyncDropdown<ItemType>(
                      allowClear: false,
                      textOnSearch: (model) =>
                          '${model.name} - ${model.description}',
                      modelClass: ItemTypeClass(),
                      label: Text(
                        _setting.columnName('ipos::Item', 'item_type'),
                      ),
                      onChanged: (model) =>
                          item.itemType = model ?? item.itemType,
                      selected: item.itemType,
                    ),
                  ),
                ),
                Visibility(
                  visible: _setting.canShow('ipos::Item', 'supplier_code'),
                  child: IgnorePointer(
                    ignoring: !_setting.isAuthorize('supplier', 'index'),
                    child: AsyncDropdown<Supplier>(
                      allowClear: false,
                      textOnSearch: (model) => '${model.code} - ${model.name}',
                      modelClass: SupplierClass(),
                      label: Text(
                        _setting.columnName('ipos::Item', 'supplier'),
                      ),
                      onChanged: (model) =>
                          item.supplier = model ?? item.supplier,
                      selected: item.supplier,
                    ),
                  ),
                ),
                Visibility(
                  visible: _setting.canShow('ipos::Item', 'uom'),
                  child: TextFormField(
                    controller: _controller['uom'],
                    readOnly: true,
                    decoration: InputDecoration(
                      label: Text(_setting.columnName('ipos::Item', 'uom')),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Visibility(
                  visible: _setting.canShow('ipos::Item', 'description'),
                  child: TextFormField(
                    controller: _controller['description'],
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      label: Text(
                        _setting.columnName('ipos::Item', 'description'),
                      ),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => item.description = value,
                  ),
                ),
                Visibility(
                  visible: _setting.canShow('ipos::Item', 'cogs'),
                  child: MoneyFormField(
                    controller: _controller['cogs'],
                    onChanged: (value) {
                      setState(() {
                        item.cogs = value ?? item.cogs;
                      });
                    },
                    label: Text(_setting.columnName('ipos::Item', 'cogs')),
                  ),
                ),
                Visibility(
                  visible: _setting.canShow('ipos::Item', 'sell_price'),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Margin: ${item.margin.format()}'),
                  ),
                ),
                Visibility(
                  visible: _setting.canShow('ipos::Item', 'sell_price'),
                  child: MoneyFormField(
                    controller: _controller['sell_price'],
                    onChanged: (value) {
                      setState(() {
                        item.sellPrice = value ?? item.sellPrice;
                      });
                    },
                    label: Text(
                      _setting.columnName('ipos::Item', 'sell_price'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(top: 15.0, left: 10),
          child: ElevatedButton(onPressed: _submit, child: Text('Submit')),
        ),
      ],
    );
  }

  void _submit() {
    showLoadingPopup();
    final server = context.read<Server>();
    if (item.isNewRecord) return;
    final params = {
      'data': {'id': item.id, 'type': 'item', 'attributes': item.toJson()},
    };
    server
        .put('items/${item.code}', body: params)
        .then((response) {
          if (mounted && response.statusCode == 200) {
            setState(() {
              item.setFromJson(
                response.data['data'],
                included: response.data['included'] ?? [],
              );
            });

            _flash.show(Text('Sukses simpan item'), ToastificationType.success);
          } else {
            _flash.show(Text('Gagal simpan item'), ToastificationType.error);
          }
        }, onError: (error) => defaultErrorResponse(error: error))
        .whenComplete(() => hideLoadingPopup());
  }
}
