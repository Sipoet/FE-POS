import 'package:fe_pos/model/item.dart';
import 'package:fe_pos/page/item_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';

import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class ItemPage extends StatefulWidget {
  const ItemPage({super.key});

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> with DefaultResponse {
  late final TrinaGridStateManager _source;
  late final Server server;
  String _searchText = '';
  List<Item> items = [];
  final cancelToken = CancelToken();
  late final Flash flash;
  late final List<TableColumn> columns;
  late final Setting setting;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    setting = context.read<Setting>();

    columns = setting.tableColumn('ipos::Item');
    super.initState();
  }

  void _openEditForm(Item item) {
    final tabManager = context.read<TabManager>();
    tabManager.addTab('Edit item ${item.code}', ItemFormPage(item: item));
  }

  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  Future<DataTableResponse<Item>> fetchItems(QueryRequest request) {
    request.include.addAll(['supplier', 'brand', 'item_type']);
    request.searchText = _searchText;
    return ItemClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<Item>(
            models: value.models,
            totalPage: value.metadata['total_pages'],
          ),
          onError: (error) {
            defaultErrorResponse(error: error);
            return DataTableResponse.empty();
          },
        );
  }

  void searchChanged(value) {
    String container = _searchText;
    setState(() {
      if (value.length >= 3) {
        _searchText = value;
      } else {
        _searchText = '';
      }
    });
    if (container != _searchText) {
      refreshTable();
    }
  }

  void refreshTable() {
    _source.refreshTable();
  }

  @override
  Widget build(BuildContext context) {
    return VerticalBodyScroll(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _searchText = '';
                    });
                    refreshTable();
                  },
                  tooltip: 'Reset Table',
                  icon: const Icon(Icons.refresh),
                ),
                SizedBox(
                  width: 150,
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'Search Text'),
                    onChanged: searchChanged,
                    onSubmitted: searchChanged,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: bodyScreenHeight,
            child: CustomAsyncDataTable<Item>(
              renderAction: (model) => Row(
                children: [
                  if (setting.isAuthorize('item', 'update'))
                    IconButton(
                      onPressed: () => _openEditForm(model),
                      icon: Icon(Icons.edit),
                    ),
                ],
              ),
              onLoaded: (stateManager) => _source = stateManager,
              fixedLeftColumns: 1,
              fetchData: fetchItems,
              columns: columns,
              showFilter: true,
            ),
          ),
        ],
      ),
    );
  }
}
