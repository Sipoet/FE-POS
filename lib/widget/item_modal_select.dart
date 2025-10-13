import 'package:fe_pos/model/item.dart';
import 'package:fe_pos/model/item_report.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ItemModalSelect extends StatefulWidget {
  final List<Item> initialValue;
  const ItemModalSelect({super.key, this.initialValue = const <Item>[]});

  @override
  State<ItemModalSelect> createState() => _ItemModalSelectState();
}

class _ItemModalSelectState extends State<ItemModalSelect>
    with DefaultResponse {
  List<Item> selectedItems = [];
  List<ItemReport> models = [];
  late final Server _server;
  late final List<TableColumn> _columns;
  late final PlutoGridStateManager _source;

  @override
  void initState() {
    selectedItems = widget.initialValue;
    _server = context.read<Server>();
    final setting = context.read<Setting>();
    _columns = setting.tableColumn('itemReport');

    super.initState();
  }

  Future<DataTableResponse<ItemReport>> fetchItem(
      {int page = 1,
      int limit = 20,
      List<SortData> sorts = const [],
      Map<String, dynamic> filter = const {}}) {
    _source.setShowLoading(true);
    Map<String, dynamic> param = {
      'page[page]': page.toString(),
      'page[limit]': limit.toString(),
      'report_type': 'json',
      'sort': sorts
          .map<String>((e) => e.isAscending ? e.key : "-${e.key}")
          .toList()
          .join(','),
      'include': 'item'
    };
    filter.forEach((key, value) {
      param[key] = value;
    });
    return _server.get('item_reports/', queryParam: param).then((response) {
      if (response.statusCode != 200) {
        return DataTableResponse<ItemReport>(models: [], totalPage: 0);
      }
      var data = response.data;

      models = data['data']
          .map<ItemReport>((row) =>
              ItemReportClass().fromJson(row, included: data['include'] ?? []))
          .toList();

      return DataTableResponse<ItemReport>(
          models: models.toList(), totalPage: data['meta']['total_pages']);
    }, onError: ((error, stackTrace) {
      defaultErrorResponse(error: error);
      return DataTableResponse<ItemReport>(models: [], totalPage: 0);
    })).whenComplete(() => _source.setShowLoading(false));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          child: CustomAsyncDataTable2<ItemReport>(
            showSummary: false,
            onRowChecked: (event) {
              if (event.isRow && event.isChecked == true) {
                final model = models[event.rowIdx ?? -1];
                selectedItems.add(model.item);
              }
            },
            fetchData: (request) {
              return fetchItem(
                  page: request.page,
                  sorts: request.sorts,
                  filter: request.filter);
            },
            primaryKey: 'item_code',
            showCheckboxColumn: true,
            columns: _columns,
            showFilter: true,
            onLoaded: (stateManager) {
              _source = stateManager;
              fetchItem();
            },
            fixedLeftColumns: 2,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        ElevatedButton(
            onPressed: () => Navigator.of(context).pop(selectedItems),
            child: const Text('Pilih')),
      ],
    );
  }
}
