import 'package:fe_pos/model/brand.dart';
import 'package:fe_pos/model/server.dart';
import 'package:fe_pos/tool/default_response.dart';
import 'package:fe_pos/tool/loading_popup.dart';
import 'package:fe_pos/tool/setting.dart';
import 'package:fe_pos/widget/vertical_body_scroll.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BrandFormPage extends StatefulWidget {
  final Brand brand;
  const BrandFormPage({super.key, required this.brand});

  @override
  State<BrandFormPage> createState() => _BrandFormPageState();
}

class _BrandFormPageState extends State<BrandFormPage>
    with DefaultResponse, LoadingPopup {
  Brand get brand => widget.brand;
  late final Setting _setting;
  late final Server _server;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  @override
  void initState() {
    _setting = context.read<Setting>();
    _server = context.read<Server>();
    _nameController = TextEditingController(text: brand.name);
    _descriptionController = TextEditingController(text: brand.description);
    super.initState();
    if (brand.rawData.isEmpty) {
      Future.delayed(Duration.zero, fetchBrand);
    }
  }

  void fetchBrand() {
    showLoadingPopup();
    _server.get('brands/${brand.id}').then((response) {
      if (mounted && response.statusCode == 200) {
        brand.setFromJson(
          response.data['data'],
          included: response.data['included'] ?? [],
        );
        _nameController.text = brand.name;
        _descriptionController.text = brand.description;
      }
    }).whenComplete(() => hideLoadingPopup());
  }

  @override
  Widget build(BuildContext context) {
    return VerticalBodyScroll(
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            readOnly: true,
            decoration: InputDecoration(
                label: Text(_setting.columnName('brand', 'name')),
                border: OutlineInputBorder()),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            controller: _descriptionController,
            readOnly: true,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
                label: Text(_setting.columnName('brand', 'description')),
                border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }
}
