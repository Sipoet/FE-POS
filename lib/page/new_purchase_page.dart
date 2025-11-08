import 'package:fe_pos/model/purchase_header.dart';
import 'package:fe_pos/tool/tab_manager.dart';
import 'package:flutter/material.dart';
import 'package:fe_pos/page/new_purchase_form_page.dart';
import 'package:provider/provider.dart';

class NewPurchasePage extends StatefulWidget {
  const NewPurchasePage({super.key});

  @override
  State<NewPurchasePage> createState() => _NewPurchasePageState();
}

class _NewPurchasePageState extends State<NewPurchasePage> {
  void openForm() {
    final tabManager = context.read<TabManager>();
    tabManager.addTab(
        'Pembelian Baru',
        NewPurchaseFormPage(
          purchaseHeader: PurchaseHeader(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [ElevatedButton(onPressed: openForm, child: Text('Tambah'))],
    );
  }
}
