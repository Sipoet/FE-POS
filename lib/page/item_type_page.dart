import 'package:fe_pos/model/item_type.dart';
import 'package:fe_pos/page/item_type_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class ItemTypePage extends StatefulWidget {
  const ItemTypePage({super.key});

  @override
  State<ItemTypePage> createState() => _ItemTypePageState();
}

class _ItemTypePageState extends State<ItemTypePage>
    with DefaultResponse, PlatformChecker {
  // late final PlutoGridStateManager _source;
  late final Server server;
  String _searchText = '';
  final cancelToken = CancelToken();
  List<TreeNode> tree = [];
  late Flash flash;
  late final Setting setting;
  late final TabManager tabManager;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    setting = context.read<Setting>();
    tabManager = context.read<TabManager>();
    Future.delayed(Duration.zero, fetchItemTypes);
    super.initState();
  }

  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  Future<void> refreshTable() async {
    fetchItemTypes();
    // _source.refreshTable();
  }

  Future<DataTableResponse<ItemType>> fetchItemTypes(
      {int page = 1,
      int limit = 20,
      List<SortData> sorts = const [],
      Map filter = const {}}) {
    var sort = sorts.isEmpty ? null : sorts.first;
    Map<String, dynamic> param = {
      'search_text': _searchText,
      // 'page[page]': page.toString(),
      // 'page[limit]': limit.toString(),
      'sort': sort == null
          ? ''
          : sort.isAscending
              ? sort.key
              : "-${sort.key}",
    };
    filter.forEach((key, value) {
      param[key] = value;
    });
    try {
      return server
          .get('item_types', queryParam: param, cancelToken: cancelToken)
          .then((response) {
        if (response.statusCode != 200) {
          throw 'error: ${response.data.toString()}';
        }
        Map responseBody = response.data;
        if (responseBody['data'] is! List) {
          throw 'error: invalid data type ${response.data.toString()}';
        }
        final models = responseBody['data']
            .map<ItemType>((json) => ItemType.fromJson(json,
                included: responseBody['included'] ?? []))
            .toList();

        flash.hide();
        setState(() {
          tree = convertToTree(models);
        });
        final totalPage = responseBody['meta']?['total_pages'] ?? 1;
        return DataTableResponse<ItemType>(
            models: models, totalPage: totalPage);
      },
              onError: (error, stackTrace) =>
                  defaultErrorResponse(error: error, valueWhenError: []));
    } catch (e, trace) {
      flash.showBanner(
          title: e.toString(),
          description: trace.toString(),
          messageType: ToastificationType.error);
      return Future(() => DataTableResponse<ItemType>(models: []));
    }
  }

  List<TreeNode> convertToTree(List<ItemType> models, {dynamic parentId}) {
    return models
        .where((itemType) => itemType.parentId == parentId)
        .map((ItemType itemType) => TreeNode(
              content: Row(
                children: [
                  Tooltip(
                      message: itemType.description,
                      child: Text(itemType.name)),
                  const SizedBox(
                    width: 15,
                  ),
                  IconButton(
                      onPressed: () => _openForm(itemType),
                      icon: Icon(Icons.edit)),
                  const SizedBox(
                    width: 10,
                  ),
                  IconButton(
                      onPressed: () =>
                          _openForm(ItemType(parentId: itemType.id)),
                      icon: Icon(Icons.add)),
                ],
              ),
              children: convertToTree(models, parentId: itemType.id),
            ))
        .toList();
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

  void _openForm(ItemType itemType) {
    final titleDesc = itemType.isNewRecord ? 'Buat' : 'Edit';
    if (isDesktop()) {
      tabManager.setSafeAreaContent(
        '$titleDesc Jenis',
        ItemTypeFormPage(
          itemType: itemType,
          key: ObjectKey(itemType),
        ),
        whenClose: () => refreshTable(),
      );
    } else {
      tabManager.addTab(
          '$titleDesc Jenis',
          ItemTypeFormPage(
            itemType: itemType,
            key: ObjectKey(itemType),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
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
                      decoration:
                          const InputDecoration(hintText: 'Search Text'),
                      onChanged: searchChanged,
                      onSubmitted: searchChanged,
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton.filled(
                  onPressed: () => _openForm(ItemType(
                        parentId: null,
                      )),
                  icon: Icon(Icons.add)),
            ),
            SizedBox(
              height: 10,
            ),
            TreeView(nodes: tree),
            // SizedBox(
            //   height: 100,
            //   child: CustomAsyncDataTable2<ItemType>(
            //     onLoaded: (stateManager) => _source = stateManager,
            //     columns: setting.tableColumn('ipos::ItemType'),
            //     fetchData: (request) => fetchItemTypes(
            //         page: request.page,
            //         filter: request.filter,
            //         sorts: request.sorts),
            //     fixedLeftColumns: 0,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
