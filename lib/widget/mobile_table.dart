import 'dart:async';

import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/tool/table_decorator.dart';
import 'package:fe_pos/widget/model_card.dart';
import 'package:fe_pos/widget/pagination_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MobileTable<T extends Model> extends StatefulWidget {
  final FutureOr<DataTableResponse<T>> Function(QueryRequest) fetchData;
  final Widget Function(T model)? renderAction;
  final List<TableColumn> columns;
  const MobileTable({
    super.key,
    required this.columns,
    required this.fetchData,
    required this.renderAction,
  });

  @override
  State<MobileTable<T>> createState() => _MobileTableState<T>();
}

class _MobileTableState<T extends Model> extends State<MobileTable<T>>
    with DefaultResponse, LoadingPopup {
  QueryRequest queryRequest = QueryRequest();
  DataTableResponse<T>? queryResponse;
  late final TabManager tabManager;
  final pageController = TextEditingController();
  final scrollController = ScrollController();
  @override
  void initState() {
    tabManager = context.read<TabManager>();
    Future.delayed(Duration.zero, refreshTable);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final models = queryResponse?.models ?? [];
    return Column(
      children: [
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Flexible(
              child: TextField(
                onSubmitted: (value) {
                  debugPrint('==submit search $value');
                  queryRequest.searchText = value;
                  refreshTable();
                },
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            IconButton(onPressed: refreshTable, icon: Icon(Icons.refresh)),
          ],
        ),
        const SizedBox(height: 10),
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
        PaginationWidget(
          totalPage: queryResponse?.totalPage ?? 1,
          initialPage: queryRequest.page,
          onPageChanged: (page) {
            queryRequest.page = page;
            fetchModels();
          },
        ),
      ],
    );
  }

  void refreshTable() {
    queryRequest.page = 1;
    fetchModels();
  }

  void fetchModels() async {
    debugPrint(
      "fetch search text ${queryRequest.searchText} page ${queryRequest.page} limit ${queryRequest.limit}",
    );
    showLoadingPopup();

    pageController.setValue(queryRequest.page);

    final response = await widget.fetchData(queryRequest);
    debugPrint(
      'masuk response  search ${queryRequest.searchText} response ${queryResponse?.models.length}',
    );
    setState(() {
      if (queryResponse != null) {
        queryResponse?.models = response.models;
        queryResponse?.totalPage = response.totalPage;
      } else {
        queryResponse = response;
      }
      scrollController.jumpTo(0);
    });

    hideLoadingPopup();
  }
}
