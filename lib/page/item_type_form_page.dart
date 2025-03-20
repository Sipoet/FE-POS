import 'package:fe_pos/model/item_type.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ItemTypeFormPage extends StatefulWidget {
  final ItemType itemType;
  const ItemTypeFormPage({super.key, required this.itemType});

  @override
  State<ItemTypeFormPage> createState() => _ItemTypeFormPageState();
}

class _ItemTypeFormPageState extends State<ItemTypeFormPage> {
  ItemType get itemType => widget.itemType;
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
            initialValue: itemType.name,
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('itemType', 'name')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            initialValue: itemType.description,
            readOnly: true,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
                label: Text(_setting.columnName('itemType', 'description')),
                border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }
}
