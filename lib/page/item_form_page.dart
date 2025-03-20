import 'package:fe_pos/model/item.dart';
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

class _ItemFormPageState extends State<ItemFormPage> {
  Item get item => widget.item;
  late final Setting _setting;
  @override
  void initState() {
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
            maxLength: 5,
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
            readOnly: true,
            label: Text(_setting.columnName('item', 'cogs')),
          ),
          const SizedBox(
            height: 10,
          ),
          MoneyFormField(
            initialValue: item.sellPrice,
            readOnly: true,
            label: Text(_setting.columnName('item', 'sell_price')),
          ),
        ],
      ),
    );
  }
}
