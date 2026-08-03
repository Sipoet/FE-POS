import 'package:fe_pos/model/ipos/item_type.dart';
import 'package:fe_pos/tool/default_response.dart';

import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/async_dropdown.dart';
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
  late final Authorizer _setting;
  late final Server _server;
  final _formState = GlobalKey<FormState>();

  @override
  void initState() {
    _setting = context.read<Authorizer>();
    _server = context.read<Server>();

    super.initState();
    if (!itemType.isNewRecord) {
      Future.delayed(Duration.zero, fetchItemType);
    }
  }

  void fetchItemType() {
    showLoadingPopup();
    _server
        .get('item_types/${itemType.id}')
        .then((response) {
          if (mounted && response.statusCode == 200) {
            itemType.setFromJson(
              response.data['data'],
              included: response.data['included'] ?? [],
            );
          }
        })
        .whenComplete(() => hideLoadingPopup());
  }

  @override
  Widget build(BuildContext context) {
    return VerticalBodyScroll(
      child: Form(
        key: _formState,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: itemType.name,
              onChanged: (value) {
                setState(() {
                  itemType.name = value;
                });
              },
              validator: (value) {
                debugPrint(value.toString());
                if (value == null || value.isEmpty) {
                  return 'harus diisi';
                }
                return null;
              },
              decoration: InputDecoration(
                label: Text(
                  _setting.columnName('itemType', 'name'),
                  style: TextFormatter.labelStyle,
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: itemType.description,
              onChanged: (value) {
                setState(() {
                  itemType.description = value;
                });
              },
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                label: Text(
                  _setting.columnName('itemType', 'description'),
                  style: TextFormatter.labelStyle,
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            AsyncDropdown<ItemType>(
              label: const Text('Parent :', style: TextFormatter.labelStyle),
              key: const ValueKey('itemTypeSelect'),
              textOnSearch: (ItemType itemType) => itemType.name,
              selected: itemType.parent,
              modelClass: ItemTypeClass(),
              attributeKey: 'jenis',
              path: '/item_types',
              onChanged: (value) => itemType.parent = value,
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}
