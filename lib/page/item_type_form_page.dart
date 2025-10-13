import 'package:fe_pos/model/item_type.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
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
  late final Setting _setting;
  late final Server _server;
  final _formState = GlobalKey<FormState>();
  late final TabManager _tabManager;
  // late final Flash _flash;
  @override
  void initState() {
    _setting = context.read<Setting>();
    _server = context.read<Server>();
    _tabManager = context.read<TabManager>();
    // _flash = context.read<Flash>();
    super.initState();
    if (!itemType.isNewRecord) {
      Future.delayed(Duration.zero, fetchItemType);
    }
  }

  void fetchItemType() {
    showLoadingPopup();
    _server.get('item_types/${itemType.id}').then((response) {
      if (mounted && response.statusCode == 200) {
        itemType.setFromJson(response.data['data'],
            included: response.data['included'] ?? []);
      }
    }).whenComplete(() => hideLoadingPopup());
  }

  void save() {
    if (_formState.currentState?.validate() == false) {
      return;
    }
    showLoadingPopup();
    final params = {
      'data': {
        'id': itemType.id,
        'type': 'item',
        'attributes': itemType.toJson(),
      }
    };
    Future response;
    if (itemType.isNewRecord) {
      response = _server.post('item_types', body: params);
    } else {
      response = _server.put('item_types/${itemType.id}', body: params);
    }
    response.then((response) {
      if (mounted && [200, 201].contains(response.statusCode)) {
        setState(() {
          itemType.setFromJson(response.data['data'],
              included: response.data['included'] ?? []);
        });
        _tabManager.changeTabHeader(widget, 'Edit Jenis ${itemType.name}');
        toastification.show(
          title: Text(
            'Sukses simpan Jenis',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          type: ToastificationType.success,
          autoCloseDuration: Duration(seconds: 3),
        );
      } else {
        final String errorMessage = response.statusCode == 409
            ? response.data['errors'].toString()
            : response.data.toString();
        toastification.show(
          title: Text(
            'Gagal simpan Jenis',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          description: Text(errorMessage),
          type: ToastificationType.error,
        );
      }
    }, onError: (error) => defaultErrorResponse(error: error)).whenComplete(
        () => hideLoadingPopup());
  }

  static const _filterLabelStyle =
      TextStyle(fontSize: 14, fontWeight: FontWeight.bold);

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
                    style: _filterLabelStyle,
                  ),
                  border: OutlineInputBorder()),
            ),
            const SizedBox(
              height: 10,
            ),
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
                    style: _filterLabelStyle,
                  ),
                  border: OutlineInputBorder()),
            ),
            const SizedBox(
              height: 10,
            ),
            AsyncDropdown<ItemType>(
              label: const Text('Parent :', style: _filterLabelStyle),
              key: const ValueKey('itemTypeSelect'),
              textOnSearch: (ItemType itemType) => itemType.name,
              selected: itemType.parent,
              modelClass: ItemTypeClass(),
              attributeKey: 'jenis',
              path: '/item_types',
              onChanged: (value) => itemType.parent = value,
            ),
            const SizedBox(
              height: 15,
            ),
            ElevatedButton(onPressed: save, child: Text('Simpan'))
          ],
        ),
      ),
    );
  }
}
