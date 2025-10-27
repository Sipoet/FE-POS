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
import 'package:fe_pos/model/server.dart';

class ItemPage extends StatefulWidget {
  const ItemPage({super.key});

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> with DefaultResponse {
  late final PlutoGridStateManager _source;
  late final Server server;
  String _searchText = '';
  List<Item> items = [];
  CancelToken cancelToken = CancelToken();
  late Flash flash;
  late final List<TableColumn> columns;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    final setting = context.read<Setting>();

    final actionColumn = TableColumn(
      clientWidth: 100,
      name: 'action',
      type: TableColumnType.action,
      humanizeName: 'Action',
      frozen: PlutoColumnFrozen.end,
      renderBody: (rendererContext) {
        return Row(
          children: [
            IconButton(
              onPressed: () => _openEditForm(rendererContext.rowIdx),
              icon: Icon(Icons.edit),
            )
          ],
        );
      },
    );
    columns = setting.tableColumn('ipos::Item')..add(actionColumn);
    super.initState();
  }

  void _openEditForm(int index) {
    final item = items[index];
    final tabManager = context.read<TabManager>();
    tabManager.addTab('Edit item ${item.code}', ItemFormPage(item: item));
  }

  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  Future<DataTableResponse<Item>> fetchItems(request) {
    request.searchText = _searchText;
    request.cancelToken = cancelToken;
    request.include = ['supplier', 'brand', 'item_type'];

    return ItemClass().finds(server, request).then((response) {
      return DataTableResponse<Item>(
          totalPage: response.metadata['total_pages'] ?? 1,
          models: response.models);
    }, onError: (error, stackTrace) {
      defaultErrorResponse(error: error, valueWhenError: []);
      return DataTableResponse<Item>(models: [], totalPage: 1);
    });
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
      cancelToken.cancel();
      cancelToken = CancelToken();
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
            child: CustomAsyncDataTable2<Item>(
              onLoaded: (stateManager) => _source = stateManager,
              fixedLeftColumns: 1,
              fetchData: (request) => fetchItems(request),
              columns: columns,
            ),
          ),
        ],
      ),
    );
  }
}
