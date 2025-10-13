import 'package:fe_pos/model/item.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
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
    _server.get('items/${item.id}').then((response) {
      if (mounted && response.statusCode == 200) {
        item.setFromJson(response.data['data'],
            included: response.data['included'] ?? []);

        setState(() {
          item.toMap().forEach((key, value) {
            _controller[key]!.text = value.toString();
          });
        });
      }
    }).whenComplete(() => hideLoadingPopup());
  }

  @override
  Widget build(BuildContext context) {
    return VerticalBodyScroll(
      child: Column(
        children: [
          TextFormField(
            controller: _controller['code'],
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('item', 'code')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            controller: _controller['name'],
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('item', 'name')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            controller: _controller['brand_name'],
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('item', 'brand_name')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            controller: _controller['item_type_name'],
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('item', 'item_type_name')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            controller: _controller['supplier_code'],
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('item', 'supplier_code')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            controller: _controller['uom'],
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('item', 'uom')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            controller: _controller['description'],
            readOnly: true,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
                label: Text(_setting.columnName('item', 'description')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          MoneyFormField(
            controller: _controller['cogs'],
            onChanged: (value) {
              setState(() {
                item.cogs = value ?? item.cogs;
              });
            },
            label: Text(_setting.columnName('item', 'cogs')),
          ),
          const SizedBox(
            height: 10,
          ),
          Align(
              alignment: Alignment.centerLeft,
              child: Text('Margin: ${item.margin.format()}')),
          const SizedBox(
            height: 10,
          ),
          MoneyFormField(
            controller: _controller['sell_price'],
            onChanged: (value) {
              setState(() {
                item.sellPrice = value ?? item.sellPrice;
              });
            },
            label: Text(_setting.columnName('item', 'sell_price')),
          ),
          const SizedBox(
            height: 10,
          ),
          ElevatedButton(onPressed: _submit, child: Text('Submit')),
        ],
      ),
    );
  }

  void _submit() {
    showLoadingPopup();
    final server = context.read<Server>();
    if (item.isNewRecord) return;
    final params = {
      'data': {
        'id': item.id,
        'type': 'item',
        'attributes': item.toJson(),
      }
    };
    server.put('items/${item.code}', body: params).then((response) {
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
    }, onError: (error) => defaultErrorResponse(error: error)).whenComplete(
        () => hideLoadingPopup());
  }
}
