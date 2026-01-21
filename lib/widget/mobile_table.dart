import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/table_decorator.dart';
import 'package:fe_pos/tool/text_formatter.dart';
import 'package:fe_pos/widget/model_card.dart';
import 'package:fe_pos/widget/pagination_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MobileTable<T extends Model> extends StatefulWidget {
  final FutureOr<DataTableResponse<T>> Function(QueryRequest)? fetchData;
  final Widget Function(T model)? renderAction;
  final List<TableColumn> columns;
  final List<T>? rows;
  final void Function(QueryRequest queryRequest)? onQueryChanged;
  const MobileTable({
    super.key,
    required this.columns,
    this.fetchData,
    required this.renderAction,
    this.onQueryChanged,
    this.rows,
  });

  @override
  State<MobileTable<T>> createState() => _MobileTableState<T>();
}

class _MobileTableState<T extends Model> extends State<MobileTable<T>>
    with TextFormatter, LoadingPopup {
  final QueryNotifier queryRequest = QueryNotifier(QueryRequest(limit: 20));
  DataTableResponse<T>? queryResponse;
  late final TabManager tabManager;
  final pageController = TextEditingController();
  final scrollController = ScrollController();
  @override
  void initState() {
    tabManager = context.read<TabManager>();
    Future.delayed(Duration.zero, refreshTable);
    queryRequest.addListener(() {
      if (widget.onQueryChanged != null) {
        widget.onQueryChanged!(queryRequest.value);
      }
    });
    super.initState();
  }

  List<T> paginatedRows() {
    final page = queryRequest.value.page;
    final limit = queryRequest.value.limit ?? 20;
    int start = (page - 1) * limit;
    int end = [page * limit, widget.rows!.length].min;
    return widget.rows!.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final models = widget.fetchData == null
        ? paginatedRows()
        : queryResponse?.models ?? [];
    return Column(
      children: [
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Flexible(
              child: TextField(
                onSubmitted: (value) {
                  queryRequest.value.searchText = value;
                  queryRequest.notify();
                  refreshTable();
                },
                onChanged: (value) {
                  if (value.isEmpty) {
                    queryRequest.value.searchText = null;
                    queryRequest.notify();
                    refreshTable();
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
                color: queryRequest.value.sorts.isNotEmpty
                    ? Colors.green
                    : null,
              ),
            ),
            IconButton(onPressed: refreshTable, icon: Icon(Icons.refresh)),
          ],
        ),
        const SizedBox(height: 10),
        Visibility(
          visible: models.isEmpty,
          child: Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Text('Data tidak ditemukan'),
          ),
        ),
        Expanded(
          child: ListView(
            controller: scrollController,
            children: models
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
          visible: models.isNotEmpty,
          child: PaginationWidget(
            totalPage: queryResponse?.totalPage ?? 1,
            initialPage: queryRequest.value.page,
            onPageChanged: (page) {
              queryRequest.value.page = page;
              fetchModels();
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
        for (final sort in queryRequest.value.sorts) {
          sorts[sort.key] = sort;
        }
        String searchSortText = '';
        return StatefulBuilder(
          builder: (BuildContext context, setstateDialog) => AlertDialog(
            title: const Text("Urutkan Berdasarkan:"),
            content: SizedBox(
              height: 460,
              child: Column(
                spacing: 15,
                children: [
                  TextField(
                    decoration: InputDecoration(hintText: 'Cari'),
                    onChanged: (val) => setstateDialog(() {
                      searchSortText = val;
                    }),
                  ),
                  SizedBox(
                    height: 200,
                    width: 300,
                    child: ListView(
                      children: widget.columns
                          .where(
                            (column) =>
                                column.canSort && searchSortText.isEmpty ||
                                column.humanizeName.insensitiveContains(
                                  searchSortText,
                                ),
                          )
                          .map<Widget>((column) {
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisSize: .min,
                                  crossAxisAlignment: .start,
                                  mainAxisAlignment: .spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        column.humanizeName,
                                        overflow: .fade,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setstateDialog(() {
                                          if (sorts[column.name] == null) {
                                            sorts[column.name] = SortData(
                                              key: column.name,
                                              isAscending: true,
                                            );
                                          } else if (sorts[column.name]!
                                              .isAscending) {
                                            sorts[column.name] = SortData(
                                              key: column.name,
                                              isAscending: false,
                                            );
                                          } else {
                                            sorts.remove(column.name);
                                          }
                                        });
                                      },
                                      icon: sorts[column.name] == null
                                          ? Icon(Icons.unfold_more)
                                          : sorts[column.name]!.isAscending
                                          ? Icon(
                                              Icons.arrow_drop_up,
                                              color: Colors.green,
                                            )
                                          : Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.green,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton(
                        child: const Text("Submit"),
                        onPressed: () {
                          queryRequest.value.sorts = sorts.values.toList();
                          queryRequest.notify();
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((result) {
      if (result == true) refreshTable();
    });
  }

  void refreshTable() {
    queryRequest.value.page = 1;
    fetchModels();
  }

  void fetchModels() async {
    debugPrint(
      "fetch search text ${queryRequest.value.searchText} page ${queryRequest.value.page} limit ${queryRequest.value.limit}",
    );
    if (widget.fetchData == null) {
      return;
    }
    showLoadingPopup();

    pageController.setValue(queryRequest.value.page);

    final response = await widget.fetchData!(queryRequest.value);
    debugPrint(
      'masuk response  search ${queryRequest.value.searchText} response ${queryResponse?.models.length}',
    );
    setState(() {
      if (queryResponse != null) {
        queryResponse!.models = response.models;
        queryResponse!.totalPage = response.totalPage;
      } else {
        queryResponse = response;
      }
      scrollController.jumpTo(0);
    });

    hideLoadingPopup();
  }
}

class QueryNotifier extends ChangeNotifier {
  QueryRequest _value;

  QueryNotifier(this._value);
  set value(QueryRequest val) {
    _value = val;
    notifyListeners();
  }

  QueryRequest get value => _value;

  void notify() {
    notifyListeners();
  }
}
