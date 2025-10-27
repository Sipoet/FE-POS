import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/widget/table_filter_form.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/page/product_form_page.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/model/product.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> with DefaultResponse {
  late final PlutoGridStateManager _source;
  late final Server server;
  String _searchText = '';
  List<Product> products = [];
  final cancelToken = CancelToken();
  late Flash flash;
  late final List<TableColumn> columns;
  List<FilterData> _filter = [];
  final _menuController = MenuController();

  @override
  void initState() {
    server = context.read<Server>();
    flash = Flash();
    final setting = context.read<Setting>();
    final actionColumn = TableColumn(
      clientWidth: 100,
      name: 'action',
      type: TableColumnType.action,
      humanizeName: 'Action',
      frozen: PlutoColumnFrozen.end,
      renderBody: (rendererContext) {
        return Row(
          children: [
            IconButton(
              onPressed: () => _openEditForm(rendererContext.rowIdx),
              icon: Icon(Icons.edit),
            )
          ],
        );
      },
    );
    columns = setting.tableColumn('product')..add(actionColumn);
    super.initState();
  }

  @override
  void dispose() {
    cancelToken.cancel();
    super.dispose();
  }

  void openForm(Product product) {
    final tabManager = context.read<TabManager>();

    final desc = product.isNewRecord ? 'Tambah' : 'Edit';
    tabManager.addTab(
        '$desc Produk ${product.id ?? ''}', ProductFormPage(product: product));
  }

  void _openEditForm(int index) {
    final product = products[index];
    openForm(product);
  }

  void refreshTable() {
    _source.refreshTable();
  }

  Future<DataTableResponse<Product>> fetchData(QueryRequest request) {
    _source.setShowLoading(true);
    request.searchText = _searchText;
    request.cancelToken = cancelToken;
    request.filters.addAll(_filter);

    return ProductClass().finds(server, request).then((response) {
      return DataTableResponse<Product>(
          totalPage: response.metadata['total_pages'], models: response.models);
    }, onError: (error, stackTrace) {
      defaultErrorResponse(error: error);
      return DataTableResponse<Product>(totalPage: 1, models: []);
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
    return VerticalBodyScroll(
      child: Column(
        children: [
          TableFilterForm(
            columns: columns,
            onSubmit: (filter) {
              _filter = filter;
              _source.refreshTable();
            },
          ),
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
                SizedBox(
                  width: 50,
                  child: SubmenuButton(
                      controller: _menuController,
                      menuChildren: [
                        MenuItemButton(
                          child: const Text('Tambah Produk'),
                          onPressed: () {
                            _menuController.close();
                            openForm(Product());
                          },
                        ),
                      ],
                      child: const Icon(Icons.table_rows_rounded)),
                )
              ],
            ),
          ),
          SizedBox(
            height: bodyScreenHeight,
            child: CustomAsyncDataTable2<Product>(
              onLoaded: (stateManager) => _source = stateManager,
              showFilter: false,
              showSummary: false,
              fixedLeftColumns: 1,
              fetchData: fetchData,
              columns: columns,
            ),
          ),
        ],
      ),
    );
  }
}
