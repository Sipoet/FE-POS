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
  late final TableController _source;
  late final Server server;
  List<Product> products = [];
  late final DefaultSetting defaultSetting;
  late Flash flash;
  late final List<TableColumn> columns;
  List<FilterData> _filter = [];

  @override
  void initState() {
    server = context.read<Server>();
    defaultSetting = context.read<DefaultSetting>();
    flash = Flash();
    final authorizer = context.read<Authorizer>();

    columns = authorizer.tableColumn('product');
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void openForm(Product product) {
    final tabManager = context.read<TabManager>();

    final desc = product.isNewRecord ? 'Tambah' : 'Edit';
    tabManager.addTab(
      '$desc Produk ${product.id ?? ''}',
      ProductFormPage(product: product),
    );
  }

  void refreshTable() {
    _source.refreshTable();
  }

  void deleteRecord(Product product) {
    showConfirmDialog(
      message: 'Apakah Yakin Hapus Produk ${product.supplierProductCode}',
      onSubmit: () {
        product.destroy(server).then((result) {
          if (result) {
            flash.show(
              Text('Sukses hapus ${product.supplierProductCode}'),
              .success,
            );
            refreshTable();
          } else {
            flash.show(
              Text('Gagal hapus ${product.supplierProductCode}'),
              .error,
            );
          }
        });
      },
    );
  }

  Future<DataTableResponse<Product>> fetchData(QueryRequest request) {
    _source.setShowLoading(true);
    request.include = [
      'product_category',
      'supplier',
      'brand',
      'base_uom',
      'stock_account',
    ];
    request.filters.addAll(_filter);

    return ProductClass()
        .finds(server, request)
        .then(
          (response) {
            return DataTableResponse<Product>(
              totalPage: response.metadata['total_pages'],
              models: response.models,
            );
          },
          onError: (error, stackTrace) {
            defaultErrorResponse(error: error);
            return DataTableResponse<Product>(totalPage: 1, models: []);
          },
        )
        .whenComplete(() => _source.setShowLoading(false));
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
          SizedBox(
            height: bodyScreenHeight,
            child: CustomAsyncDataTable<Product>(
              additionalHeaderActions: (menuController) => [
                MenuItemButton(
                  onPressed: () {
                    menuController.close();
                    final product = ProductClass().initModel();
                    product.baseUom = defaultSetting.uom;
                    product.stockAccount = defaultSetting.stockAccount;
                    openForm(product);
                  },
                  child: Text('Tambah Produk'),
                ),
              ],
              rowAction: (model) => Row(
                children: [
                  IconButton(
                    onPressed: () => openForm(model),
                    icon: Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: () => deleteRecord(model),
                    icon: Icon(Icons.delete),
                  ),
                ],
              ),
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
