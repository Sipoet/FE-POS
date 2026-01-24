import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/table_decorator.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/model_card.dart';
import 'package:fe_pos/widget/pagination_widget.dart';
import 'package:fe_pos/widget/sync_data_table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MobileTable<T extends Model> extends StatefulWidget {
  final Widget Function(T model)? renderAction;
  final List<TableColumn> columns;
  // final void Function() onChanged;
  final MobileTableController<T> controller;
  final List<T>? rows;
  const MobileTable({
    super.key,
    required this.columns,
    required this.controller,
    required this.renderAction,
    this.rows,
  });

  @override
  State<MobileTable<T>> createState() => _MobileTableState<T>();
}

class _MobileTableState<T extends Model> extends State<MobileTable<T>>
    with TextFormatter, LoadingPopup {
  DataTableResponse<T>? queryResponse;
  late final TabManager tabManager;
  final pageController = TextEditingController();
  final scrollController = ScrollController();
  MobileTableController<T> get controller => widget.controller;
  @override
  void initState() {
    tabManager = context.read<TabManager>();

    Future.delayed(Duration.zero, refreshTable);
    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    controller.loader.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Flexible(
              child: TextFormField(
                onFieldSubmitted: (value) {
                  controller.searchText = value;
                  debugPrint('search change');
                  controller.notifyChanged();
                },
                initialValue: controller.searchText,
                onChanged: (value) {
                  if (value.isEmpty) {
                    controller.searchText = '';
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            IconButton(
              onPressed: openSortDialog,
              icon: Icon(
                Icons.sort_outlined,
                color: controller.sorts.isNotEmpty ? Colors.green : null,
              ),
            ),
            IconButton(onPressed: refreshTable, icon: Icon(Icons.refresh)),
          ],
        ),
        const SizedBox(height: 10),
        Visibility(
          visible: controller.models.isEmpty && !controller.loader.value,
          child: Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Text('Data tidak ditemukan'),
          ),
        ),
        Visibility(
          visible: controller.loader.value,
          child: Padding(
            padding: const EdgeInsets.only(top: 50),
            child: loadingWidget(),
          ),
        ),
        Expanded(
          child: ListView(
            controller: scrollController,
            children: controller.models
                .map<Widget>(
                  (model) => ModelCard(
                    model: model,
                    columns: widget.columns,
                    tabManager: tabManager,
                    action: widget.renderAction == null
                        ? null
                        : widget.renderAction!(model),
                  ),
                )
                .toList(),
          ),
        ),
        SizedBox(height: 10),
        Visibility(
          visible: controller.models.isNotEmpty,
          child: PaginationWidget(
            totalPage: controller.totalPage,
            initialPage: controller.currentPage,
            onPageChanged: (page) {
              controller.currentPage = page;
              controller.notifyChanged();
            },
          ),
        ),
      ],
    );
  }

  void openSortDialog() {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final navigator = Navigator.of(context);
        Map<String, SortData> sorts = {};
        for (final sort in controller.sorts) {
          sorts[sort.key] = sort;
        }
        String searchSortText = '';
        final columns = widget.columns
            .where(
              (column) =>
                  column.canSort && searchSortText.isEmpty ||
                  column.humanizeName.insensitiveContains(searchSortText),
            )
            .toList();
        return StatefulBuilder(
          builder: (BuildContext context, setstateDialog) => AlertDialog(
            title: const Text("Urutkan Berdasarkan:"),
            content: SizedBox(
              width: 350,
              height: 400,
              child: Column(
                spacing: 15,
                mainAxisSize: .min,
                children: [
                  TextField(
                    decoration: InputDecoration(hintText: 'Cari'),
                    onChanged: (val) => setstateDialog(() {
                      searchSortText = val;
                    }),
                  ),
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      primary: true,
                      itemCount: columns.length,
                      separatorBuilder: (context, index) => SizedBox(height: 3),
                      itemBuilder: (context, index) {
                        final column = columns[index];
                        return Card(
                          borderOnForeground: false,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1, color: Colors.grey),
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                          ),
                          child: ListTile(
                            dense: true,
                            subtitle: Text(
                              column.humanizeName,
                              overflow: .fade,
                              style: TextStyle(fontSize: 16),
                            ),
                            onTap: () {
                              setstateDialog(() {
                                if (sorts[column.name] == null) {
                                  sorts[column.name] = SortData(
                                    key: column.name,
                                    isAscending: true,
                                  );
                                } else if (sorts[column.name]!.isAscending) {
                                  sorts[column.name] = SortData(
                                    key: column.name,
                                    isAscending: false,
                                  );
                                } else {
                                  sorts.remove(column.name);
                                }
                              });
                            },
                            trailing: sorts[column.name] == null
                                ? Icon(Icons.unfold_more)
                                : sorts[column.name]!.isAscending
                                ? Icon(Icons.arrow_drop_up, color: Colors.green)
                                : Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.green,
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            actions: [
              ElevatedButton(
                child: const Text("Submit"),
                onPressed: () {
                  controller.sorts = sorts.values.toList();
                  navigator.pop(true);
                },
              ),
              ElevatedButton(
                child: const Text("Reset"),
                onPressed: () {
                  setstateDialog(() {
                    sorts.clear();
                  });
                },
              ),
              ElevatedButton(
                child: const Text("Kembali"),
                onPressed: () {
                  navigator.pop(false);
                },
              ),
            ],
            elevation: 5,
            actionsAlignment: .spaceAround,
            actionsPadding: EdgeInsets.only(bottom: 20, left: 10, right: 10),
            actionsOverflowAlignment: .end,
            actionsOverflowButtonSpacing: 5,
            actionsOverflowDirection: .down,
          ),
        );
      },
    ).then((result) {
      if (result == true) refreshTable();
    });
  }

  void refreshTable() {
    setState(() {
      controller.currentPage = 1;
      controller.notifyChanged(force: true);
    });
  }
}

final listFormula = ListEquality();

extension ListEqual on List {
  bool equal(List a) {
    return listFormula.equals(this, a);
  }
}

class MobileTableController<T extends Model> extends ChangeNotifier {
  int _currentPage;
  int _totalPage;
  List<T> _models;
  String _searchText;

  ValueNotifier<bool> loader = ValueNotifier<bool>(false);
  List<SortData> _sorts;
  bool _isValueChanged = false;
  MobileTableController({
    int currentPage = 1,
    int totalPage = 1,
    String searchText = '',
    List<T>? models,
    List<SortData>? sorts,
  }) : _models = models ?? [],
       _sorts = sorts ?? [],
       _currentPage = currentPage,
       _totalPage = totalPage,
       _searchText = searchText;

  set currentPage(int value) {
    if (_currentPage != value) {
      _currentPage = value;
      _isValueChanged = true;
    }
  }

  set totalPage(int value) {
    if (_totalPage != value) {
      _totalPage = value;
      _isValueChanged = true;
    }
  }

  set sorts(List<SortData> value) {
    if (!_sorts.equals(value)) {
      debugPrint(
        '_sorts change from ${_sorts.map<String>((e) => e.toString()).join(',')} to ${value.map<String>((e) => e.toString()).join(',')}',
      );
      _sorts = value;
      _isValueChanged = true;
    }
  }

  set models(List<T> value) {
    if (!(_models
        .map<String>((e) => e.modelValue)
        .toList()
        .equals(value.map<String>((e) => e.modelValue).toList()))) {
      debugPrint('_models change from ${models.length} to ${value.length}');
      _models = value;
      _isValueChanged = true;
    }
  }

  void showLoading() {
    loader.value = true;
  }

  void hideLoading() {
    loader.value = false;
  }

  set searchText(String value) {
    if (_searchText != value) {
      _searchText = value;
      _isValueChanged = true;
    }
  }

  int get currentPage => _currentPage;
  int get totalPage => _totalPage;
  List<T> get models => _models;
  String get searchText => _searchText;

  List<SortData> get sorts => _sorts;

  void notifyChanged({bool force = false}) {
    if (_isValueChanged) {
      _isValueChanged = false;
      debugPrint('notify pressed');
      notifyListeners();
    } else if (force) {
      notifyListeners();
    }
  }
}
