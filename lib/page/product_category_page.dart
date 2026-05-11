import 'package:fe_pos/model/product_category.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/flash.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/custom_async_data_table.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/model/session_state.dart';
import 'package:fe_pos/page/product_category_form_page.dart';

class ProductCategoryPage extends StatefulWidget {
  const ProductCategoryPage({super.key});

  @override
  State<ProductCategoryPage> createState() => _ProductCategoryPageState();
}

class _ProductCategoryPageState extends State<ProductCategoryPage>
    with DefaultResponse {
  late final TableController _source;
  late final Server server;
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
    super.dispose();
  }

  Future<void> refreshTable() async {
    _source.refreshTable();
  }

  Future<DataTableResponse<ProductCategory>> fetchProductCategorys(
    QueryRequest request,
  ) {
    return ProductCategoryClass()
        .finds(server, request)
        .then(
          (value) => DataTableResponse<ProductCategory>(
            models: value.models,
            totalPage: value.metadata['total_pages'],
          ),
          onError: (error) {
            defaultErrorResponse(error: error);
            return DataTableResponse.empty();
          },
        );
  }

  void openForm(ProductCategory productCategory) {
    final tabManager = context.read<TabManager>();

    final desc = productCategory.isNewRecord ? 'Tambah' : 'Edit';
    tabManager.addTab(
      '$desc Kategori Produk ${productCategory.name}',
      ProductCategoryFormPage(productCategory: productCategory),
    );
  }

  void deleteRecord(ProductCategory supplier) {
    showConfirmDialog(
      message: 'Apakah Yakin Hapus Kategori Produk ${supplier.name}',
      onSubmit: () {
        supplier.destroy(server).then((result) {
          if (result) {
            flash.show(Text('Sukses hapus ${supplier.name}'), .success);
            refreshTable();
          } else {
            flash.show(Text('Gagal hapus ${supplier.name}'), .error);
          }
        });
      },
    );
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
                children: [],
              ),
            ),
            SizedBox(
              height: bodyScreenHeight,
              child: CustomAsyncDataTable<ProductCategory>(
                onLoaded: (stateManager) => _source = stateManager,
                additionalHeaderActions: (menuController) => [
                  MenuItemButton(
                    child: const Text('Tambah Kategori Produk'),
                    onPressed: () {
                      menuController.close();
                      openForm(ProductCategory());
                    },
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
                fixedLeftColumns: 0,
                fetchData: fetchProductCategorys,
                showFilter: true,
                columns: setting.tableColumn('supplier'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
