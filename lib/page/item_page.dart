import 'package:fe_pos/model/item.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
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
  late final PlutoGridStateManager _source;
  late final Server server;
  String _searchText = '';
  List<Item> items = [];
  final cancelToken = CancelToken();
  late Flash flash;
  late final Setting setting;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    setting = context.read<Setting>();

    super.initState();
  }

  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  Future<DataTableResponse<Item>> fetchItems(
      {int page = 1,
      int limit = 20,
      List<SortData> sorts = const [],
      Map filter = const {}}) {
    var sort = sorts.isEmpty ? null : sorts.first;
    Map<String, dynamic> param = {
      'search_text': _searchText,
      'page[page]': page.toString(),
      'page[limit]': limit.toString(),
      'include': 'supplier,brand,item_type',
      'sort': sort == null
          ? ''
          : sort.isAscending
              ? sort.key
              : "-${sort.key}",
    };
    filter.forEach((key, value) {
      param[key] = value;
    });

    return server
        .get('items', queryParam: param, cancelToken: cancelToken)
        .then((response) {
      if (response.statusCode != 200) {
        throw 'error: ${response.data.toString()}';
      }
      Map responseBody = response.data;
      if (responseBody['data'] is! List) {
        throw 'error: invalid data type ${response.data.toString()}';
      }
      final models = responseBody['data']
          .map<Item>((json) =>
              Item.fromJson(json, included: responseBody['included'] ?? []))
          .toList();
      final totalPage = responseBody['meta']?['total_pages'] ?? 1;
      return DataTableResponse<Item>(totalPage: totalPage, models: models);
    },
            onError: (error, stackTrace) =>
                defaultErrorResponse(error: error, valueWhenError: []));
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
            height: 600,
            child: CustomAsyncDataTable2<Item>(
              onLoaded: (stateManager) => _source = stateManager,
              fixedLeftColumns: 1,
              fetchData: (request) => fetchItems(
                page: request.page,
                sorts: request.sorts,
                filter: request.filter,
              ),
              columns: setting.tableColumn('ipos::Item'),
            ),
          ),
        ],
      ),
    );
  }
}
