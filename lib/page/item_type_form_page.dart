import 'package:fe_pos/model/item_type.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/loading_popup.dart';
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

class _ItemTypeFormPageState extends State<ItemTypeFormPage>
    with DefaultResponse, LoadingPopup {
  ItemType get itemType => widget.itemType;
  late final Setting _setting;
  late final Server _server;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  @override
  void initState() {
    _setting = context.read<Setting>();
    _server = context.read<Server>();
    _nameController = TextEditingController(text: itemType.name);
    _descriptionController = TextEditingController(text: itemType.description);
    super.initState();
    if (itemType.rawData.isEmpty) {
      Future.delayed(Duration.zero, fetchItemType);
    }
  }

  void fetchItemType() {
    showLoadingPopup();
    _server.get('item_types/${itemType.id}').then((response) {
      if (mounted && response.statusCode == 200) {
        ItemType.fromJson(response.data['data'],
            included: response.data['included'] ?? [], model: itemType);
        _nameController.text = itemType.name;
        _descriptionController.text = itemType.description;
      }
    }).whenComplete(() => hideLoadingPopup());
  }

  @override
  Widget build(BuildContext context) {
    return VerticalBodyScroll(
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('itemType', 'name')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            controller: _descriptionController,
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
