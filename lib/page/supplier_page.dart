import 'package:fe_pos/model/supplier.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});

  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> with DefaultResponse {
  late final PlutoGridStateManager _source;
  late final Server server;
  String _searchText = '';
  final cancelToken = CancelToken();
  late Flash flash;
  late final Setting setting;

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    setting = context.read<Setting>();
    super.initState();
    Future.delayed(Duration.zero, refreshTable);
  }

  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  Future<void> refreshTable() async {
    _source.refreshTable();
  }

  Future<DataTableResponse<Supplier>> fetchSuppliers(QueryRequest request) {
    _source.setShowLoading(true);
    request.searchText = _searchText;
    request.cancelToken = cancelToken;

    return SupplierClass().finds(server, request).then((response) {
      return DataTableResponse<Supplier>(
          models: response.models,
          totalPage: response.metadata['total_pages'] ?? 1);
    }, onError: (error, stackTrace) {
      defaultErrorResponse(error: error, valueWhenError: []);
      return DataTableResponse<Supplier>(models: []);
    }).whenComplete(() => _source.setShowLoading(false));
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
            SizedBox(
              height: bodyScreenHeight,
              child: CustomAsyncDataTable2<Supplier>(
                onLoaded: (stateManager) => _source = stateManager,
                fixedLeftColumns: 0,
                fetchData: (request) => fetchSuppliers(request),
                columns: setting.tableColumn('ipos::Supplier'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
