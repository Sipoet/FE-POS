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
  @override
  void initState() {
    _flash = Flash();
    _setting = context.read<Setting>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return VerticalBodyScroll(
      child: Column(
        children: [
          TextFormField(
            initialValue: item.code,
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('item', 'code')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            initialValue: item.name,
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('item', 'name')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            initialValue: item.description,
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
          TextFormField(
            initialValue: item.brandName,
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('item', 'brand_name')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            initialValue: item.uom,
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('item', 'uom')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          MoneyFormField(
            initialValue: item.cogs,
            onChanged: (value) => item.cogs = value ?? item.cogs,
            label: Text(_setting.columnName('item', 'cogs')),
          ),
          const SizedBox(
            height: 10,
          ),
          MoneyFormField(
            initialValue: item.sellPrice,
            onChanged: (value) => item.sellPrice = value ?? item.sellPrice,
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
          Item.fromJson(response.data['data'],
              included: response.data['included'], model: item);
        });

        _flash.show(Text('Sukses simpan item'), ToastificationType.success);
      } else {
        _flash.show(Text('Gagal simpan item'), ToastificationType.error);
      }
    }, onError: (error) => defaultErrorResponse(error: error)).whenComplete(
        () => hideLoadingPopup());
  }
}
