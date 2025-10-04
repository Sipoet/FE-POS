import 'package:fe_pos/model/item_type.dart';
import 'package:fe_pos/page/item_type_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class ItemTypePage extends StatefulWidget {
  const ItemTypePage({super.key});

  @override
  State<ItemTypePage> createState() => _ItemTypePageState();
}

class _ItemTypePageState extends State<ItemTypePage>
    with DefaultResponse, PlatformChecker {
  late final PlutoGridStateManager _source;
  late final Server server;
  String _searchText = '';
  final cancelToken = CancelToken();
  List<TreeSliverNode<ItemType>> tree = [];
  late Flash flash;
  late final Setting setting;
  late final TabManager tabManager;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    setting = context.read<Setting>();
    tabManager = context.read<TabManager>();
    Future.delayed(Duration.zero, refreshTable);
    super.initState();
  }

  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  Future<void> refreshTable() async {
    _source.refreshTable();
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

  List<TreeSliverNode<ItemType>> convertToTree(List<ItemType> models,
      {dynamic parentId}) {
    return models
        .where((itemType) => itemType.parentId == parentId)
        .map((ItemType itemType) => TreeSliverNode<ItemType>(
              itemType,
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

  Widget treeNodes() {
    return DecoratedSliver(
      decoration: BoxDecoration(border: Border.all()),
      sliver: TreeSliver<ItemType>(
        tree: tree,
        onNodeToggle: (TreeSliverNode<Object?> node) {
          // setState(() {
          //   _selectedNode = node as TreeSliverNode<String>;
          // });
        },
        treeNodeBuilder: _treeNodeBuilder,
        treeRowExtentBuilder: (TreeSliverNode<Object?> node,
            SliverLayoutDimensions layoutDimensions) {
          // This gives more space to parent nodes.
          return node.children.isNotEmpty ? 60.0 : 50.0;
        },
        // No internal indentation, the custom treeNodeBuilder applies its
        // own indentation to decorate in the indented space.
        indentation: TreeSliverIndentationType.none,
      ),
    );
  }

  Widget _treeNodeBuilder(
    BuildContext context,
    TreeSliverNode<Object?> node,
    AnimationStyle toggleAnimationStyle,
  ) {
    final bool isParentNode = node.children.isNotEmpty;
    final BorderSide border = BorderSide(width: 2, color: Colors.purple[300]!);
    ItemType itemType = node.content as ItemType;

    return TreeSliver.wrapChildToToggleNode(
      node: node,
      child: Row(
        children: <Widget>[
          // Custom indentation
          SizedBox(width: 10.0 * node.depth! + 8.0),
          DecoratedBox(
            decoration: BoxDecoration(
              border: node.parent != null
                  ? Border(left: border, bottom: border)
                  : null,
            ),
            child: const SizedBox(height: 50.0, width: 20.0),
          ),
          // Leading icon for parent nodes
          if (isParentNode)
            DecoratedBox(
              decoration: BoxDecoration(border: Border.all()),
              child: SizedBox.square(
                dimension: 20.0,
                child:
                    Icon(node.isExpanded ? Icons.remove : Icons.add, size: 14),
              ),
            ),
          // Spacer
          const SizedBox(width: 8.0),
          // Content
          Text(itemType.name),
          const SizedBox(width: 8.0),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _openForm(itemType),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _openForm(ItemType(
              parentId: itemType.id,
            )),
          ),
        ],
      ),
    );
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
    return Padding(
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
                    decoration: const InputDecoration(hintText: 'Search Text'),
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
          Expanded(
            child: CustomScrollView(
              slivers: [treeNodes()],
            ),
          ),
          SizedBox(
            height: 100,
            child: CustomAsyncDataTable2<ItemType>(
              onLoaded: (stateManager) => _source = stateManager,
              columns: setting.tableColumn('ipos::ItemType'),
              fetchData: (request) => fetchItemTypes(
                  page: request.page,
                  filter: request.filter,
                  sorts: request.sorts),
              fixedLeftColumns: 0,
            ),
          ),
        ],
      ),
    );
  }
}
