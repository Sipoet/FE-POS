import 'package:flutter/material.dart';
import 'package:fe_pos/page/product_form_page.dart';
import 'package:provider/provider.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:fe_pos/model/product.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  @override
  void initState() {
    super.initState();
  }

  void openForm() {
    final tabManager = context.read<TabManager>();
    Product product = Product();
    tabManager.addTab(
        'Edit Produk ${product.name}', ProductFormPage(product: product));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Text('Produk'),
      ElevatedButton(onPressed: openForm, child: Text('Tambah')),
      Text('table')
    ]);
  }
}
