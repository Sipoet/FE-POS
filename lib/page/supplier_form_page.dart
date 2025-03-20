import 'package:fe_pos/model/supplier.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SupplierFormPage extends StatefulWidget {
  final Supplier supplier;
  const SupplierFormPage({super.key, required this.supplier});

  @override
  State<SupplierFormPage> createState() => _SupplierFormPageState();
}

class _SupplierFormPageState extends State<SupplierFormPage> {
  Supplier get supplier => widget.supplier;
  late final Setting _setting;
  @override
  void initState() {
    _setting = context.read<Setting>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return VerticalBodyScroll(
      child: Column(
        children: [
          TextFormField(
            initialValue: supplier.code,
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('supplier', 'code')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            initialValue: supplier.name,
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('supplier', 'name')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            initialValue: supplier.address,
            readOnly: true,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
                label: Text(_setting.columnName('supplier', 'address')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            initialValue: supplier.contact,
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('supplier', 'contact')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            initialValue: supplier.bank,
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('supplier', 'bank')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            initialValue: supplier.account,
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('supplier', 'account')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            initialValue: supplier.accountRegisterName,
            readOnly: true,
            decoration: InputDecoration(
                label: Text(
                    _setting.columnName('supplier', 'account_register_name')),
                border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }
}
