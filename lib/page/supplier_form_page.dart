import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/model/supplier.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/loading_popup.dart';
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

class _SupplierFormPageState extends State<SupplierFormPage>
    with DefaultResponse, LoadingPopup {
  Supplier get supplier => widget.supplier;
  late final Setting _setting;
  late final Server _server;
  final Map<String, TextEditingController> _controller = {};
  @override
  void initState() {
    _setting = context.read<Setting>();
    _server = context.read<Server>();
    supplier.toMap().forEach((key, value) {
      _controller[key] = TextEditingController(text: value.toString());
    });
    super.initState();
    if (supplier.rawData.isEmpty) {
      Future.delayed(Duration.zero, fetchSupplier);
    }
  }

  void fetchSupplier() {
    showLoadingPopup();
    _server.get('suppliers/${supplier.id}').then((response) {
      if (mounted && response.statusCode == 200) {
        Supplier.fromJson(response.data['data'],
            included: response.data['included'] ?? [], model: supplier);
        supplier.toMap().forEach((key, value) {
          _controller[key]!.text = value.toString();
        });
      }
    }).whenComplete(() => hideLoadingPopup());
  }

  @override
  Widget build(BuildContext context) {
    return VerticalBodyScroll(
      child: Column(
        children: [
          TextFormField(
            controller: _controller['code'],
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('supplier', 'code')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            controller: _controller['name'],
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('supplier', 'name')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            controller: _controller['address'],
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
            controller: _controller['contact'],
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('supplier', 'contact')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            controller: _controller['bank'],
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('supplier', 'bank')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            controller: _controller['account'],
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('supplier', 'account')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            controller: _controller['account_register_name'],
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
