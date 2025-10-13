import 'package:fe_pos/model/item_type.dart';
import 'package:fe_pos/page/item_type_form_page.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/platform_checker.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/widget/custom_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class ItemTypePage extends StatefulWidget {
  const ItemTypePage({super.key});

  @override
  State<ItemTypePage> createState() => _ItemTypePageState();
}

class _ItemTypePageState extends State<ItemTypePage>
    with DefaultResponse, PlatformChecker, LoadingPopup {
  late final Server server;
  String _searchText = '';
  final cancelToken = CancelToken();
  List<CustomTreeNode<ItemType>> tree = [];
  late Flash flash;
  late final Setting setting;
  late final TabManager tabManager;
  final _treeController = TreeController();
  static const minSearchLength = 2;
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

  void refreshTable() async {
    showLoadingPopup();
    await fetchItemTypes();
    hideLoadingPopup();
  }

  Future<DataTableResponse<ItemType>> fetchItemTypes(
      {int page = 1,
      int limit = 20,
      List<SortData> sorts = const [],
      Map filter = const {}}) {
    var sort = sorts.isEmpty ? null : sorts.first;
    Map<String, dynamic> param = {
      'search_text': _searchText,
      'sort': sort == null
          ? ''
          : sort.isAscending
              ? sort.key
              : "-${sort.key}",
    };
    filter.forEach((key, value) {
      param[key] = value;
    });
    tree = [];
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
            .map<ItemType>((json) => ItemTypeClass()
                .fromJson(json, included: responseBody['included'] ?? []))
            .toList();

        flash.hide();
        _treeController.collapseAll();
        setState(() {
          tree = convertToTree(models);
          if (_searchText.length >= minSearchLength) {
            filterTree(tree);
          }
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

  void _destroyItemType(ItemType itemType) {
    showConfirmDialog(
        message: 'Apakah anda yakin hapus ${itemType.name}?',
        onSubmit: () {
          server.delete('/item_types/${itemType.id}').then((response) {
            if (response.statusCode == 200) {
              flash.showBanner(
                messageType: ToastificationType.success,
                title: 'Sukses Hapus ${itemType.name}',
              );
              refreshTable();
            } else if (response.statusCode == 409) {
              flash.showBanner(
                  messageType: ToastificationType.error,
                  title: 'Gagal Hapus ${itemType.name}',
                  description: response.data['errors'].join(','));
            } else {
              flash.showBanner(
                  messageType: ToastificationType.error,
                  title: 'Gagal Hapus ${itemType.name}',
                  description: response.data.toString());
            }
          }, onError: (error) {
            defaultErrorResponse(error: error);
          });
        });
  }

  List<CustomTreeNode<ItemType>> convertToTree(List<ItemType> models,
      {dynamic parentId}) {
    return models
        .where((itemType) => itemType.parentId == parentId)
        .map((ItemType itemType) {
      final key = ObjectKey(itemType);
      return CustomTreeNode<ItemType>(
        key: key,
        object: itemType,
        content: Row(
          children: [
            Tooltip(message: itemType.description, child: Text(itemType.name)),
            const SizedBox(
              width: 15,
            ),
            IconButton(
                onPressed: () => _openForm(itemType), icon: Icon(Icons.edit)),
            const SizedBox(
              width: 10,
            ),
            IconButton(
                onPressed: () => _destroyItemType(itemType),
                icon: Icon(Icons.delete)),
          ],
        ),
        children: convertToTree(models, parentId: itemType.id),
      );
    }).toList();
  }

  void searchChanged(value) {
    setState(() {
      if (value.length >= minSearchLength) {
        _searchText = value;
        filterTree(tree);
      } else {
        for (CustomTreeNode node in tree) {
          node.displayAll();
        }
        _searchText = '';
      }
    });
  }

  bool filterTree(List<CustomTreeNode<ItemType>> treeNodes) {
    bool result = false;
    for (final treeNode in treeNodes) {
      bool isChildMatched = filterTree(treeNode.rawChildren ?? []);
      if (isChildMatched) {
        treeNode.isDisplay = true;
        _treeController.expandNode(treeNode.key!);
        result = true;
        continue;
      } else {
        _treeController.collapseNode(treeNode.key!);
      }
      ItemType? itemType = treeNode.object;
      if (itemType == null) {
        continue;
      }
      if (itemType.name.toLowerCase().contains(_searchText) ||
          itemType.description.toLowerCase().contains(_searchText)) {
        treeNode.displayAll();
        result = true;
      } else {
        treeNode.isDisplay = false;
      }
    }
    return result;
  }

  void _openForm(ItemType itemType) {
    final titleDesc = itemType.isNewRecord ? 'Buat' : 'Edit';
    if (isDesktop()) {
      tabManager.setSafeAreaContent(
        '$titleDesc Jenis ${itemType.name}',
        ItemTypeFormPage(
          itemType: itemType,
          key: ObjectKey(itemType),
        ),
        whenClose: () => refreshTable(),
      );
    } else {
      tabManager.addTab(
          '$titleDesc Jenis ${itemType.name}',
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton.filled(
                        onPressed: () => _openForm(ItemType(
                              parentId: null,
                            )),
                        icon: Icon(Icons.add)),
                  ),
                  Row(children: [
                    SizedBox(
                      width: 150,
                      child: TextField(
                        decoration:
                            const InputDecoration(hintText: 'Search Text'),
                        onChanged: searchChanged,
                        onSubmitted: searchChanged,
                      ),
                    ),
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
                  ]),
                ],
              ),
            ),
            const Divider(),
            SizedBox(
              height: 10,
            ),
            CustomTreeView(nodes: tree, treeController: _treeController),
          ],
        ),
      ),
    );
  }
}
