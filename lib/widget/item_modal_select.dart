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
  late final TableController<ItemReport> _source;

  @override
  void initState() {
    selectedItems = widget.initialValue;
    _server = context.read<Server>();
    final setting = context.read<Setting>();
    _columns = setting.tableColumn('itemReport');

    super.initState();
  }

  Future<DataTableResponse<ItemReport>> fetchItem(QueryRequest request) {
    _source.setShowLoading(true);
    return ItemReportClass()
        .finds(_server, request)
        .then(
          (result) {
            return DataTableResponse<ItemReport>(
              models: result.models,
              totalPage: result.metadata['total_pages'],
            );
          },
          onError: ((error, stackTrace) {
            defaultErrorResponse(error: error);
            return DataTableResponse<ItemReport>(models: [], totalPage: 0);
          }),
        )
        .whenComplete(() => _source.setShowLoading(false));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          child: CustomAsyncDataTable<ItemReport>(
            showSummary: false,
            onRowChecked: (event) {
              if (event.isRow && event.isChecked == true) {
                final model = models[event.rowIdx ?? -1];
                selectedItems.add(model.item);
              }
            },
            fetchData: fetchItem,
            primaryKey: 'item_code',
            showCheckboxColumn: true,
            columns: _columns,
            showFilter: true,
            onLoaded: (stateManager) {
              _source = stateManager;
            },
            fixedLeftColumns: 2,
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(selectedItems),
          child: const Text('Pilih'),
        ),
      ],
    );
  }
}
